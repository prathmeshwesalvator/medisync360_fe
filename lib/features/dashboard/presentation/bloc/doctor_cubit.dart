import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/dashboard/data/models/doctor_model.dart';
import 'package:medisync_app/features/dashboard/data/repository/doctor_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';

part 'doctor_state.dart';

class DoctorCubit extends Cubit<DoctorState> {
  final DoctorRepository _repo;
  final TokenStorage _storage;

  DoctorCubit(this._repo, this._storage) : super(const DoctorInitial());

  // Cache the last successfully loaded doctor so DoctorDetailScreen can keep
  // rendering when state transitions to DoctorSlotsLoading / DoctorSlotsLoaded.
  DoctorModel? lastDoctor;

  Future<void> loadDoctors({
    String query = '',
    String specialization = '',
    String city = '',
  }) async {
    emit(const DoctorLoading());
    try {
      final list = await _repo.getDoctors(
        query: query,
        specialization: specialization,
        city: city,
      );
      emit(DoctorListLoaded(list));
    } on ApiException catch (e) {
      emit(DoctorError(e.message));
    } catch (_) {
      emit(const DoctorError('Unable to load doctors.'));
    }
  }

  Future<void> loadDetail(int id) async {
    emit(const DoctorLoading());
    try {
      final doctor = await _repo.getDoctorDetail(id);
      lastDoctor = doctor; // cache for use by detail screen during slot loading
      emit(DoctorDetailLoaded(doctor));
    } on ApiException catch (e) {
      emit(DoctorError(e.message));
    } catch (_) {
      emit(const DoctorError('Unable to load doctor details.'));
    }
  }

  /// Emits DoctorSlotsLoading (not DoctorLoading) so DoctorDetailScreen
  /// stays visible while slots are being fetched.
  Future<void> loadSlots(int doctorId, String date) async {
    emit(const DoctorSlotsLoading());
    try {
      final slots = await _repo.getAvailableSlots(doctorId, date);
      emit(DoctorSlotsLoaded(slots: slots));
    } on ApiException catch (e) {
      emit(DoctorError(e.message));
    } catch (_) {
      emit(const DoctorError('Unable to load slots.'));
    }
  }

  Future<void> submitReview(int doctorId, int rating, String comment) async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        emit(const DoctorError('Session expired.'));
        return;
      }
      await _repo.submitReview(doctorId, rating, comment, token);
      emit(const DoctorReviewSubmitted());
    } on ApiException catch (e) {
      emit(DoctorError(e.message));
    } catch (_) {
      emit(const DoctorError('Could not submit review.'));
    }
  }
}