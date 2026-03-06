class AppointmentStatus {
  static const String pending     = 'pending';
  static const String confirmed   = 'confirmed';
  static const String cancelled   = 'cancelled';
  static const String completed   = 'completed';
  static const String noShow      = 'no_show';
  static const String rescheduled = 'rescheduled';
}

class PaymentStatus {
  static const String unpaid   = 'unpaid';
  static const String paid     = 'paid';
  static const String refunded = 'refunded';
  static const String waived   = 'waived';
}

class AppointmentType {
  static const String inPerson = 'in_person';
  static const String video    = 'video';
  static const String phone    = 'phone';
}

class StatusLogModel {
  final int id;
  final String fromStatus;
  final String toStatus;
  final String? changedByName;
  final String reason;
  final String changedAt;

  const StatusLogModel({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    this.changedByName,
    required this.reason,
    required this.changedAt,
  });

  factory StatusLogModel.fromJson(Map<String, dynamic> j) => StatusLogModel(
        id: j['id'] ?? 0,
        fromStatus: j['from_status'] ?? '',
        toStatus: j['to_status'] ?? '',
        changedByName: j['changed_by_name'],
        reason: j['reason'] ?? '',
        changedAt: j['changed_at'] ?? '',
      );
}

class AppointmentModel {
  final int id;
  final String patientName;
  final String doctorName;
  final String doctorSpecialty;
  final String? hospitalName;
  final String appointmentDate;
  final String slotTime;
  final String appointmentType;
  final String status;
  final double consultationFee;
  final String paymentStatus;
  final String reason;
  final String symptoms;
  final String notes;
  final String createdAt;
  final List<StatusLogModel> statusLogs;
  // Extra fields from detail
  final String patientEmail;
  final String patientPhone;

  const AppointmentModel({
    required this.id,
    required this.patientName,
    required this.doctorName,
    required this.doctorSpecialty,
    this.hospitalName,
    required this.appointmentDate,
    required this.slotTime,
    required this.appointmentType,
    required this.status,
    required this.consultationFee,
    required this.paymentStatus,
    this.reason = '',
    this.symptoms = '',
    this.notes = '',
    required this.createdAt,
    this.statusLogs = const [],
    this.patientEmail = '',
    this.patientPhone = '',
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
        id: j['id'] ?? 0,
        patientName: j['patient_name'] ?? '',
        doctorName: j['doctor_name'] ?? '',
        doctorSpecialty: j['doctor_specialty'] ?? '',
        hospitalName: j['hospital_name'],
        appointmentDate: j['appointment_date'] ?? '',
        slotTime: j['slot_time'] ?? '',
        appointmentType: j['appointment_type'] ?? AppointmentType.inPerson,
        status: j['status'] ?? AppointmentStatus.pending,
        consultationFee: double.tryParse('${j['consultation_fee']}') ?? 0,
        paymentStatus: j['payment_status'] ?? PaymentStatus.unpaid,
        reason: j['reason'] ?? '',
        symptoms: j['symptoms'] ?? '',
        notes: j['notes'] ?? '',
        createdAt: j['created_at'] ?? '',
        statusLogs: (j['status_logs'] as List? ?? []).map((s) => StatusLogModel.fromJson(s)).toList(),
        patientEmail: j['patient_email'] ?? '',
        patientPhone: j['patient_phone'] ?? '',
      );

  bool get isUpcoming => status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
  bool get isCancellable => status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
  bool get isReschedulable => status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
}