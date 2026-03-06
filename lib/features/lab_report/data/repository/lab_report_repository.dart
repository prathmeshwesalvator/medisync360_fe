import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/lab_report/data/model/lab_report_model.dart';
import 'package:medisync_app/global/constants/app_constants.dart';
import 'package:medisync_app/global/storage/token_storage.dart';


class LabReportRepository {
  final http.Client _client;
  final TokenStorage _storage;

  LabReportRepository({http.Client? client, required TokenStorage storage})
      : _client = client ?? http.Client(),
        _storage = storage;

  Future<Map<String, String>> _headers() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _parse(http.Response r) {
    final body = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    throw Exception(body['message'] ?? 'Request failed');
  }

  Future<List<LabReport>> getMyReports() async {
    final res = _parse(await _client.get(
      Uri.parse(AppConstants.labReportsEndpoint),
      headers: await _headers(),
    ));
    return (res['data'] as List? ?? [])
        .map((e) => LabReport.fromJson(e))
        .toList();
  }

  Future<LabReport> getReport(int id) async {
    final res = _parse(await _client.get(
      Uri.parse(AppConstants.labReportDetail(id)),
      headers: await _headers(),
    ));
    return LabReport.fromJson(res['data']);
  }

  Future<LabReport> uploadReport({
    required String title,
    required String reportType,
    required String fileUrl,
    required String testDate,
    String notes = '',
  }) async {
    final res = _parse(await _client.post(
      Uri.parse(AppConstants.labReportsEndpoint),
      headers: await _headers(),
      body: jsonEncode({
        'title': title,
        'report_type': reportType,
        'file_url': fileUrl,
        'test_date': testDate,
        'notes': notes,
      }),
    ));
    return LabReport.fromJson(res['data']);
  }
}