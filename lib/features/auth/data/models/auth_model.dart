class UserRole {
  static const String user = 'user';
  static const String doctor = 'doctor';
  static const String hospital = 'hospital';
  static const String admin = 'admin';
}

class ApprovalStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class DoctorProfile {
  final String specialization;
  final String qualification;
  final int experienceYears;
  final String licenseNumber;
  final String bio;
  final double consultationFee;

  const DoctorProfile({
    required this.specialization,
    required this.qualification,
    required this.experienceYears,
    required this.licenseNumber,
    this.bio = '',
    this.consultationFee = 0,
  });

  factory DoctorProfile.fromJson(Map<String, dynamic> json) => DoctorProfile(
        specialization: json['specialization'] ?? '',
        qualification: json['qualification'] ?? '',
        experienceYears: json['experience_years'] ?? 0,
        licenseNumber: json['license_number'] ?? '',
        bio: json['bio'] ?? '',
        consultationFee: double.tryParse('${json['consultation_fee']}') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'specialization': specialization,
        'qualification': qualification,
        'experience_years': experienceYears,
        'license_number': licenseNumber,
        'bio': bio,
        'consultation_fee': consultationFee,
      };
}

class HospitalProfile {
  final String hospitalName;
  final String registrationNumber;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final int totalBeds;
  final int icuBeds;
  final String phone;
  final String website;

  const HospitalProfile({
    required this.hospitalName,
    required this.registrationNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.totalBeds,
    required this.icuBeds,
    required this.phone,
    this.website = '',
  });

  factory HospitalProfile.fromJson(Map<String, dynamic> json) => HospitalProfile(
        hospitalName: json['hospital_name'] ?? '',
        registrationNumber: json['registration_number'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        pincode: json['pincode'] ?? '',
        totalBeds: json['total_beds'] ?? 0,
        icuBeds: json['icu_beds'] ?? 0,
        phone: json['phone'] ?? '',
        website: json['website'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'hospital_name': hospitalName,
        'registration_number': registrationNumber,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'total_beds': totalBeds,
        'icu_beds': icuBeds,
        'phone': phone,
        'website': website,
      };
}

class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final String approvalStatus;
  final String? profilePicture;
  final DoctorProfile? doctorProfile;
  final HospitalProfile? hospitalProfile;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.approvalStatus,
    this.profilePicture,
    this.doctorProfile,
    this.hospitalProfile,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        email: json['email'],
        fullName: json['full_name'],
        phone: json['phone'] ?? '',
        role: json['role'],
        approvalStatus: json['approval_status'],
        profilePicture: json['profile_picture'],
        doctorProfile: json['doctor_profile'] != null
            ? DoctorProfile.fromJson(json['doctor_profile'])
            : null,
        hospitalProfile: json['hospital_profile'] != null
            ? HospitalProfile.fromJson(json['hospital_profile'])
            : null,
      );
}

class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        access: json['access'],
        refresh: json['refresh'],
      );
}

class AuthResult {
  final AuthTokens? tokens;
  final UserModel user;

  const AuthResult({this.tokens, required this.user});
}