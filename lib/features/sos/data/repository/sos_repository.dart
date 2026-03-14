import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/sos/data/model/sos_model.dart';
import 'package:medisync_app/global/constants/app_constants.dart';

class SosRepository {
  final http.Client _client;
  SosRepository({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _parse(http.Response r) {
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    if (b['success'] == true) return b;
    throw ApiException(b['message'] ?? 'Error',
        errors: b['errors'], statusCode: r.statusCode);
  }

  // ── Patient ────────────────────────────────────────────────────────────────

  Future<SosAlertModel> createSos({
    required String token,
    required double latitude,
    required double longitude,
    String address = '',
    String severity = 'high',
    String description = '',
    String bloodGroup = '',
    String allergies = '',
    String medications = '',
    String emergencyContactName = '',
    String emergencyContactPhone = '',
  }) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosEndpoint),
      headers: _auth(token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'severity': severity,
        'description': description,
        'blood_group': bloodGroup,
        'allergies': allergies,
        'medications': medications,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
      }),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<SosAlertModel> getSosDetail(int id, String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.sosDetail(id)),
      headers: _auth(token),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<SosAlertModel> cancelSos(int id, String token) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosCancelEndpoint(id)),
      headers: _auth(token),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<List<SosAlertModel>> getMySosHistory(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.mySOSEndpoint),
      headers: _auth(token),
    ));
    return (r['data'] as List).map((j) => SosAlertModel.fromJson(j)).toList();
  }

  // ── Hospital ───────────────────────────────────────────────────────────────

  Future<List<SosAlertModel>> getActiveSosForHospital(String token) async {
    final r = _parse(await _client.get(
      Uri.parse(AppConstants.sosHospitalActiveEndpoint),
      headers: _auth(token),
    ));
    final data = r['data'];
    final list =
        data is Map ? (data['results'] as List? ?? []) : (data as List);
    return list.map((j) => SosAlertModel.fromJson(j)).toList();
  }

  Future<SosAlertModel> respondToSos({
    required String token,
    required int sosId,
    required int etaMinutes,
    String ambulanceNumber = '',
  }) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosRespondEndpoint(sosId)),
      headers: _auth(token),
      body: jsonEncode({
        'eta_minutes': etaMinutes,
        'ambulance_number': ambulanceNumber,
      }),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<SosAlertModel> markEnroute(int sosId, String token) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosEnrouteEndpoint(sosId)),
      headers: _auth(token),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<SosAlertModel> updateAmbulanceLocation({
    required String token,
    required int sosId,
    required double lat,
    required double lon,
  }) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosLocationEndpoint(sosId)),
      headers: _auth(token),
      body: jsonEncode({'ambulance_latitude': lat, 'ambulance_longitude': lon}),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<SosAlertModel> markArrived(int sosId, String token) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosArrivedEndpoint(sosId)),
      headers: _auth(token),
    ));
    return SosAlertModel.fromJson(r['data']);
  }

  Future<SosAlertModel> resolveSos(int sosId, String token) async {
    final r = _parse(await _client.post(
      Uri.parse(AppConstants.sosResolveEndpoint(sosId)),
      headers: _auth(token),
    ));
    return SosAlertModel.fromJson(r['data']);
  }
}
