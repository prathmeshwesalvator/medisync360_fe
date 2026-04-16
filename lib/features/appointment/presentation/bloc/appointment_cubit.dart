import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/appointment/data/repository/appointment_repository.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';

part 'appointment_state.dart';

class AppointmentCubit extends Cubit<AppointmentState> {
  final AppointmentRepository _repo;
  final TokenStorage _storage;

  AppointmentCubit(this._repo, this._storage) : super(const AppointmentInitial());

  Future<String?> _token() => _storage.getAccessToken();

  // ── Patient ────────────────────────────────────────────────────────────────

  Future<void> loadMyAppointments({String? status, String? type}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentListLoaded(
          await _repo.getMyAppointments(token, status: status, type: type)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Unable to load appointments.'));
    }
  }

  Future<void> loadMyStats() async {
    try {
      final token = await _token();
      if (token == null) return;
      emit(AppointmentStatsLoaded(await _repo.getMyStats(token)));
    } catch (_) {}
  }

  Future<void> book({
    required int doctorId,
    required int slotId,
    String reason = '',
    String symptoms = '',
    String appointmentType = 'in_person',
    int? hospitalId,
  }) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentBooked(await _repo.bookAppointment(
        token: token, doctorId: doctorId, slotId: slotId,
        reason: reason, symptoms: symptoms,
        appointmentType: appointmentType, hospitalId: hospitalId,
      )));
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
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentActionSuccess(
          message: 'Appointment cancelled.',
          appointment: await _repo.cancel(id, token, reason: reason)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not cancel appointment.'));
    }
  }

  Future<void> reschedule(int id, int newSlotId) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentActionSuccess(
          message: 'Appointment rescheduled. Awaiting doctor confirmation.',
          appointment: await _repo.reschedule(id, token, newSlotId)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not reschedule appointment.'));
    }
  }

  Future<void> markPaid(int id) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentActionSuccess(
          message: 'Payment recorded.',
          appointment: await _repo.markPaid(id, token)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not record payment.'));
    }
  }

  // ── Doctor ─────────────────────────────────────────────────────────────────

  Future<void> loadDoctorAppointments({String? status, String? date}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentListLoaded(
          await _repo.getDoctorAppointments(token, status: status, date: date)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Unable to load appointments.'));
    }
  }

  Future<void> loadDoctorStats() async {
    try {
      final token = await _token();
      if (token == null) return;
      emit(DoctorStatsLoaded(await _repo.getDoctorStats(token)));
    } catch (_) {}
  }

  Future<void> confirm(int id, {String meetingLink = ''}) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentActionSuccess(
          message: 'Appointment confirmed.',
          appointment: await _repo.confirm(id, token, meetingLink: meetingLink)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not confirm appointment.'));
    }
  }

  Future<void> complete(int id, {
    String notes = '', String diagnosis = '', String prescription = '',
  }) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentActionSuccess(
          message: 'Appointment completed.',
          appointment: await _repo.complete(id, token,
              notes: notes, diagnosis: diagnosis, prescription: prescription)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not complete appointment.'));
    }
  }

  Future<void> markNoShow(int id) async {
    emit(const AppointmentLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const AppointmentError('Session expired.')); return; }
      emit(AppointmentActionSuccess(
          message: 'Marked as no-show.',
          appointment: await _repo.markNoShow(id, token)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not update appointment.'));
    }
  }

  Future<void> updateNotes(int id, {
    String notes = '', String diagnosis = '', String prescription = '',
  }) async {
    try {
      final token = await _token();
      if (token == null) return;
      emit(AppointmentActionSuccess(
          message: 'Notes updated.',
          appointment: await _repo.updateNotes(id, token,
              notes: notes, diagnosis: diagnosis, prescription: prescription)));
    } on ApiException catch (e) {
      emit(AppointmentError(e.message));
    } catch (_) {
      emit(const AppointmentError('Could not save notes.'));
    }
  }
}