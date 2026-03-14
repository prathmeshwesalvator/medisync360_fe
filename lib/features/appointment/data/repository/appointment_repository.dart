import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/global/constants/app_constants.dart';

class AppointmentRepository {
  final http.Client _client;
  AppointmentRepository({http.Client? client})
      : _client = client ?? http.Client();

  Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _parse(http.Response r) {
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    if (b['success'] == true) return b;
    throw ApiException(
      b['message'] ?? 'Request failed',
      errors: b['errors'],
      statusCode: r.statusCode,
    );
  }

  // ── Patient: book ──────────────────────────────────────────────────────────
  Future<AppointmentModel> bookAppointment({
    required String token,
    required int doctorId,
    required int slotId,   // FIX: was slotTime (String) — backend expects slot_id (int)
    String reason = '',
    int? hospitalId,
  }) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.appointmentsEndpoint),
      headers: _auth(token),
      body: jsonEncode({
        'doctor': doctorId,
        'slot_id': slotId,           // FIX: send slot_id, not slot_time
        if (reason.isNotEmpty) 'reason': reason,
        if (hospitalId != null) 'hospital': hospitalId,
      }),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  // ── Patient: list my appointments ──────────────────────────────────────────
  Future<List<AppointmentModel>> getMyAppointments(String token,
      {String? status}) async {
    final uri = Uri.parse(AppConstants.myAppointmentsEndpoint).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final r = _parse(await _client.get(uri, headers: _auth(token)));
    final data = r['data'];
    final list = data is List
        ? data
        : (data['results'] as List? ?? data as List? ?? []);
    return list.map((a) => AppointmentModel.fromJson(a)).toList();
  }

  // ── Doctor: list appointments ──────────────────────────────────────────────
  Future<List<AppointmentModel>> getDoctorAppointments(String token,
      {String? status, String? date}) async {
    final uri =
        Uri.parse(AppConstants.doctorAppointmentsEndpoint).replace(
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (date != null && date.isNotEmpty) 'date': date,
      },
    );
    final r = _parse(await _client.get(uri, headers: _auth(token)));
    final data = r['data'];
    final list = data is List
        ? data
        : (data['results'] as List? ?? data as List? ?? []);
    return list.map((a) => AppointmentModel.fromJson(a)).toList();
  }

  // ── Detail ─────────────────────────────────────────────────────────────────
  Future<AppointmentModel> getDetail(int id, String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.appointmentDetail(id)),
      headers: _auth(token),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────
  Future<AppointmentModel> cancel(int id, String token,
      {String reason = ''}) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.cancelAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({'reason': reason}),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  // ── Reschedule ─────────────────────────────────────────────────────────────
  Future<AppointmentModel> reschedule(
    int id,
    String token,
    int newSlotId, // FIX: was (newDate, newSlotTime) — backend expects slot_id
  ) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.rescheduleAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({'slot_id': newSlotId}),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  // ── Complete (doctor action) ───────────────────────────────────────────────
  Future<AppointmentModel> complete(int id, String token,
      {String notes = ''}) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.completeAppointment(id)),
      headers: _auth(token),
      body: jsonEncode({'notes': notes}),
    ));
    return AppointmentModel.fromJson(r['data']);
  }

  // ── Confirm (doctor action) ────────────────────────────────────────────────
  Future<AppointmentModel> confirm(int id, String token) async {
    final r = _parse(await _client.post(
      Uri.parse('${AppConstants.appointmentDetail(id)}confirm/'),
      headers: _auth(token),
    ));
    return AppointmentModel.fromJson(r['data']);
  }
}