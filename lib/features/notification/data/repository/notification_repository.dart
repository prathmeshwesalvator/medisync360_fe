import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/notification/data/model/notification_model.dart';
import 'package:medisync_app/global/constants/app_constants.dart';
import 'package:medisync_app/global/storage/token_storage.dart';



class NotificationRepository {
  final http.Client _client;
  final TokenStorage _storage;

  NotificationRepository({http.Client? client, required TokenStorage storage})
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

  Future<Map<String, dynamic>> getNotifications() async {
    final res = _parse(await _client.get(
      Uri.parse(AppConstants.notificationsEndpoint),
      headers: await _headers(),
    ));
    final data = res['data'] as Map<String, dynamic>? ?? res;
    final results = data['results'] as List? ??
        data['notifications'] as List? ?? [];
    return {
      'unread': data['unread'] ?? 0,
      'notifications':
          results.map((e) => NotificationModel.fromJson(e)).toList(),
    };
  }

  Future<void> markRead({int? id}) async {
    final url = id != null
        ? AppConstants.markNotificationRead(id)
        : AppConstants.markAllReadEndpoint;
    await _client.post(Uri.parse(url), headers: await _headers());
  }

  Future<void> registerFCMToken(String fcmToken, String device) async {
    await _client.post(
      Uri.parse(AppConstants.fcmTokenEndpoint),
      headers: await _headers(),
      body: jsonEncode({'token': fcmToken, 'device': device}),
    );
  }
}