part of 'doctor_cubit.dart';

abstract class DoctorState { const DoctorState(); }

class DoctorInitial extends DoctorState { const DoctorInitial(); }

class DoctorLoading extends DoctorState { const DoctorLoading(); }

/// Separate loading state while fetching slots so the doctor
/// detail data already on screen doesn't disappear.
class DoctorSlotsLoading extends DoctorState { const DoctorSlotsLoading(); }

class DoctorListLoaded extends DoctorState {
  final List<DoctorModel> doctors;
  const DoctorListLoaded(this.doctors);
}

class DoctorDetailLoaded extends DoctorState {
  final DoctorModel doctor;
  const DoctorDetailLoaded(this.doctor);
}

class DoctorSlotsLoaded extends DoctorState {
  final DoctorModel doctor;
  final AvailableSlotsModel slots;
  const DoctorSlotsLoaded({required this.doctor, required this.slots});
}

class DoctorError extends DoctorState {
  final String message;
  const DoctorError(this.message);
}

class DoctorReviewSubmitted extends DoctorState {
  const DoctorReviewSubmitted();
}