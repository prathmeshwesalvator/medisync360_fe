import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/global/constants/app_constants.dart';
import '../models/ehr_models.dart';


class EHRRepository {
  final http.Client _client;
  EHRRepository({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _parse(http.Response r) {
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    if (r.statusCode >= 200 && r.statusCode < 300) return b;
    throw ApiException(
      b['message'] ?? 'Request failed',
      errors: b['errors'],
      statusCode: r.statusCode,
    );
  }

  // ── Medical history ──────────────────────────────────────────────────────────
  Future<MedicalRecordModel> getMyRecord(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.myHistoryEndpoint),
      headers: _auth(token),
    ));
    return MedicalRecordModel.fromJson(r['data'] ?? r);
  }

  Future<MedicalRecordModel> updateMyRecord(
      String token, Map<String, dynamic> data) async {
    final r = _parse(await _client.put(
      Uri.parse(AppConstants.myHistoryEndpoint),
      headers: _auth(token),
      body: jsonEncode(data),
    ));
    return MedicalRecordModel.fromJson(r['data'] ?? r);
  }

  // ── Prescriptions ────────────────────────────────────────────────────────────
  Future<List<PrescriptionModel>> getPrescriptions(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.myPrescriptionsEndpoint),
      headers: _auth(token),
    ));
    final list = r['data'] as List? ?? [];
    return list.map((p) => PrescriptionModel.fromJson(p)).toList();
  }

  // ── Doctor notes (visit notes) ───────────────────────────────────────────────
  Future<List<VisitNoteModel>> getVisitNotes(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.myNotesEndpoint),
      headers: _auth(token),
    ));
    final list = r['data'] as List? ?? [];
    return list.map((v) => VisitNoteModel.fromJson(v)).toList();
  }

  // ── Imaging ──────────────────────────────────────────────────────────────────
  Future<List<ImagingRecordModel>> getImagingRecords(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.myImagingEndpoint),
      headers: _auth(token),
    ));
    final list = r['data'] as List? ?? [];
    return list.map((i) => ImagingRecordModel.fromJson(i)).toList();
  }
}