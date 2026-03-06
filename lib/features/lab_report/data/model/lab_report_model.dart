import 'package:flutter/material.dart';

class LabTestResult {
  final int id;
  final String testName;
  final String value;
  final String unit;
  final String normalRange;
  final bool isAbnormal;

  const LabTestResult({
    required this.id,
    required this.testName,
    required this.value,
    required this.unit,
    required this.normalRange,
    required this.isAbnormal,
  });

  factory LabTestResult.fromJson(Map<String, dynamic> j) => LabTestResult(
    id:          j['id'],
    testName:    j['test_name'] ?? '',
    value:       j['value'] ?? '',
    unit:        j['unit'] ?? '',
    normalRange: j['normal_range'] ?? '',
    isAbnormal:  j['is_abnormal'] ?? false,
  );
}

class LabReport {
  final int id;
  final String patientName;
  final String uploadedByName;
  final String title;
  final String reportType;
  final String fileUrl;
  final DateTime testDate;
  final String status;
  final String notes;
  final List<LabTestResult> results;
  final DateTime createdAt;

  const LabReport({
    required this.id,
    required this.patientName,
    required this.uploadedByName,
    required this.title,
    required this.reportType,
    required this.fileUrl,
    required this.testDate,
    required this.status,
    required this.notes,
    required this.results,
    required this.createdAt,
  });

  factory LabReport.fromJson(Map<String, dynamic> j) => LabReport(
    id:             j['id'],
    patientName:    j['patient_name'] ?? '',
    uploadedByName: j['uploaded_by_name'] ?? '',
    title:          j['title'] ?? '',
    reportType:     j['report_type'] ?? '',
    fileUrl:        j['file_url'] ?? '',
    testDate:       DateTime.tryParse(j['test_date'] ?? '') ?? DateTime.now(),
    status:         j['status'] ?? 'pending',
    notes:          j['notes'] ?? '',
    results:        (j['results'] as List? ?? []).map((e) => LabTestResult.fromJson(e)).toList(),
    createdAt:      DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );

  bool get hasAbnormal => results.any((r) => r.isAbnormal);

  String get statusLabel {
    switch (status) {
      case 'processed': return 'Processed';
      case 'verified':  return 'Verified';
      default:          return 'Pending';
    }
  }

  Color get statusColor {
    switch (status) {
      case 'processed': return const Color(0xFF2563EB);
      case 'verified':  return const Color(0xFF16A34A);
      default:          return const Color(0xFFD97706);
    }
  }
}