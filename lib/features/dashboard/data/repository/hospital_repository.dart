import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/dashboard/data/models/hospital_model.dart';
import 'package:medisync_app/global/constants/app_constants.dart';

class HospitalRepository {
  final http.Client _client;

  HospitalRepository({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _parse(http.Response response) {
    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] == true) return body;
    throw ApiException(
      body['message'] ?? 'Something went wrong.',
      errors: body['errors'],
      statusCode: response.statusCode,
    );
  }

  // ─── Public ────────────────────────────────────────────────────────────────

  Future<HospitalListResponse> getHospitals({
    String query = '',
    String city = '',
    String department = '',
    bool hasIcu = false,
  }) async {
    final params = {
      if (query.isNotEmpty) 'q': query,
      if (city.isNotEmpty) 'city': city,
      if (department.isNotEmpty) 'department': department,
      if (hasIcu) 'has_icu': 'true',
    };
    final uri = Uri.parse(AppConstants.hospitalsEndpoint)
        .replace(queryParameters: params);
    final response = await _client.get(uri, headers: _headers);
    final body = _parse(response);
    return HospitalListResponse.fromJson(body['data']);
  }

  Future<HospitalModel> getHospitalDetail(int id) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.hospitalsEndpoint}$id/'),
      headers: _headers,
    );
    final body = _parse(response);
    return HospitalModel.fromJson(body['data']);
  }

  Future<HospitalListResponse> getNearbyHospitals({
    required double lat,
    required double lon,
    double radius = 20,
  }) async {
    final uri = Uri.parse('${AppConstants.hospitalsEndpoint}nearby/').replace(
      queryParameters: {
        'lat': '$lat',
        'lon': '$lon',
        'radius': '$radius',
      },
    );
    final response = await _client.get(uri, headers: _headers);
    final body = _parse(response);
    return HospitalListResponse.fromJson(body['data']);
  }

  // ─── Hospital User ─────────────────────────────────────────────────────────

  Future<HospitalModel> getMyHospital({required String token}) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.hospitalsEndpoint}my/'),
      headers: _authHeaders(token),
    );
    final body = _parse(response);
    return HospitalModel.fromJson(body['data']);
  }

  Future<HospitalModel> updateCapacity({
    required String token,
    required int availableBeds,
    required int icuAvailable,
    required int emergencyAvailable,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.hospitalsEndpoint}my/capacity/'),
      headers: _authHeaders(token),
      body: jsonEncode({
        'available_beds': availableBeds,
        'icu_available': icuAvailable,
        'emergency_available': emergencyAvailable,
      }),
    );
    final body = _parse(response);
    return HospitalModel.fromJson(body['data']);
  }
}
