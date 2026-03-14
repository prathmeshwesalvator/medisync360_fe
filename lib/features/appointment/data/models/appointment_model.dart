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
  final String patientEmail;
  final String patientPhone;
  final String doctorName;
  final String doctorSpecialty;
  final String? hospitalName;
  final String appointmentDate; // "YYYY-MM-DD"
  final String slotTime;        // "HH:MM:SS"
  final String appointmentType;
  final String status;
  final double consultationFee;
  final String paymentStatus;
  final String reason;
  final String symptoms;
  final String notes;
  final String cancelReason;
  final int rescheduleCount;
  final String createdAt;
  final String updatedAt;
  final List<StatusLogModel> statusLogs;

  const AppointmentModel({
    required this.id,
    required this.patientName,
    this.patientEmail = '',
    this.patientPhone = '',
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
    this.cancelReason = '',
    this.rescheduleCount = 0,
    required this.createdAt,
    this.updatedAt = '',
    this.statusLogs = const [],
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
        id: j['id'] ?? 0,
        patientName: j['patient_name'] ?? '',
        patientEmail: j['patient_email'] ?? '',
        patientPhone: j['patient_phone'] ?? '',
        doctorName: j['doctor_name'] ?? '',
        // FIX: backend now returns 'doctor_specialty' (fixed in serializers.py)
        doctorSpecialty: j['doctor_specialty'] ?? j['specialization'] ?? '',
        hospitalName: j['hospital_name'],
        // FIX: backend now returns 'appointment_date' (fixed in serializers.py)
        appointmentDate: j['appointment_date'] ?? j['date'] ?? '',
        // FIX: backend now returns 'slot_time' (fixed in serializers.py)
        slotTime: j['slot_time'] ?? j['start_time'] ?? '',
        // FIX: backend returns 'appointment_type' via SerializerMethodField
        appointmentType: j['appointment_type'] ?? AppointmentType.inPerson,
        status: j['status'] ?? AppointmentStatus.pending,
        consultationFee: double.tryParse('${j['consultation_fee']}') ?? 0,
        paymentStatus: j['payment_status'] ?? PaymentStatus.unpaid,
        reason: j['reason'] ?? '',
        symptoms: j['symptoms'] ?? '',
        notes: j['notes'] ?? '',
        cancelReason: j['cancel_reason'] ?? '',
        rescheduleCount: j['reschedule_count'] ?? 0,
        createdAt: j['created_at'] ?? '',
        updatedAt: j['updated_at'] ?? '',
        statusLogs: (j['status_logs'] as List? ?? [])
            .map((s) => StatusLogModel.fromJson(s))
            .toList(),
      );

  bool get isUpcoming =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get isCancellable =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;

  bool get isReschedulable =>
      status == AppointmentStatus.pending ||
      status == AppointmentStatus.confirmed;
}