// ─────────────────────────────────────────────────────────────────────────────
// FILE: features/dashboard/presentation/bloc/hospital_cubit.dart
// ACTION: REPLACE full file (added loadHospitalsForMap method)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/hospital_model.dart';
import '../../data/repository/hospital_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';

part 'hospital_state.dart';

class HospitalCubit extends Cubit<HospitalState> {
  final HospitalRepository _repository;
  final TokenStorage _tokenStorage;

  HospitalCubit(this._repository, this._tokenStorage)
      : super(const HospitalInitial());

  // ── List (search + filter) ────────────────────────────────────────────────
  Future<void> loadHospitals({
    String query = '',
    String city = '',
    String department = '',
    bool hasIcu = false,
  }) async {
    emit(const HospitalLoading());
    try {
      final result = await _repository.getHospitals(
        query: query,
        city: city,
        department: department,
        hasIcu: hasIcu,
      );
      emit(HospitalListLoaded(
        hospitals: result.results,
        count: result.count,
        appliedQuery: query.isNotEmpty ? query : null,
      ));
    } on ApiException catch (e) {
      emit(HospitalError(e.message));
    } catch (_) {
      emit(const HospitalError('Unable to load hospitals. Check your connection.'));
    }
  }

  // ── Map: all hospitals with coordinates ───────────────────────────────────
  Future<void> loadHospitalsForMap() async {
    emit(const HospitalLoading());
    try {
      final result = await _repository.getHospitalsForMap();
      emit(HospitalMapLoaded(hospitals: result.results));
    } on ApiException catch (e) {
      emit(HospitalError(e.message));
    } catch (_) {
      emit(const HospitalError('Unable to load map data.'));
    }
  }

  // ── Nearby ────────────────────────────────────────────────────────────────
  Future<void> loadNearbyHospitals({
    required double lat,
    required double lon,
    double radius = 20,
  }) async {
    emit(const HospitalLoading());
    try {
      final result = await _repository.getNearbyHospitals(
          lat: lat, lon: lon, radius: radius);
      emit(NearbyHospitalsLoaded(hospitals: result.results));
    } on ApiException catch (e) {
      emit(HospitalError(e.message));
    } catch (_) {
      emit(const HospitalError('Unable to find nearby hospitals.'));
    }
  }

  // ── Detail ────────────────────────────────────────────────────────────────
  Future<void> loadHospitalDetail(int id) async {
    emit(const HospitalLoading());
    try {
      final hospital = await _repository.getHospitalDetail(id);
      emit(HospitalDetailLoaded(hospital: hospital));
    } on ApiException catch (e) {
      emit(HospitalError(e.message));
    } catch (_) {
      emit(const HospitalError('Unable to load hospital details.'));
    }
  }

  // ── My Hospital ───────────────────────────────────────────────────────────
  Future<void> loadMyHospital() async {
    emit(const HospitalLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(const HospitalError('Session expired. Please log in again.'));
        return;
      }
      final hospital = await _repository.getMyHospital(token: token);
      emit(MyHospitalLoaded(hospital: hospital));
    } on ApiException catch (e) {
      emit(HospitalError(e.message));
    } catch (_) {
      emit(const HospitalError('Unable to load your hospital profile.'));
    }
  }

  // ── Capacity update ───────────────────────────────────────────────────────
  Future<void> updateCapacity({
    required int availableBeds,
    required int icuAvailable,
    required int emergencyAvailable,
  }) async {
    emit(const HospitalLoading());
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) {
        emit(const HospitalError('Session expired. Please log in again.'));
        return;
      }
      final hospital = await _repository.updateCapacity(
        token: token,
        availableBeds: availableBeds,
        icuAvailable: icuAvailable,
        emergencyAvailable: emergencyAvailable,
      );
      emit(CapacityUpdated(hospital: hospital));
    } on ApiException catch (e) {
      emit(HospitalError(e.message));
    } catch (_) {
      emit(const HospitalError('Unable to update capacity.'));
    }
  }
}