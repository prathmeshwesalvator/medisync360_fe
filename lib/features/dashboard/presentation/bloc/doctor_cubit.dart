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

  Future<void> loadDoctors(
      {String query = '', String specialization = '', String city = ''}) async {
    emit(const DoctorLoading());
    try {
      final list = await _repo.getDoctors(
          query: query, specialization: specialization, city: city);
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
      emit(DoctorDetailLoaded(await _repo.getDoctorDetail(id)));
    } on ApiException catch (e) {
      emit(DoctorError(e.message));
    } catch (_) {
      emit(const DoctorError('Unable to load doctor details.'));
    }
  }

  Future<void> loadSlots(int doctorId, String date) async {
    emit(const DoctorLoading());
    try {
      final doctor = await _repo.getDoctorDetail(doctorId);
      final slots = await _repo.getAvailableSlots(doctorId, date);
      emit(DoctorSlotsLoaded(doctor: doctor, slots: slots));
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
