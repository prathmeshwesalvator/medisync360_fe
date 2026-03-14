class LabReport {
  final int id;
  final String title;
  final String reportType;
  final String image;
  final String uploadedAt;
  final String status;
  final String? aiAnalysis;
  final LabAiResult? aiStructuredResult;

  LabReport({
    required this.id,
    required this.title,
    required this.reportType,
    required this.image,
    required this.uploadedAt,
    required this.status,
    this.aiAnalysis,
    this.aiStructuredResult,
  });

  factory LabReport.fromJson(Map<String, dynamic> json) => LabReport(
        id: json['id'],
        title: json['title'] ?? '',
        reportType: json['report_type'] ?? '',
        image: json['image'] ?? '',
        uploadedAt: json['uploaded_at'] ?? '',
        status: json['status'] ?? 'pending',
        aiAnalysis: json['ai_analysis'],
        aiStructuredResult: json['ai_structured_result'] != null
            ? LabAiResult.fromJson(json['ai_structured_result'])
            : null,
      );
}

class LabAiResult {
  final String summary;
  final String reportType;
  final List<LabParameter> parameters;
  final List<String> abnormalFlags;
  final List<String> criticalAlerts;
  final List<HealthRisk> healthRisks;
  final List<Recommendation> dietaryRecommendations;
  final List<Recommendation> lifestyleRecommendations;
  final List<String> followUpTests;
  final String doctorConsultUrgency;
  final String doctorConsultReason;
  final List<String> positiveFindings;
  final String trendAdvice;
  final String disclaimer;

  LabAiResult({
    required this.summary,
    required this.reportType,
    required this.parameters,
    required this.abnormalFlags,
    required this.criticalAlerts,
    required this.healthRisks,
    required this.dietaryRecommendations,
    required this.lifestyleRecommendations,
    required this.followUpTests,
    required this.doctorConsultUrgency,
    required this.doctorConsultReason,
    required this.positiveFindings,
    required this.trendAdvice,
    required this.disclaimer,
  });

  factory LabAiResult.fromJson(Map<String, dynamic> json) => LabAiResult(
        summary: json['summary'] ?? '',
        reportType: json['report_type'] ?? '',
        parameters: (json['parameters'] as List? ?? [])
            .map((e) => LabParameter.fromJson(e))
            .toList(),
        abnormalFlags: List<String>.from(json['abnormal_flags'] ?? []),
        criticalAlerts: List<String>.from(json['critical_alerts'] ?? []),
        healthRisks: (json['health_risks'] as List? ?? [])
            .map((e) => HealthRisk.fromJson(e))
            .toList(),
        dietaryRecommendations: (json['dietary_recommendations'] as List? ?? [])
            .map((e) => Recommendation.fromJson(e))
            .toList(),
        lifestyleRecommendations: (json['lifestyle_recommendations'] as List? ?? [])
            .map((e) => Recommendation.fromJson(e))
            .toList(),
        followUpTests: List<String>.from(json['follow_up_tests'] ?? []),
        doctorConsultUrgency: json['doctor_consult_urgency'] ?? 'routine',
        doctorConsultReason: json['doctor_consult_reason'] ?? '',
        positiveFindings: List<String>.from(json['positive_findings'] ?? []),
        trendAdvice: json['trend_advice'] ?? '',
        disclaimer: json['disclaimer'] ?? '',
      );
}

class LabParameter {
  final String name;
  final String value;
  final String unit;
  final String status; // normal | high | low | critical_high | critical_low
  final String referenceRange;
  final String interpretation;
  final String severity;

  LabParameter({
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
    required this.referenceRange,
    required this.interpretation,
    required this.severity,
  });

  factory LabParameter.fromJson(Map<String, dynamic> json) => LabParameter(
        name: json['name'] ?? '',
        value: json['value'] ?? '',
        unit: json['unit'] ?? '',
        status: json['status'] ?? 'normal',
        referenceRange: json['reference_range'] ?? '',
        interpretation: json['interpretation'] ?? '',
        severity: json['severity'] ?? 'none',
      );
}

class HealthRisk {
  final String condition;
  final String riskLevel;
  final String explanation;

  HealthRisk({
    required this.condition,
    required this.riskLevel,
    required this.explanation,
  });

  factory HealthRisk.fromJson(Map<String, dynamic> json) => HealthRisk(
        condition: json['condition'] ?? '',
        riskLevel: json['risk_level'] ?? 'low',
        explanation: json['explanation'] ?? '',
      );
}

class Recommendation {
  final String recommendation;
  final String reason;

  Recommendation({required this.recommendation, required this.reason});

  factory Recommendation.fromJson(Map<String, dynamic> json) => Recommendation(
        recommendation: json['recommendation'] ?? '',
        reason: json['reason'] ?? '',
      );
}

class ReportQA {
  final int id;
  final String question;
  final String answer;
  final String askedAt;

  ReportQA({
    required this.id,
    required this.question,
    required this.answer,
    required this.askedAt,
  });

  factory ReportQA.fromJson(Map<String, dynamic> json) => ReportQA(
        id: json['id'] ?? 0,
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        askedAt: json['asked_at'] ?? '',
      );
}