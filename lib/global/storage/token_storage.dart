import 'dart:convert';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Handles secure local persistence of JWT tokens and user data.
/// Uses shared_preferences — swap for flutter_secure_storage in production.
class TokenStorage {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _userKey = 'user_data';

  // ─── Save ──────────────────────────────────────────────────────────────────

  Future<void> saveTokens(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, tokens.access);
    await prefs.setString(_refreshKey, tokens.refresh);
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
      'id': user.id,
      'email': user.email,
      'full_name': user.fullName,
      'phone': user.phone,
      'role': user.role,
      'approval_status': user.approvalStatus,
      'profile_picture': user.profilePicture,
    }));
  }

  // ─── Get ───────────────────────────────────────────────────────────────────

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey);
  }

  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    final user = await getUser();
    return token != null && user != null;
  }

  // ─── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }
}