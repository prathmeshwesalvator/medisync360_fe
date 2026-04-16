import 'dart:io';
import 'package:medisync_app/features/lab_report/data/service/lab_service.dart';
import '../model/lab_report_model.dart';

class LabReportRepository {
  // In-memory store — replace with sqflite/Hive for persistence
  final List<LabReport> _reports = [];
  int _nextId = 1;

  // ── Upload + analyze ─────────────────────────────────────────────────────────

  /// Runs OCR + GPT and returns a completed LabReport.
  Future<LabReport> uploadAndAnalyze({
    required File imageFile,
    required String reportType,
    String title = '',
    String notes = '',
  }) async {
    final result = await LabService.processReport(imageFile, reportType);

    final report = LabReport(
      id: _nextId++,
      title: title,
      reportType: reportType,
      image: imageFile.path,
      uploadedAt: DateTime.now().toIso8601String(),
      status: 'completed',
      aiAnalysis: result.aiResult['summary'] as String?,
      aiStructuredResult: LabAiResult.fromJson(result.aiResult),
      ocrRawText: result.ocrText,
      notes: notes,
    );

    _reports.add(report);
    return report;
  }

  // ── List / detail / delete ───────────────────────────────────────────────────

  List<LabReport> listReports() =>
      List.unmodifiable(_reports.reversed.toList());

  LabReport? getReport(int id) =>
      _reports.cast<LabReport?>().firstWhere((r) => r?.id == id, orElse: () => null);

  void deleteReport(int id) => _reports.removeWhere((r) => r.id == id);

  // ── Q&A ──────────────────────────────────────────────────────────────────────

  Future<ReportQA> askQuestion(int reportId, String question) async {
    final report = getReport(reportId);
    if (report == null) throw Exception('Report not found');

    final context = report.aiStructuredResult != null
        ? _aiResultToMap(report.aiStructuredResult!)
        : <String, dynamic>{};

    final answer = await LabService.askFollowUp(context, question);

    final qa = ReportQA(
      id: DateTime.now().millisecondsSinceEpoch,
      question: question,
      answer: answer,
      askedAt: DateTime.now().toIso8601String(),
    );

    _qaByReport.putIfAbsent(reportId, () => []).add(qa);
    return qa;
  }

  List<ReportQA> getQuestions(int reportId) =>
      List.unmodifiable(_qaByReport[reportId] ?? []);

  final Map<int, List<ReportQA>> _qaByReport = {};

  // ── Helper ───────────────────────────────────────────────────────────────────

  Map<String, dynamic> _aiResultToMap(LabAiResult r) => {
        'summary': r.summary,
        'report_type': r.reportType,
        'abnormal_flags': r.abnormalFlags,
        'critical_alerts': r.criticalAlerts,
        'doctor_consult_urgency': r.doctorConsultUrgency,
        'doctor_consult_reason': r.doctorConsultReason,
        'trend_advice': r.trendAdvice,
        'parameters': r.parameters
            .map((p) => {'name': p.name, 'value': p.value, 'status': p.status})
            .toList(),
      };
}