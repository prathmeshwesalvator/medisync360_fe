class AppConstants {
  AppConstants._();

  // Change host based on your environment:
  // Android emulator  → 10.0.2.2
  // iOS simulator     → localhost
  // Physical device   → your machine IP

  // static const String _host = '0.0.0.0';
  static const String _host = '10.17.165.65';
  static const String _base = 'http://$_host:8000/api';
  static const String adminBase = 'http://$_host:8000/admin/';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String loginEndpoint = '$_base/auth/login/';
  static const String registerUserEndpoint = '$_base/auth/register/user/';
  static const String registerDoctorEndpoint = '$_base/auth/register/doctor/';
  static const String registerHospitalEndpoint =
      '$_base/auth/register/hospital/';
  static const String logoutEndpoint = '$_base/auth/logout/';
  static const String meEndpoint = '$_base/auth/me/';
  static const String tokenRefreshEndpoint = '$_base/token/refresh/';
  static const String changePasswordEndpoint = '$_base/auth/change-password/';

  // ── Hospitals ───────────────────────────────────────────────────────────────
  static const String hospitalsEndpoint = '$_base/hospitals/';
  static const String nearbyHospitalsEndpoint = '$_base/hospitals/nearby/';
  static const String hospitalsMapEndpoint = '$_base/hospitals/map/';
  static const String myHospitalEndpoint = '$_base/hospitals/my/';
  static const String myCapacityEndpoint = '$_base/hospitals/my/capacity/';

  // ── Doctors ─────────────────────────────────────────────────────────────────
  static const String doctorsEndpoint = '$_base/doctors/';
  static const String myDoctorProfileEndpoint = '$_base/doctors/my/';
  static const String myScheduleEndpoint = '$_base/doctors/my/schedule/';
  static const String mySlotBlocksEndpoint = '$_base/doctors/my/blocks/';

  // ── Appointments ─────────────────────────────────────────────────────────────
  static const String appointmentsEndpoint = '$_base/appointments/';
  static const String myAppointmentsEndpoint = '$_base/appointments/my/';
  static const String doctorAppointmentsEndpoint =
      '$_base/appointments/doctor/mine/';

  // ── EHR ─────────────────────────────────────────────────────────────────────
  static const String myHistoryEndpoint = '$_base/ehr/my/history/';
  static const String myPrescriptionsEndpoint = '$_base/ehr/my/prescriptions/';
  static const String myNotesEndpoint = '$_base/ehr/my/notes/';
  static const String myImagingEndpoint = '$_base/ehr/my/imaging/';

  // ── Lab Reports ──────────────────────────────────────────────────────────────
  static const String labReportsEndpoint = '$_base/lab-reports/';

  // ── Notifications ────────────────────────────────────────────────────────────
  static const String notificationsEndpoint = '$_base/notifications/';
  static const String fcmTokenEndpoint = '$_base/notifications/fcm/';
  static const String markAllReadEndpoint = '$_base/notifications/read/';

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static String doctorDetail(int id) => '$_base/doctors/$id/';
  static String doctorSlots(int id) => '$_base/doctors/$id/slots/';
  static String doctorReviews(int id) => '$_base/doctors/$id/reviews/';
  static String hospitalDetail(int id) => '$_base/hospitals/$id/';
  static String appointmentDetail(int id) => '$_base/appointments/$id/';
  static String cancelAppointment(int id) => '$_base/appointments/$id/cancel/';
  static String rescheduleAppointment(int id) =>
      '$_base/appointments/$id/reschedule/';
  static String payAppointment(int id) => '$_base/appointments/$id/pay/';
  static String completeAppointment(int id) =>
      '$_base/appointments/$id/complete/';
  static String markNotificationRead(int id) =>
      '$_base/notifications/$id/read/';
  static String patientEHR(int patientId, String section) =>
      '$_base/ehr/patient/$patientId/$section/';
  static String labReportDetail(int id) => '$_base/lab-reports/$id/';
  static String patientLabReports(int patientId) =>
      '$_base/lab-reports/patient/$patientId/';
}
