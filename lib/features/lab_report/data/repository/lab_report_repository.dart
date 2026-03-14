import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../global/constants/app_constants.dart';
import '../../../../global/storage/token_storage.dart';
import '../model/lab_report_model.dart';

class LabReportRepository {
  final Dio _dio;

  LabReportRepository()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConstants.labReportsUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

  // ── Auth header helper ───────────────────────────────────────────────────────

  Future<Options> _authOptions() async {
    final token = await TokenStorage().getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  // ── Upload ───────────────────────────────────────────────────────────────────

  /// Upload a lab report image. Returns { report_id, status, message }.
  Future<Map<String, dynamic>> uploadReport({
    required File imageFile,
    required String reportType,
    String title = '',
    String notes = '',
  }) async {
    try {
      final options = await _authOptions();
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
        'report_type': reportType,
        'title': title,
        'notes': notes,
      });
      final response = await _dio.post(
        '/upload/',
        data: formData,
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Status polling ───────────────────────────────────────────────────────────

  /// Poll processing status: 'pending' | 'processing' | 'completed' | 'failed'
  Future<String> getStatus(int reportId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get('/$reportId/status/', options: options);
      return response.data['status'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Full report detail ───────────────────────────────────────────────────────

  /// Fetch full report with AI analysis.
  Future<LabReport> getReport(int reportId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get('/$reportId/', options: options);
      return LabReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Summary card ─────────────────────────────────────────────────────────────

  /// Lightweight summary for dashboard cards.
  Future<Map<String, dynamic>> getSummary(int reportId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get('/$reportId/summary/', options: options);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── List all reports ─────────────────────────────────────────────────────────

  /// List all reports for the authenticated user.
  Future<List<LabReport>> listReports() async {
    try {
      final options = await _authOptions();
      final response = await _dio.get('/', options: options);
      return (response.data as List)
          .map((e) => LabReport.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteReport(int reportId) async {
    try {
      final options = await _authOptions();
      await _dio.delete('/$reportId/delete/', options: options);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Ask AI a question ────────────────────────────────────────────────────────

  /// Ask a follow-up question about a specific report.
  /// Returns { id, question, answer, asked_at }.
  Future<Map<String, dynamic>> askQuestion(int reportId, String question) async {
    try {
      final options = await _authOptions();
      final response = await _dio.post(
        '/$reportId/ask/',
        data: {'question': question},
        options: options,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Q&A history ──────────────────────────────────────────────────────────────

  /// Fetch all past questions & answers for a report.
  Future<List<ReportQA>> getQuestions(int reportId) async {
    try {
      final options = await _authOptions();
      final response = await _dio.get('/$reportId/questions/', options: options);
      return (response.data as List)
          .map((e) => ReportQA.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error handler ────────────────────────────────────────────────────────────

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      if (data is Map && data.containsKey('detail')) {
        return Exception(data['detail']);
      }
      if (data is Map && data.containsKey('error')) {
        return Exception(data['error']);
      }
      return Exception('Server error: ${e.response!.statusCode}');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Request timed out. Please try again.');
    }
    return Exception('Network error. Check your connection.');
  }
}