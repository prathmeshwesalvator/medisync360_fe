class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String notifType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.notifType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
    id:         j['id'],
    title:      j['title'] ?? '',
    body:       j['body'] ?? '',
    notifType:  j['notif_type'] ?? '',
    isRead:     j['is_read'] ?? false,
    createdAt:  DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
  );

  String get typeLabel {
    switch (notifType) {
      case 'appointment_booked':      return 'Appointment';
      case 'appointment_cancelled':   return 'Cancelled';
      case 'appointment_reminder':    return 'Reminder';
      case 'appointment_completed':   return 'Completed';
      case 'appointment_rescheduled': return 'Rescheduled';
      case 'lab_report_uploaded':     return 'Lab Report';
      case 'prescription_added':      return 'Prescription';
      default:                        return 'General';
    }
  }

  String get typeIcon {
    switch (notifType) {
      case 'appointment_booked':
      case 'appointment_confirmed':   return '📅';
      case 'appointment_cancelled':   return '❌';
      case 'appointment_reminder':    return '⏰';
      case 'appointment_completed':   return '✅';
      case 'appointment_rescheduled': return '🔄';
      case 'lab_report_uploaded':     return '🧪';
      case 'prescription_added':      return '💊';
      default:                        return '🔔';
    }
  }
}