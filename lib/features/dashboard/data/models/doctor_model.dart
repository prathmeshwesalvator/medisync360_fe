class DoctorSlotModel {
  final int id;
  final int day;
  final String dayDisplay;
  final String startTime;
  final String endTime;
  final int maxPatients;
  final bool isActive;

  const DoctorSlotModel({
    required this.id,
    required this.day,
    required this.dayDisplay,
    required this.startTime,
    required this.endTime,
    required this.maxPatients,
    required this.isActive,
  });

  factory DoctorSlotModel.fromJson(Map<String, dynamic> j) => DoctorSlotModel(
        id: j['id'] ?? 0,
        day: j['day'] ?? 0,
        dayDisplay: j['day_display'] ?? '',
        startTime: j['start_time'] ?? '',
        endTime: j['end_time'] ?? '',
        maxPatients: j['max_patients'] ?? 1,
        isActive: j['is_active'] ?? true,
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
        id: j['id'] ?? 0,
        patientName: j['patient_name'] ?? '',
        rating: j['rating'] ?? 0,
        comment: j['comment'] ?? '',
        createdAt: j['created_at'] ?? '',
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
    required this.city,
    required this.state,
    required this.isAvailable,
    this.profileImage = '',
    this.hospitalName,
    this.bio = '',
    this.slots = const [],
    this.reviews = const [],
  });

  factory DoctorModel.fromJson(Map<String, dynamic> j) => DoctorModel(
        id: j['id'] ?? 0,
        fullName: j['full_name'] ?? '',
        specialization: j['specialization'] ?? '',
        qualification: j['qualification'] ?? '',
        experienceYears: j['experience_years'] ?? 0,
        consultationFee: double.tryParse('${j['consultation_fee']}') ?? 0,
        averageRating: double.tryParse('${j['average_rating']}') ?? 0,
        totalReviews: j['total_reviews'] ?? 0,
        city: j['city'] ?? '',
        state: j['state'] ?? '',
        isAvailable: j['is_available'] ?? true,
        profileImage: j['profile_image'] ?? '',
        hospitalName: j['hospital_name'],
        bio: j['bio'] ?? '',
        slots: (j['slots'] as List? ?? []).map((s) => DoctorSlotModel.fromJson(s)).toList(),
        reviews: (j['reviews'] as List? ?? []).map((r) => DoctorReviewModel.fromJson(r)).toList(),
      );
}

class AvailableSlotsModel {
  final String date;
  final String dayName;
  final List<DoctorSlotModel> slots;
  final List<String> bookedTimes;
  final bool isOnLeave;

  const AvailableSlotsModel({
    required this.date,
    required this.dayName,
    required this.slots,
    required this.bookedTimes,
    required this.isOnLeave,
  });

  factory AvailableSlotsModel.fromJson(Map<String, dynamic> j) => AvailableSlotsModel(
        date: j['date'] ?? '',
        dayName: j['day_name'] ?? '',
        slots: (j['slots'] as List? ?? []).map((s) => DoctorSlotModel.fromJson(s)).toList(),
        bookedTimes: (j['booked_times'] as List? ?? []).map((t) => t.toString()).toList(),
        isOnLeave: j['is_on_leave'] ?? false,
      );
}