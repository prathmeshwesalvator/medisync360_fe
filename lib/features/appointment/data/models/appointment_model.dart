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
}

class AppointmentType {
  static const String inPerson = 'in_person';
  static const String video    = 'video';
  static const String phone    = 'phone';

  static String label(String type) {
    switch (type) {
      case video:   return 'Video Call';
      case phone:   return 'Phone Call';
      default:      return 'In Person';
    }
  }
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
  final String appointmentDate;
  final String slotTime;
  final String appointmentType;
  final String status;
  final double consultationFee;
  final String paymentStatus;
  final String? paymentMarkedAt;
  final String reason;
  final String symptoms;
  final String notes;
  final String diagnosis;
  final String prescription;
  final String cancelReason;
  final int rescheduleCount;
  final String? confirmedAt;
  final String? completedAt;
  final String meetingLink;
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
    this.paymentMarkedAt,
    this.reason = '',
    this.symptoms = '',
    this.notes = '',
    this.diagnosis = '',
    this.prescription = '',
    this.cancelReason = '',
    this.rescheduleCount = 0,
    this.confirmedAt,
    this.completedAt,
    this.meetingLink = '',
    required this.createdAt,
    this.updatedAt = '',
    this.statusLogs = const [],
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> j) => AppointmentModel(
        id:              j['id'] ?? 0,
        patientName:     j['patient_name'] ?? '',
        patientEmail:    j['patient_email'] ?? '',
        patientPhone:    j['patient_phone'] ?? '',
        doctorName:      j['doctor_name'] ?? '',
        doctorSpecialty: j['doctor_specialty'] ?? j['specialization'] ?? '',
        hospitalName:    j['hospital_name'],
        appointmentDate: j['appointment_date'] ?? j['date'] ?? '',
        slotTime:        j['slot_time'] ?? j['start_time'] ?? '',
        appointmentType: j['appointment_type'] ?? AppointmentType.inPerson,
        status:          j['status'] ?? AppointmentStatus.pending,
        consultationFee: double.tryParse('${j['consultation_fee']}') ?? 0,
        paymentStatus:   j['payment_status'] ?? PaymentStatus.unpaid,
        paymentMarkedAt: j['payment_marked_at'],
        reason:          j['reason'] ?? '',
        symptoms:        j['symptoms'] ?? '',
        notes:           j['notes'] ?? '',
        diagnosis:       j['diagnosis'] ?? '',
        prescription:    j['prescription'] ?? '',
        cancelReason:    j['cancel_reason'] ?? '',
        rescheduleCount: j['reschedule_count'] ?? 0,
        confirmedAt:     j['confirmed_at'],
        completedAt:     j['completed_at'],
        meetingLink:     j['meeting_link'] ?? '',
        createdAt:       j['created_at'] ?? '',
        updatedAt:       j['updated_at'] ?? '',
        statusLogs: (j['status_logs'] as List? ?? [])
            .map((s) => StatusLogModel.fromJson(s))
            .toList(),
      );

  // ── Computed helpers ────────────────────────────────────────────────────
  bool get isUpcoming      => status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
  bool get isCancellable   => status == AppointmentStatus.pending || status == AppointmentStatus.confirmed;
  bool get isReschedulable => isCancellable && rescheduleCount < 3;
  bool get canPay          => status == AppointmentStatus.confirmed && paymentStatus == PaymentStatus.unpaid;
  bool get hasNotes        => notes.isNotEmpty || diagnosis.isNotEmpty || prescription.isNotEmpty;
  bool get isVirtual       => appointmentType == AppointmentType.video || appointmentType == AppointmentType.phone;
  bool get hasMeetingLink  => meetingLink.isNotEmpty;
  bool get canConfirm      => status == AppointmentStatus.pending || status == AppointmentStatus.rescheduled;
  bool get canComplete     => status == AppointmentStatus.confirmed;
  bool get canMarkNoShow   => status == AppointmentStatus.confirmed;
}

class AppointmentStats {
  final int total;
  final int pending;
  final int confirmed;
  final int completed;
  final int cancelled;
  final int upcoming;

  const AppointmentStats({
    this.total = 0, this.pending = 0, this.confirmed = 0,
    this.completed = 0, this.cancelled = 0, this.upcoming = 0,
  });

  factory AppointmentStats.fromJson(Map<String, dynamic> j) => AppointmentStats(
        total:     j['total'] ?? 0,
        pending:   j['pending'] ?? 0,
        confirmed: j['confirmed'] ?? 0,
        completed: j['completed'] ?? 0,
        cancelled: j['cancelled'] ?? 0,
        upcoming:  j['upcoming'] ?? 0,
      );
}