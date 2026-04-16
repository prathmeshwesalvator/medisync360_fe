// xray_analyzer_datasource.dart
// ─────────────────────────────────────────────────────────────────────────────
// DataSource: handles all OpenAI Vision API calls for X-Ray Analyzer
// Reads OPENAI_API_KEY from .env via flutter_dotenv
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// ─── Models ──────────────────────────────────────────────────────────────────

class XRayGuardResult {
  final bool isChestXRay;
  final String reason;

  const XRayGuardResult({required this.isChestXRay, required this.reason});
}

class XRayAnalysisResult {
  final bool isChestXRay;          // guard result
  final String guardReason;
  final String summary;            // short plain-english summary
  final String impression;         // radiologist-style impression
  final List<XRayFinding> findings;
  final List<PossibleCondition> possibleConditions;
  final String recommendation;
  final String disclaimer;

  const XRayAnalysisResult({
    required this.isChestXRay,
    required this.guardReason,
    required this.summary,
    required this.impression,
    required this.findings,
    required this.possibleConditions,
    required this.recommendation,
    required this.disclaimer,
  });
}

class XRayFinding {
  final String region;
  final String observation;
  final Severity severity;  // normal | mild | moderate | severe

  const XRayFinding({
    required this.region,
    required this.observation,
    required this.severity,
  });

  factory XRayFinding.fromJson(Map<String, dynamic> j) => XRayFinding(
        region: j['region'] as String? ?? '',
        observation: j['observation'] as String? ?? '',
        severity: Severity.fromString(j['severity'] as String? ?? 'normal'),
      );
}

class PossibleCondition {
  final String name;
  final String description;
  final ConfidenceLevel confidence;   // low | moderate | high
  final String evidenceBasis;

  const PossibleCondition({
    required this.name,
    required this.description,
    required this.confidence,
    required this.evidenceBasis,
  });

  factory PossibleCondition.fromJson(Map<String, dynamic> j) =>
      PossibleCondition(
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
        confidence:
            ConfidenceLevel.fromString(j['confidence'] as String? ?? 'low'),
        evidenceBasis: j['evidence_basis'] as String? ?? '',
      );
}

enum Severity {
  normal,
  mild,
  moderate,
  severe;

  static Severity fromString(String s) => switch (s.toLowerCase()) {
        'mild' => mild,
        'moderate' => moderate,
        'severe' => severe,
        _ => normal,
      };
}

enum ConfidenceLevel {
  low,
  moderate,
  high;

  static ConfidenceLevel fromString(String s) => switch (s.toLowerCase()) {
        'moderate' => moderate,
        'high' => high,
        _ => low,
      };
}

// ─── Exceptions ───────────────────────────────────────────────────────────────

class XRayApiException implements Exception {
  final String message;
  final int? statusCode;
  const XRayApiException(this.message, {this.statusCode});

  @override
  String toString() => 'XRayApiException($statusCode): $message';
}

class NotAChestXRayException implements Exception {
  final String reason;
  const NotAChestXRayException(this.reason);

  @override
  String toString() => 'NotAChestXRayException: $reason';
}

// ─── DataSource ───────────────────────────────────────────────────────────────

class XRayAnalyzerDataSource {
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-4o'; // vision-capable model

  String get _apiKey {
    final key = dotenv.env['OPENAI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw const XRayApiException('OPENAI_API_KEY not found in .env');
    }
    return key;
  }

  // ── Step 1: Guard — is this a chest X-ray? ────────────────────────────────

  static const String _guardPrompt = '''
You are a radiology AI safety guard. Your ONLY job is to determine if the provided image is a 
chest X-ray (PA, AP, or lateral chest radiograph).

Respond with a JSON object ONLY — no markdown, no explanation outside JSON:
{
  "is_chest_xray": true | false,
  "reason": "brief one-sentence reason"
}

Criteria for true:
- The image shows thoracic anatomy (ribs, lungs, heart, mediastinum, diaphragm)
- It is a radiographic (X-ray) image, NOT CT, MRI, ultrasound, photo, or illustration
- It is specifically of the CHEST region (not abdomen-only, skull, limb, spine-only, etc.)

If ANY of these criteria fail, respond with is_chest_xray: false.
''';

