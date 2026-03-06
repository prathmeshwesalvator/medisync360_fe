part of 'appointment_cubit.dart';

abstract class AppointmentState { const AppointmentState(); }
class AppointmentInitial extends AppointmentState { const AppointmentInitial(); }
class AppointmentLoading extends AppointmentState { const AppointmentLoading(); }
class AppointmentListLoaded extends AppointmentState {
  final List<AppointmentModel> appointments;
  const AppointmentListLoaded(this.appointments);
}
class AppointmentDetailLoaded extends AppointmentState {
  final AppointmentModel appointment;
  const AppointmentDetailLoaded(this.appointment);
}
class AppointmentBooked extends AppointmentState {
  final AppointmentModel appointment;
  const AppointmentBooked(this.appointment);
}
class AppointmentActionSuccess extends AppointmentState {
  final String message;
  final AppointmentModel appointment;
  const AppointmentActionSuccess({required this.message, required this.appointment});
}
class AppointmentError extends AppointmentState {
  final String message;
  const AppointmentError(this.message);
}