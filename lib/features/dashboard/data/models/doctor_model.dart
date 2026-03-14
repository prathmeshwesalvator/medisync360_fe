// ── DoctorSlotModel ──────────────────────────────────────────────────────────
// FIX: Backend /api/doctors/<id>/slots/ returns a flat list of TimeSlot objects:
//   { id, date, start_time, end_time, status }
// The old model expected { id, day, day_display, start_time, end_time, max_patients, is_active }
// which is the WeeklySchedule shape — wrong model was used.
class DoctorSlotModel {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final String status; // "available" | "booked" | "blocked"

  const DoctorSlotModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory DoctorSlotModel.fromJson(Map<String, dynamic> j) => DoctorSlotModel(
        id: j['id'] ?? 0,
        date: j['date'] ?? '',
        startTime: j['start_time'] ?? '',
        endTime: j['end_time'] ?? '',
        status: j['status'] ?? 'available',
      );

  bool get isAvailable => status == 'available';
}

// ── AvailableSlotsModel ───────────────────────────────────────────────────────
// FIX: Backend returns a plain list [] inside data, not a structured object.
// We build this wrapper in the repository so the UI contract stays the same.
class AvailableSlotsModel {
  final String date;
  final List<DoctorSlotModel> slots;
  final bool isOnLeave;

  const AvailableSlotsModel({
    required this.date,
    required this.slots,
    this.isOnLeave = false,
  });

  /// Build from the raw list returned by GET /api/doctors/<id>/slots/?date=...
  factory AvailableSlotsModel.fromList(String date, List<dynamic> list) {
    final slots = list.map((s) => DoctorSlotModel.fromJson(s)).toList();
    return AvailableSlotsModel(
      date: date,
      slots: slots,
      isOnLeave: false,
    );
  }

  /// Convenience: only the booked start times (for greying out in UI)
  List<String> get bookedTimes => slots
      .where((s) => s.status == 'booked')
      .map((s) => s.startTime)
      .toList();
}

// ── DoctorReviewModel ─────────────────────────────────────────────────────────
class DoctorReviewModel {
  final int id;
  final String patientName;
  final int rating;
  final String comment;
  final String createdAt;

  const DoctorReviewModel({
    required this.id,
    required this.patientName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory DoctorReviewModel.fromJson(Map<String, dynamic> j) => DoctorReviewModel(
        id: j['id'] ?? 0,
        patientName: j['patient_name'] ?? '',
        rating: j['rating'] ?? 0,
        comment: j['comment'] ?? '',
        createdAt: j['created_at'] ?? '',
      );
}

// ── DoctorModel ───────────────────────────────────────────────────────────────
// FIX: Backend DoctorDetailSerializer returns 'rating' not 'average_rating',
//      'is_available_today' not 'is_available', and has no 'city'/'state' —
//      those come from the linked hospital. Safe defaults added.
class DoctorModel {
  final int id;
  final String fullName;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double consultationFee;
  final double averageRating;
  final int totalReviews;
  final bool isAvailable;
  final String profileImage;
  final String? hospitalName;
  final String bio;
  final List<DoctorReviewModel> reviews;

  const DoctorModel({
    required this.id,
    required this.fullName,
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.consultationFee,
    required this.averageRating,
    required this.totalReviews,
    required this.isAvailable,
    this.profileImage = '',
    this.hospitalName,
    this.bio = '',
    this.reviews = const [],
  });

  factory DoctorModel.fromJson(Map<String, dynamic> j) => DoctorModel(
        id: j['id'] ?? 0,
        fullName: j['full_name'] ?? '',
        specialization: j['specialization_label'] ?? j['specialization'] ?? '',
        qualification: j['qualification'] ?? '',
        experienceYears: j['experience_years'] ?? 0,
        consultationFee: double.tryParse('${j['consultation_fee']}') ?? 0,
        // FIX: backend field is 'rating', not 'average_rating'
        averageRating: double.tryParse('${j['rating']}') ?? 0,
        totalReviews: j['total_reviews'] ?? 0,
        // FIX: backend field is 'is_available_today', not 'is_available'
        isAvailable: j['is_available_today'] ?? j['is_available'] ?? true,
        profileImage: j['profile_image'] ?? '',
        hospitalName: j['hospital_name'],
        bio: j['bio'] ?? '',
        reviews: (j['reviews'] as List? ?? [])
            .map((r) => DoctorReviewModel.fromJson(r))
            .toList(),
      );
}