  Future<XRayGuardResult> checkIsChestXRay(File imageFile) async {
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final response = await _callOpenAI(
      systemPrompt: _guardPrompt,
      userContent: [
        {
          'type': 'image_url',
          'image_url': {'url': 'data:$mimeType;base64,$base64Image', 'detail': 'high'},
        },
        {
          'type': 'text',
          'text': 'Is this a chest X-ray? Respond only in the JSON format specified.',
        },
      ],
      maxTokens: 200,
    );

    try {
      final clean = _stripJsonFences(response);
      final json = jsonDecode(clean) as Map<String, dynamic>;
      return XRayGuardResult(
        isChestXRay: json['is_chest_xray'] as bool? ?? false,
        reason: json['reason'] as String? ?? '',
      );
    } catch (_) {
      // If parsing fails, assume not a chest X-ray for safety
      return const XRayGuardResult(
        isChestXRay: false,
        reason: 'Could not parse guard response — treating as non-chest X-ray.',
      );
    }
  }

  // ── Step 2: Full Analysis ─────────────────────────────────────────────────

  static const String _analysisSystemPrompt = '''
You are an expert radiologist AI assistant with deep knowledge of chest radiography, pulmonology, 
and internal medicine. You are assisting a medical professional reviewing a chest X-ray.

Your task is to analyze the provided chest X-ray image with the rigor of a board-certified 
radiologist and provide a structured JSON report. Be thorough, specific, and medically precise.

⚠️ IMPORTANT DISCLAIMER REMINDER: Always include a disclaimer that this is an AI-assisted 
analysis for educational purposes only and not a substitute for professional medical diagnosis.

Respond ONLY with a valid JSON object in this exact schema (no markdown fences, no text outside JSON):

{
  "summary": "A concise 2–3 sentence plain-English summary of the overall X-ray findings",
  "impression": "Formal radiologist-style impression paragraph as seen in a real radiology report",
  "findings": [
    {
      "region": "e.g. Right lower lobe / Cardiac silhouette / Costophrenic angles",
      "observation": "Detailed description of what is seen in this region",
      "severity": "normal | mild | moderate | severe"
    }
  ],
  "possible_conditions": [
    {
      "name": "Condition name",
      "description": "Brief clinical description of the condition and how it presents on X-ray",
      "confidence": "low | moderate | high",
      "evidence_basis": "Specific X-ray features that support this possibility"
    }
  ],
  "recommendation": "Clinical follow-up recommendation (e.g., CT scan, blood work, clinical correlation)",
  "disclaimer": "Standard medical disclaimer text"
}

Evaluation criteria for findings regions to ALWAYS cover:
1. Lung fields (bilateral — upper, middle, lower zones)
2. Cardiac silhouette (size, shape, borders)
3. Mediastinum (width, tracheal deviation)
4. Hila (size, position, density)
5. Pleural spaces (effusion, pneumothorax)
6. Diaphragm (position, contour, costophrenic angles)
7. Bones (visible ribs, clavicles, thoracic spine)
8. Soft tissues and any tubes/lines/devices if present

For possible_conditions: list 1–5 conditions. Include "No acute cardiopulmonary abnormality" 
as a condition with appropriate confidence if the X-ray appears normal.

Be honest about uncertainty. Use hedging language where appropriate 
(e.g. "cannot be excluded", "suspicious for", "consider").
''';

