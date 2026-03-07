// ─────────────────────────────────────────────────────────────────────────────
// FILE: features/dashboard/presentation/bloc/hospital_state.dart
// ACTION: REPLACE full file (added HospitalMapLoaded state)
// ─────────────────────────────────────────────────────────────────────────────

part of 'hospital_cubit.dart';

abstract class HospitalState {
  const HospitalState();
}

class HospitalInitial extends HospitalState {
  const HospitalInitial();
}

class HospitalLoading extends HospitalState {
  const HospitalLoading();
}

class HospitalListLoaded extends HospitalState {
  final List<HospitalModel> hospitals;
  final int count;
  final String? appliedQuery;

  const HospitalListLoaded({
    required this.hospitals,
    required this.count,
    this.appliedQuery,
  });
}

// ── NEW: emitted after loadHospitalsForMap() ──────────────────────────────────
class HospitalMapLoaded extends HospitalState {
  final List<HospitalModel> hospitals;
  const HospitalMapLoaded({required this.hospitals});
}

class NearbyHospitalsLoaded extends HospitalState {
  final List<HospitalModel> hospitals;
  const NearbyHospitalsLoaded({required this.hospitals});
}

class HospitalDetailLoaded extends HospitalState {
  final HospitalModel hospital;
  const HospitalDetailLoaded({required this.hospital});
}

class MyHospitalLoaded extends HospitalState {
  final HospitalModel hospital;
  const MyHospitalLoaded({required this.hospital});
}

class CapacityUpdated extends HospitalState {
  final HospitalModel hospital;
  const CapacityUpdated({required this.hospital});
}

class HospitalError extends HospitalState {
  final String message;
  const HospitalError(this.message);
}