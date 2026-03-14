import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/dashboard/data/models/doctor_model.dart';
import 'package:medisync_app/global/constants/app_constants.dart';

class DoctorRepository {
  final http.Client _client;
  DoctorRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _base = AppConstants.doctorsEndpoint;

  Map<String, String> _auth(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, String> get _open => {'Content-Type': 'application/json'};

  Map<String, dynamic> _parse(http.Response r) {
    final b = jsonDecode(r.body) as Map<String, dynamic>;
    if (b['success'] == true) return b;
    throw ApiException(b['message'] ?? 'Error',
        errors: b['errors'], statusCode: r.statusCode);
  }

  Future<List<DoctorModel>> getDoctors({
    String query = '',
    String specialization = '',
    String city = '',
    bool availableOnly = false,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      if (query.isNotEmpty) 'q': query,
      if (specialization.isNotEmpty) 'specialization': specialization,
      if (city.isNotEmpty) 'city': city,
      if (availableOnly) 'available_only': 'true',
    });
    final r = _parse(await _client.get(uri, headers: _open));
    final data = r['data'];
    // Backend wraps list in {count, results}
    final list = data is Map ? (data['results'] as List? ?? []) : (data as List? ?? []);
    return list.map((d) => DoctorModel.fromJson(d)).toList();
  }

  Future<DoctorModel> getDoctorDetail(int id) async {
    final r = _parse(
        await _client.get(Uri.parse('$_base$id/'), headers: _open));
    return DoctorModel.fromJson(r['data']);
  }

  Future<AvailableSlotsModel> getAvailableSlots(
      int doctorId, String date) async {
    final uri = Uri.parse('$_base$doctorId/slots/')
        .replace(queryParameters: {'date': date});
    final r = _parse(await _client.get(uri, headers: _open));

    // FIX: Backend returns a flat list of TimeSlot objects inside data[],
    // NOT a structured object { date, slots, booked_times, is_on_leave }.
    // Build AvailableSlotsModel from the list using the named constructor.
    final data = r['data'];
    if (data is List) {
      return AvailableSlotsModel.fromList(date, data);
    }
    // Fallback: if backend ever wraps it, handle gracefully
    if (data is Map) {
      final list = data['results'] ?? data['slots'] ?? [];
      return AvailableSlotsModel.fromList(date, list as List);
    }
    return AvailableSlotsModel.fromList(date, []);
  }

  Future<void> submitReview(
      int doctorId, int rating, String comment, String token) async {
    _parse(await _client.post(
      Uri.parse('$_base$doctorId/reviews/'),
      headers: _auth(token),
      body: jsonEncode({'rating': rating, 'comment': comment}),
    ));
  }
}