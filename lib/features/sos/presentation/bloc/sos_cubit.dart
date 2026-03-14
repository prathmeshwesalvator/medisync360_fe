import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/sos/data/model/sos_model.dart';
import 'package:medisync_app/features/sos/data/repository/sos_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';

part 'sos_state.dart';

class SosCubit extends Cubit<SosState> {
  final SosRepository _repo;
  final TokenStorage _storage;

  // Polling timer — refreshes SOS detail every 5 seconds while active
  Timer? _pollTimer;

  SosCubit(this._repo, this._storage) : super(const SosInitial());

  Future<String?> _token() => _storage.getAccessToken();

  // ── Patient actions ────────────────────────────────────────────────────────

  Future<void> triggerSos({
    required double latitude,
    required double longitude,
    String address = '',
    String severity = 'high',
    String description = '',
    String bloodGroup = '',
    String allergies = '',
    String medications = '',
    String emergencyContactName = '',
    String emergencyContactPhone = '',
  }) async {
    emit(const SosLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const SosError('Session expired.')); return; }
      final sos = await _repo.createSos(
        token: token,
        latitude: latitude,
        longitude: longitude,
        address: address,
        severity: severity,
        description: description,
        bloodGroup: bloodGroup,
        allergies: allergies,
        medications: medications,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );
      emit(SosTriggered(sos));
      _startPolling(sos.id); // auto-poll while alert is live
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to send SOS. Check your connection.'));
    }
  }

  Future<void> pollSosDetail(int sosId) async {
    try {
      final token = await _token();
      if (token == null) return;
      final sos = await _repo.getSosDetail(sosId, token);
      emit(SosDetailLoaded(sos));
      if (!sos.isLive) _stopPolling(); // stop polling when resolved/cancelled
    } catch (_) { /* silent poll failure */ }
  }

  Future<void> cancelSos(int sosId) async {
    _stopPolling();
    emit(const SosLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const SosError('Session expired.')); return; }
      final sos = await _repo.cancelSos(sosId, token);
      emit(SosCancelled(sos));
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to cancel SOS.'));
    }
  }

  Future<void> loadMyHistory() async {
    emit(const SosLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const SosError('Session expired.')); return; }
      final list = await _repo.getMySosHistory(token);
      emit(SosHistoryLoaded(list));
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to load SOS history.'));
    }
  }

  // ── Hospital actions ────────────────────────────────────────────────────────

  Future<void> loadActiveAlerts() async {
    emit(const SosLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const SosError('Session expired.')); return; }
      final list = await _repo.getActiveSosForHospital(token);
      emit(SosActiveAlertsLoaded(list));
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to load active SOS alerts.'));
    }
  }

  Future<void> respondToSos({
    required int sosId,
    required int etaMinutes,
    String ambulanceNumber = '',
  }) async {
    emit(const SosLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const SosError('Session expired.')); return; }
      final sos = await _repo.respondToSos(
        token: token, sosId: sosId,
        etaMinutes: etaMinutes, ambulanceNumber: ambulanceNumber,
      );
      emit(SosActionSuccess(message: 'SOS accepted. Patient notified.', sos: sos));
      _startPolling(sosId);
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to respond to SOS.'));
    }
  }

  Future<void> markEnroute(int sosId) async {
    try {
      final token = await _token();
      if (token == null) return;
      final sos = await _repo.markEnroute(sosId, token);
      emit(SosActionSuccess(message: 'Ambulance marked en route.', sos: sos));
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to update status.'));
    }
  }

  Future<void> markArrived(int sosId) async {
    try {
      final token = await _token();
      if (token == null) return;
      final sos = await _repo.markArrived(sosId, token);
      emit(SosActionSuccess(message: 'Ambulance arrived.', sos: sos));
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to update status.'));
    }
  }

  Future<void> resolveSos(int sosId) async {
    _stopPolling();
    try {
      final token = await _token();
      if (token == null) return;
      final sos = await _repo.resolveSos(sosId, token);
      emit(SosActionSuccess(message: 'SOS resolved.', sos: sos));
    } on ApiException catch (e) {
      emit(SosError(e.message));
    } catch (_) {
      emit(const SosError('Failed to resolve SOS.'));
    }
  }

  Future<void> pushAmbulanceLocation({
    required int sosId,
    required double lat,
    required double lon,
  }) async {
    try {
      final token = await _token();
      if (token == null) return;
      await _repo.updateAmbulanceLocation(
          token: token, sosId: sosId, lat: lat, lon: lon);
    } catch (_) { /* silent */ }
  }

  // ── Polling ────────────────────────────────────────────────────────────────

  void _startPolling(int sosId) {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      pollSosDetail(sosId);
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}