part of 'doctor_cubit.dart';

abstract class DoctorState {
  const DoctorState();
}

class DoctorInitial extends DoctorState {
  const DoctorInitial();
}

class DoctorLoading extends DoctorState {
  const DoctorLoading();
}

/// FIX: new state — emitted when only slots are loading so the doctor card
/// in BookAppointmentScreen stays visible (doesn't get replaced by a spinner).
class DoctorSlotsLoading extends DoctorState {
  const DoctorSlotsLoading();
}

class DoctorListLoaded extends DoctorState {
  final List<DoctorModel> doctors;
  const DoctorListLoaded(this.doctors);
}

class DoctorDetailLoaded extends DoctorState {
  final DoctorModel doctor;
  const DoctorDetailLoaded(this.doctor);
}

/// FIX: removed 'doctor' field — BookAppointmentScreen already has the doctor
/// passed in as a constructor parameter; it doesn't need it from state.
class DoctorSlotsLoaded extends DoctorState {
  final AvailableSlotsModel slots;
  const DoctorSlotsLoaded({required this.slots});
}

class DoctorError extends DoctorState {
  final String message;
  const DoctorError(this.message);
}

class DoctorReviewSubmitted extends DoctorState {
  const DoctorReviewSubmitted();
}