  Future<XRayAnalysisResult> analyzeXRay(File imageFile) async {
    // Step 1: Guard
    final guard = await checkIsChestXRay(imageFile);
    if (!guard.isChestXRay) {
      throw NotAChestXRayException(guard.reason);
    }

    // Step 2: Full analysis
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    final response = await _callOpenAI(
      systemPrompt: _analysisSystemPrompt,
      userContent: [
        {
          'type': 'image_url',
          'image_url': {'url': 'data:$mimeType;base64,$base64Image', 'detail': 'high'},
        },
        {
          'type': 'text',
          'text':
              'Please provide a comprehensive radiological analysis of this chest X-ray. '
              'Return only the JSON report as specified in your instructions.',
        },
      ],
      maxTokens: 2500,
    );

    try {
      final clean = _stripJsonFences(response);
      final json = jsonDecode(clean) as Map<String, dynamic>;

      final findingsRaw = json['findings'] as List<dynamic>? ?? [];
      final conditionsRaw = json['possible_conditions'] as List<dynamic>? ?? [];

      return XRayAnalysisResult(
        isChestXRay: true,
        guardReason: guard.reason,
        summary: json['summary'] as String? ?? '',
        impression: json['impression'] as String? ?? '',
        findings: findingsRaw
            .map((e) => XRayFinding.fromJson(e as Map<String, dynamic>))
            .toList(),
        possibleConditions: conditionsRaw
            .map((e) => PossibleCondition.fromJson(e as Map<String, dynamic>))
            .toList(),
        recommendation: json['recommendation'] as String? ?? '',
        disclaimer: json['disclaimer'] as String? ??
            'This analysis is AI-generated for educational purposes only. '
                'It is NOT a substitute for professional medical advice, diagnosis, or treatment.',
      );
    } catch (e) {
      throw XRayApiException('Failed to parse analysis response: $e');
    }
  }

  // ── Step 3: Chat about the X-ray ─────────────────────────────────────────

  static const String _chatSystemPrompt = '''
You are a knowledgeable radiology AI assistant. The user has uploaded a chest X-ray and has 
already received an initial analysis report. The user now wants to ask follow-up questions 
about this specific X-ray.

Guidelines:
- Answer in clear, friendly, but medically accurate language
- You can see the X-ray image in this conversation
- Reference specific findings visible in the X-ray when answering
- If asked about treatment, always recommend consulting a qualified physician
- Keep answers focused and clinically relevant
- Use plain English where possible; define medical terms if used
- If a question is outside your ability to answer from the X-ray alone, say so clearly
''';

  Future<String> chatAboutXRay({
    required File imageFile,
    required List<Map<String, String>> chatHistory, // [{role, content}]
    required String userMessage,
  }) async {
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    // Build messages: system + image context + history + new message
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _chatSystemPrompt},
      // First user turn: attach the image once
      {
        'role': 'user',
        'content': [
          {
            'type': 'image_url',
            'image_url': {
              'url': 'data:$mimeType;base64,$base64Image',
              'detail': 'high',
            },
          },
          {
            'type': 'text',
            'text': 'This is the chest X-ray we are discussing.',
          },
        ],
      },
      {'role': 'assistant', 'content': 'Understood. I can see the chest X-ray. What would you like to know?'},
      // Inject prior conversation
      ...chatHistory.map((m) => {'role': m['role']!, 'content': m['content']!}),
      // New user question
      {'role': 'user', 'content': userMessage},
    ];

    return await _callOpenAIMessages(messages: messages, maxTokens: 800);
  }

  // ── Internal HTTP helpers ─────────────────────────────────────────────────

  Future<String> _callOpenAI({
    required String systemPrompt,
    required List<Map<String, dynamic>> userContent,
    int maxTokens = 1000,
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userContent},
    ];
    return _callOpenAIMessages(messages: messages, maxTokens: maxTokens);
  }

  Future<String> _callOpenAIMessages({
    required List<Map<String, dynamic>> messages,
    int maxTokens = 1000,
  }) async {
    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': maxTokens,
        'messages': messages,
        'temperature': 0.2, // low temperature for clinical accuracy
      }),
    );

    if (res.statusCode != 200) {
      final body = jsonDecode(res.body);
      final errMsg = body['error']?['message'] as String? ?? 'Unknown error';
      throw XRayApiException(errMsg, statusCode: res.statusCode);
    }

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>;
    if (choices.isEmpty) throw const XRayApiException('Empty response from API');

    return (choices[0]['message']['content'] as String).trim();
  }

  String _stripJsonFences(String text) {
    return text
        .replaceAll(RegExp(r'^```json\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^```\s*', multiLine: true), '')
        .trim();
  }
}