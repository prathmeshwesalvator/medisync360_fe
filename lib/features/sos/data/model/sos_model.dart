class SosStatus {
  static const String active    = 'active';
  static const String accepted  = 'accepted';
  static const String enroute   = 'enroute';
  static const String arrived   = 'arrived';
  static const String resolved  = 'resolved';
  static const String cancelled = 'cancelled';
}

class SosSeverity {
  static const String critical = 'critical';
  static const String high     = 'high';
  static const String medium   = 'medium';
}

class SosStatusLogModel {
  final int id;
  final String fromStatus;
  final String toStatus;
  final String? changedByName;
  final String note;
  final String changedAt;

  const SosStatusLogModel({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    this.changedByName,
    required this.note,
    required this.changedAt,
  });

  factory SosStatusLogModel.fromJson(Map<String, dynamic> j) => SosStatusLogModel(
        id: j['id'] ?? 0,
        fromStatus: j['from_status'] ?? '',
        toStatus: j['to_status'] ?? '',
        changedByName: j['changed_by_name'],
        note: j['note'] ?? '',
        changedAt: j['changed_at'] ?? '',
      );
}

class SosAlertModel {
  final int id;
  final String patientName;
  final String patientPhone;
  final double latitude;
  final double longitude;
  final String address;
  final String severity;
  final String description;
  final String bloodGroup;
  final String allergies;
  final String medications;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String status;
  final String? respondingHospitalName;
  final String? acceptedAt;
  final String? enrouteAt;
  final String? arrivedAt;
  final String? resolvedAt;
  final int? etaMinutes;
  final double? ambulanceLatitude;
  final double? ambulanceLongitude;
  final String ambulanceNumber;
  final String createdAt;
  final String updatedAt;
  final List<SosStatusLogModel> statusLogs;

  // Only set when returned as part of hospital active list
  final double? distanceKm;

  const SosAlertModel({
    required this.id,
    required this.patientName,
    this.patientPhone = '',
    required this.latitude,
    required this.longitude,
    this.address = '',
    required this.severity,
    this.description = '',
    this.bloodGroup = '',
    this.allergies = '',
    this.medications = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    required this.status,
    this.respondingHospitalName,
    this.acceptedAt,
    this.enrouteAt,
    this.arrivedAt,
    this.resolvedAt,
    this.etaMinutes,
    this.ambulanceLatitude,
    this.ambulanceLongitude,
    this.ambulanceNumber = '',
    required this.createdAt,
    this.updatedAt = '',
    this.statusLogs = const [],
    this.distanceKm,
  });

  factory SosAlertModel.fromJson(Map<String, dynamic> j) => SosAlertModel(
        id: j['id'] ?? 0,
        patientName: j['patient_name'] ?? '',
        patientPhone: j['patient_phone'] ?? '',
        latitude: double.tryParse('${j['latitude']}') ?? 0,
        longitude: double.tryParse('${j['longitude']}') ?? 0,
        address: j['address'] ?? '',
        severity: j['severity'] ?? SosSeverity.high,
        description: j['description'] ?? '',
        bloodGroup: j['blood_group'] ?? '',
        allergies: j['allergies'] ?? '',
        medications: j['medications'] ?? '',
        emergencyContactName: j['emergency_contact_name'] ?? '',
        emergencyContactPhone: j['emergency_contact_phone'] ?? '',
        status: j['status'] ?? SosStatus.active,
        respondingHospitalName: j['responding_hospital_name'],
        acceptedAt: j['accepted_at'],
        enrouteAt: j['enroute_at'],
        arrivedAt: j['arrived_at'],
        resolvedAt: j['resolved_at'],
        etaMinutes: j['eta_minutes'],
        ambulanceLatitude: j['ambulance_latitude'] != null
            ? double.tryParse('${j['ambulance_latitude']}')
            : null,
        ambulanceLongitude: j['ambulance_longitude'] != null
            ? double.tryParse('${j['ambulance_longitude']}')
            : null,
        ambulanceNumber: j['ambulance_number'] ?? '',
        createdAt: j['created_at'] ?? '',
        updatedAt: j['updated_at'] ?? '',
        statusLogs: (j['status_logs'] as List? ?? [])
            .map((s) => SosStatusLogModel.fromJson(s))
            .toList(),
        distanceKm: j['distance_km'] != null
            ? double.tryParse('${j['distance_km']}')
            : null,
      );

  bool get isActive    => status == SosStatus.active;
  bool get isAccepted  => status == SosStatus.accepted;
  bool get isEnroute   => status == SosStatus.enroute;
  bool get isArrived   => status == SosStatus.arrived;
  bool get isResolved  => status == SosStatus.resolved;
  bool get isCancelled => status == SosStatus.cancelled;
  bool get isLive      => isActive || isAccepted || isEnroute;
  bool get hasAmbulanceLocation =>
      ambulanceLatitude != null && ambulanceLongitude != null;
}