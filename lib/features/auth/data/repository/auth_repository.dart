import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/global/constants/app_constants.dart';

// ─── Exception ────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  const ApiException(this.message, {this.errors, this.statusCode});

  @override
  String toString() => message;
}

// ─── Repository ───────────────────────────────────────────────────────────────

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // ─── Helper ────────────────────────────────────────────────────────────────

  Map<String, dynamic> _parseResponse(http.Response response) {
    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] == true) return body;
    throw ApiException(
      body['message'] ?? 'Something went wrong.',
      errors: body['errors'],
      statusCode: response.statusCode,
    );
  }

  // ─── Login ─────────────────────────────────────────────────────────────────

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.loginEndpoint),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _parseResponse(response);
    return AuthResult(
      tokens: AuthTokens.fromJson(body['data']['tokens']),
      user: UserModel.fromJson(body['data']['user']),
    );
  }

  // ─── Register User (Patient) ───────────────────────────────────────────────

  Future<AuthResult> registerUser({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.registerUserEndpoint),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );
    final body = _parseResponse(response);
    return AuthResult(
      tokens: AuthTokens.fromJson(body['data']['tokens']),
      user: UserModel.fromJson(body['data']['user']),
    );
  }

  // ─── Register Doctor ───────────────────────────────────────────────────────

  Future<UserModel> registerDoctor({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    required DoctorProfile doctorProfile,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.registerDoctorEndpoint),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
        'doctor_profile': doctorProfile.toJson(),
      }),
    );
    final body = _parseResponse(response);
    return UserModel.fromJson(body['data']['user']);
  }

  // ─── Register Hospital ─────────────────────────────────────────────────────

  Future<UserModel> registerHospital({
    required String email,
    required String fullName,
    required String phone,
    required String password,
    required String confirmPassword,
    required HospitalProfile hospitalProfile,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.registerHospitalEndpoint),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
        'hospital_profile': hospitalProfile.toJson(),
      }),
    );
    final body = _parseResponse(response);
    return UserModel.fromJson(body['data']['user']);
  }

  // ─── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _client.post(
      Uri.parse(AppConstants.logoutEndpoint),
      headers: _authHeaders(accessToken),
      body: jsonEncode({'refresh': refreshToken}),
    );
  }

  // ─── Change Password ───────────────────────────────────────────────────────

  Future<void> changePassword({
    required String accessToken,
    required String oldPassword,
    required String newPassword,
    required String confirmNewPassword,
  }) async {
    final response = await _client.post(
      Uri.parse(AppConstants.changePasswordEndpoint),
      headers: _authHeaders(accessToken),
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
        'confirm_new_password': confirmNewPassword,
      }),
    );
    _parseResponse(response);
  }

  // ─── Get Current User ──────────────────────────────────────────────────────

  Future<UserModel> getMe({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse(AppConstants.meEndpoint),
      headers: _authHeaders(accessToken),
    );
    final body = _parseResponse(response);
    return UserModel.fromJson(body['data']);
  }
}
