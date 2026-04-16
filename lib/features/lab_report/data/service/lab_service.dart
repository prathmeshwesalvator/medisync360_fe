import 'dart:convert';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LabService {
  // ── OCR ─────────────────────────────────────────────────────────────────────

  /// Runs ML Kit OCR on the image and returns extracted text.
  static Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText result = await recognizer.processImage(inputImage);
      return result.text.trim();
    } finally {
      recognizer.close();
    }
  }

  // ── OpenAI ───────────────────────────────────────────────────────────────────

  static const String _model = 'gpt-4o';
  static const String _endpoint = 'https://api.openai.com/v1/chat/completions';

  static String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static const String _systemPrompt = '''
You are Dr. AI — an expert medical report analyst with clinical training across
hematology, biochemistry, endocrinology, nephrology, hepatology, and general medicine.
Your role is to analyze patient lab reports and provide clear, actionable,
medically accurate interpretations that a layperson can understand.

You ALWAYS respond ONLY in valid JSON format. No markdown, no prose outside JSON.

Your JSON response must follow this exact structure:
{
  "summary": "2-3 sentence plain-language summary of the overall health picture",
  "report_type": "detected report type (e.g. Complete Blood Count, Lipid Panel, etc.)",
  "parameters": [
    {
      "name": "parameter name",
      "value": "numeric value",
      "unit": "unit",
      "status": "normal | high | low | critical_high | critical_low",
      "reference_range": "reference range string",
      "interpretation": "1-2 sentence clinical meaning in plain English",
      "severity": "none | mild | moderate | severe"
    }
  ],
  "abnormal_flags": ["list of parameters that are outside normal range"],
  "critical_alerts": ["list of any critically abnormal values requiring urgent attention"],
  "health_risks": [
    {
      "condition": "condition name",
      "risk_level": "low | moderate | high",
      "explanation": "why this is a concern based on these results"
    }
  ],
  "dietary_recommendations": [
    {
      "recommendation": "specific dietary advice",
      "reason": "why this helps based on results"
    }
  ],
  "lifestyle_recommendations": [
    {
      "recommendation": "specific lifestyle or exercise advice",
      "reason": "why this helps based on results"
    }
  ],
  "follow_up_tests": ["list of tests that should be done as follow-up"],
  "doctor_consult_urgency": "immediate | within_week | within_month | routine",
  "doctor_consult_reason": "reason why they should see a doctor",
  "positive_findings": ["list of parameters that are normal or good"],
  "trend_advice": "advice on what to monitor over time",
  "disclaimer": "Always present — remind user this is AI analysis, not a diagnosis"
}''';

  static String _buildUserPrompt(String ocrText, String reportType) => '''
Analyze the following lab report.

REPORT TYPE (if known): ${reportType.isEmpty ? 'Auto-detect from content' : reportType}

--- RAW OCR TEXT ---
$ocrText

Instructions:
1. Extract ALL lab parameters from the raw text above.
2. Determine reference ranges based on standard clinical guidelines.
3. Flag any value that is outside the reference range.
4. Mark critical values (e.g. Hemoglobin < 7, Glucose > 400, Potassium > 6.5) as critical alerts.
5. Provide actionable dietary and lifestyle changes tailored to these results.
6. Be empathetic but factual. Avoid causing unnecessary panic.
7. RESPOND ONLY IN THE JSON FORMAT SPECIFIED IN YOUR SYSTEM PROMPT.
''';

  /// Sends OCR text to OpenAI and returns structured LabAiResult JSON.
  static Future<Map<String, dynamic>> analyzeWithGpt(
    String ocrText,
    String reportType,
  ) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.2,
        'max_tokens': 2500,
        'response_format': {'type': 'json_object'},
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': _buildUserPrompt(ocrText, reportType)},
        ],
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'OpenAI request failed');
    }

    final decoded = jsonDecode(response.body);
    final content = decoded['choices'][0]['message']['content'] as String;
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Ask a follow-up question about an already-analyzed report.
  static Future<String> askFollowUp(
    Map<String, dynamic> reportContext,
    String question,
  ) async {
    const system = '''
You are Dr. AI, a compassionate and knowledgeable medical assistant.
A patient is asking a follow-up question about their lab report.
Answer clearly, empathetically, and in plain English.
Do NOT provide a diagnosis. Explain in a way a non-medical person understands.
Keep response under 300 words. End with a gentle reminder to consult their doctor.
''';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _model,
        'temperature': 0.4,
        'max_tokens': 500,
        'messages': [
          {'role': 'system', 'content': system},
          {
            'role': 'user',
            'content':
                'Lab Report Context:\n${jsonEncode(reportContext)}\n\nPatient Question: $question',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'OpenAI request failed');
    }

    final decoded = jsonDecode(response.body);
    return decoded['choices'][0]['message']['content'] as String;
  }

  // ── Full pipeline ────────────────────────────────────────────────────────────

  /// OCR → GPT analysis. Returns { ocrText, aiResult } or throws.
  static Future<({String ocrText, Map<String, dynamic> aiResult})> processReport(
    File imageFile,
    String reportType,
  ) async {
    final ocrText = await extractText(imageFile);

    if (ocrText.length < 20) {
      throw Exception(
        'Could not extract readable text from image. Please upload a clearer image.',
      );
    }

    final aiResult = await analyzeWithGpt(ocrText, reportType);
    return (ocrText: ocrText, aiResult: aiResult);
  }
}