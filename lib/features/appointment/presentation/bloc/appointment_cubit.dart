import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/appointment/data/repository/appointment_repository.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
part 'appointment_state.dart';

class AppointmentCubit extends Cubit<AppointmentState> {
  final AppointmentRepository _repo;
  final TokenStorage _storage;

  AppointmentCubit(this._repo, this._storage)
      : super(const AppointmentInitial());

  Future<String?> _token() => _storage.getAccessToken();

  Future<void> loadMyAppointments({String? status}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final list = await _repo.getMyAppointments(token, status: status);
      emit(AppointmentListLoaded(list));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Unable to load appointments.'));
    }
  }

  Future<void> loadDoctorAppointments({String? status, String? date}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final list =
          await _repo.getDoctorAppointments(token, status: status, date: date);
      emit(AppointmentListLoaded(list));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Unable to load appointments.'));
    }
  }

  Future<void> book({
    required int doctorId,
    required String date,
    required String slotTime,
    required String type,
    String reason = '',
    String symptoms = '',
    int? hospitalId,
  }) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final appt = await _repo.bookAppointment(
        token: token,
        doctorId: doctorId,
        date: date,
        slotTime: slotTime,
        type: type,
        reason: reason,
        symptoms: symptoms,
        hospitalId: hospitalId,
      );
      emit(AppointmentBooked(appt));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Booking failed. Please try again.'));
    }
  }

  Future<void> cancel(int id, {String reason = ''}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final appt = await _repo.cancel(id, token, reason: reason);
      emit(AppointmentActionSuccess(
          message: 'Appointment cancelled.', appointment: appt));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not cancel appointment.'));
    }
  }

  Future<void> reschedule(int id, String newDate, String newSlotTime,
      {String reason = ''}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final appt = await _repo.reschedule(id, token, newDate, newSlotTime,
          reason: reason);
      emit(AppointmentActionSuccess(
          message: 'Appointment rescheduled.', appointment: appt));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not reschedule appointment.'));
    }
  }

  Future<void> confirm(int id) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final appt = await _repo.confirm(id, token);
      emit(AppointmentActionSuccess(
          message: 'Appointment confirmed.', appointment: appt));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not confirm appointment.'));
    }
  }

  Future<void> complete(int id, {String notes = ''}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) {
        emit(const AppointmentError('Session expired.'));
        return;
      }
      final appt = await _repo.complete(id, token, notes: notes);
      emit(AppointmentActionSuccess(
          message: 'Appointment completed.', appointment: appt));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not complete appointment.'));
    }
  }
}
