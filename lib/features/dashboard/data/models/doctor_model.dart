class DoctorSlotModel {
  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final String status;  // 'available' | 'booked' | 'blocked'

  // Legacy weekly-schedule fields (used in DoctorDetailSerializer)
  final int day;
  final String dayDisplay;
  final int maxPatients;
  final bool isActive;

  const DoctorSlotModel({
    required this.id,
    this.date = '',
    required this.startTime,
    this.endTime = '',
    this.status = 'available',
    this.day = 0,
    this.dayDisplay = '',
    this.maxPatients = 1,
    this.isActive = true,
  });

  bool get isAvailable => status == 'available';

  factory DoctorSlotModel.fromJson(Map<String, dynamic> j) => DoctorSlotModel(
        id:          j['id'] ?? 0,
        date:        j['date'] ?? '',
        startTime:   j['start_time'] ?? '',
        endTime:     j['end_time'] ?? '',
        status:      j['status'] ?? 'available',
        day:         j['day'] ?? j['day_of_week'] ?? 0,
        dayDisplay:  j['day_display'] ?? j['day_label'] ?? '',
        maxPatients: j['max_patients'] ?? 1,
        isActive:    j['is_active'] ?? true,
      );
}

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
        id:          j['id'] ?? 0,
        patientName: j['patient_name'] ?? '',
        rating:      j['rating'] ?? 0,
        comment:     j['comment'] ?? '',
        createdAt:   j['created_at'] ?? '',
      );
}

class DoctorModel {
  final int id;
  final String fullName;
  final String specialization;
  final String qualification;
  final int experienceYears;
  final double consultationFee;
  final double averageRating;
  final int totalReviews;
  final String city;
  final String state;
  final bool isAvailable;
  final String profileImage;
  final String? hospitalName;
  final String bio;
  final List<DoctorSlotModel> slots;
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
    this.city = '',
    this.state = '',
    required this.isAvailable,
    this.profileImage = '',
    this.hospitalName,
    this.bio = '',
    this.slots = const [],
    this.reviews = const [],
  });

  factory DoctorModel.fromJson(Map<String, dynamic> j) => DoctorModel(
        id:              j['id'] ?? 0,
        fullName:        j['full_name'] ?? '',
        specialization:  j['specialization'] ?? '',
        qualification:   j['qualification'] ?? '',
        experienceYears: j['experience_years'] ?? 0,
        consultationFee: double.tryParse('${j['consultation_fee']}') ?? 0,
        averageRating:   double.tryParse('${j['average_rating'] ?? j['rating']}') ?? 0,
        totalReviews:    j['total_reviews'] ?? 0,
        city:            j['city'] ?? '',
        state:           j['state'] ?? '',
        isAvailable:     j['is_available_today'] ?? j['is_available'] ?? true,
        profileImage:    j['profile_image'] ?? '',
        hospitalName:    j['hospital_name'],
        bio:             j['bio'] ?? '',
        slots: (j['weekly_schedule'] as List? ?? j['slots'] as List? ?? [])
            .map((s) => DoctorSlotModel.fromJson(s))
            .toList(),
        reviews: (j['reviews'] as List? ?? [])
            .map((r) => DoctorReviewModel.fromJson(r))
            .toList(),
      );
}

/// Returned by /api/doctors/<id>/slots/?date=YYYY-MM-DD
/// Backend sends a flat list of TimeSlot records via TimeSlotSerializer.
class AvailableSlotsModel {
  final String date;
  final List<DoctorSlotModel> slots;

  const AvailableSlotsModel({required this.date, required this.slots});

  /// Parse from a flat list (current backend sends a plain list).
  factory AvailableSlotsModel.fromList(List<dynamic> list, {String date = ''}) =>
      AvailableSlotsModel(
        date: date,
        slots: list.map((s) => DoctorSlotModel.fromJson(s)).toList(),
      );

  /// Parse from a structured map (future backend shape).
  factory AvailableSlotsModel.fromJson(Map<String, dynamic> j) =>
      AvailableSlotsModel(
        date: j['date'] ?? '',
        slots: (j['slots'] as List? ?? (j['data'] as List? ?? []))
            .map((s) => DoctorSlotModel.fromJson(s))
            .toList(),
      );
}