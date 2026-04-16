import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/global/constants/app_constants.dart';

class AppointmentRepository {
  final http.Client _client;
  AppointmentRepository({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _parse(http.Response r) {
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    if (b['success'] == true) return b;
    throw ApiException(b['message'] ?? 'Request failed',
        errors: b['errors'], statusCode: r.statusCode);
  }

  List<AppointmentModel> _list(dynamic data) {
    final raw = data is List ? data : (data['results'] as List? ?? data as List? ?? []);
    return raw.map((a) => AppointmentModel.fromJson(a)).toList();
  }

  // ── Patient ──────────────────────────────────────────────────────────────

  Future<AppointmentModel> bookAppointment({
    required String token,
    required int doctorId,
    required int slotId,
    String reason = '',
    String symptoms = '',
    String appointmentType = 'in_person',
    int? hospitalId,
  }) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.appointmentsEndpoint),
      headers: _auth(token),
      body: jsonEncode({
        'doctor': doctorId,
        'slot_id': slotId,
        'appointment_type': appointmentType,
        if (reason.isNotEmpty) 'reason': reason,
        if (symptoms.isNotEmpty) 'symptoms': symptoms,
        if (hospitalId != null) 'hospital': hospitalId,
      }),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<List<AppointmentModel>> getMyAppointments(String token,
      {String? status, String? type}) async {
    final uri = Uri.parse(AppConstants.myAppointmentsEndpoint).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
      },
    );
    final r = _parse(await _client.get(uri, headers: _auth(token)));
    return _list(r['data']);
  }

  Future<AppointmentStats> getMyStats(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.myAppointmentStatsEndpoint),
      headers: _auth(token),
    ));
    return AppointmentStats.fromJson(r['data']);
  }

  Future<AppointmentModel> getDetail(int id, String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.appointmentDetail(id)),
      headers: _auth(token),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<AppointmentModel> cancel(int id, String token, {String reason = ''}) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.cancelAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({'reason': reason}),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<AppointmentModel> reschedule(int id, String token, int newSlotId) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.rescheduleAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({'slot_id': newSlotId}),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<AppointmentModel> markPaid(int id, String token) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.payAppointment(id)),
      headers: _auth(token),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  // ── Doctor ───────────────────────────────────────────────────────────────

  Future<List<AppointmentModel>> getDoctorAppointments(String token,
      {String? status, String? date}) async {
    final uri = Uri.parse(AppConstants.doctorAppointmentsEndpoint).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    final r = _parse(await _client.get(uri, headers: _auth(token)));
    return _list(r['data']);
  }

  Future<Map<String, dynamic>> getDoctorStats(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.doctorAppointmentStatsEndpoint),
      headers: _auth(token),
    ));
    return r['data'] as Map<String, dynamic>;
  }

  Future<AppointmentModel> confirm(int id, String token, {String meetingLink = ''}) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.confirmAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({if (meetingLink.isNotEmpty) 'meeting_link': meetingLink}),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<AppointmentModel> complete(int id, String token, {
    String notes = '',
    String diagnosis = '',
    String prescription = '',
  }) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.completeAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({
        if (notes.isNotEmpty) 'notes': notes,
        if (diagnosis.isNotEmpty) 'diagnosis': diagnosis,
        if (prescription.isNotEmpty) 'prescription': prescription,
      }),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<AppointmentModel> markNoShow(int id, String token) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.noShowAppointment(id)),
      headers: _auth(token),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  Future<AppointmentModel> updateNotes(int id, String token, {
    String notes = '',
    String diagnosis = '',
    String prescription = '',
  }) async {
    final r = _parse(await _client.patch(
      Uri.parse(AppConstants.appointmentNotes(id)),
      headers: _auth(token),
      body: jsonEncode({
        'notes': notes,
        'diagnosis': diagnosis,
        'prescription': prescription,
      }),
    ));
    return AppointmentModel.fromJson(r['data']);
  }
}