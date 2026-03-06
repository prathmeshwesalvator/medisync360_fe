class HospitalStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
  static const String maintenance = 'maintenance';
}

class HospitalDepartment {
  final int id;
  final String name;
  final String nameDisplay;
  final String headDoctorName;
  final String phoneExtension;
  final String floor;
  final bool isActive;

  const HospitalDepartment({
    required this.id,
    required this.name,
    required this.nameDisplay,
    this.headDoctorName = '',
    this.phoneExtension = '',
    this.floor = '',
    this.isActive = true,
  });

  factory HospitalDepartment.fromJson(Map<String, dynamic> json) =>
      HospitalDepartment(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        nameDisplay: json['name_display'] ?? json['name'] ?? '',
        headDoctorName: json['head_doctor_name'] ?? '',
        phoneExtension: json['phone_extension'] ?? '',
        floor: json['floor'] ?? '',
        isActive: json['is_active'] ?? true,
      );
}

class HospitalAmenity {
  final int id;
  final String name;
  final bool isAvailable;

  const HospitalAmenity({
    required this.id,
    required this.name,
    required this.isAvailable,
  });

  factory HospitalAmenity.fromJson(Map<String, dynamic> json) =>
      HospitalAmenity(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        isAvailable: json['is_available'] ?? true,
      );
}

class HospitalModel {
  final int id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String email;
  final String website;
  final String logoUrl;
  final String imageUrl;
  final String description;
  final String status;

  // Capacity
  final int totalBeds;
  final int availableBeds;
  final int icuTotal;
  final int icuAvailable;
  final int emergencyBeds;
  final int emergencyAvailable;
  final double bedOccupancyPercent;
  final double icuOccupancyPercent;

  // Location
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  // Meta
  final bool isVerified;
  final int? establishedYear;

  // Relations (only in detail view)
  final List<HospitalDepartment> departments;
  final List<HospitalAmenity> amenities;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    this.email = '',
    this.website = '',
    this.logoUrl = '',
    this.imageUrl = '',
    this.description = '',
    this.status = HospitalStatus.active,
    required this.totalBeds,
    required this.availableBeds,
    required this.icuTotal,
    required this.icuAvailable,
    required this.emergencyBeds,
    required this.emergencyAvailable,
    this.bedOccupancyPercent = 0,
    this.icuOccupancyPercent = 0,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.isVerified = false,
    this.establishedYear,
    this.departments = const [],
    this.amenities = const [],
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) => HospitalModel(
        id: json['id'],
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        pincode: json['pincode'] ?? '',
        phone: json['phone'] ?? '',
        email: json['email'] ?? '',
        website: json['website'] ?? '',
        logoUrl: json['logo_url'] ?? '',
        imageUrl: json['image_url'] ?? '',
        description: json['description'] ?? '',
        status: json['status'] ?? HospitalStatus.active,
        totalBeds: json['total_beds'] ?? 0,
        availableBeds: json['available_beds'] ?? 0,
        icuTotal: json['icu_total'] ?? 0,
        icuAvailable: json['icu_available'] ?? 0,
        emergencyBeds: json['emergency_beds'] ?? 0,
        emergencyAvailable: json['emergency_available'] ?? 0,
        bedOccupancyPercent:
            double.tryParse('${json['bed_occupancy_percent']}') ?? 0,
        icuOccupancyPercent:
            double.tryParse('${json['icu_occupancy_percent']}') ?? 0,
        latitude: json['latitude'] != null
            ? double.tryParse('${json['latitude']}')
            : null,
        longitude: json['longitude'] != null
            ? double.tryParse('${json['longitude']}')
            : null,
        distanceKm: json['distance_km'] != null
            ? double.tryParse('${json['distance_km']}')
            : null,
        isVerified: json['is_verified'] ?? false,
        establishedYear: json['established_year'],
        departments: (json['departments'] as List<dynamic>? ?? [])
            .map((d) => HospitalDepartment.fromJson(d))
            .toList(),
        amenities: (json['amenities'] as List<dynamic>? ?? [])
            .map((a) => HospitalAmenity.fromJson(a))
            .toList(),
      );

  int get occupiedBeds => totalBeds - availableBeds;
  bool get hasAvailableBeds => availableBeds > 0;
  bool get hasAvailableICU => icuAvailable > 0;
}

class HospitalListResponse {
  final int count;
  final List<HospitalModel> results;

  const HospitalListResponse({required this.count, required this.results});

  factory HospitalListResponse.fromJson(Map<String, dynamic> json) =>
      HospitalListResponse(
        count: json['count'] ?? 0,
        results: (json['results'] as List<dynamic>? ?? [])
            .map((h) => HospitalModel.fromJson(h))
            .toList(),
      );
}