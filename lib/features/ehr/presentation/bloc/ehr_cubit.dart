import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/ehr/data/models/ehr_models.dart';
import 'package:medisync_app/features/ehr/data/repository/ehr_repository.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
part 'ehr_state.dart';

class EHRCubit extends Cubit<EHRState> {
  final EHRRepository _repo;
  final TokenStorage _storage;

  EHRCubit(this._repo, this._storage) : super(const EHRInitial());

  Future<String?> _token() => _storage.getAccessToken();

  // ── Medical history ──────────────────────────────────────────────────────────
  Future<void> loadSummary() async {
    emit(const EHRLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const EHRError('Session expired.')); return; }
      final record = await _repo.getMyRecord(token);
      // Wrap in a minimal EHRSummaryModel — screens that need full summary call
      // loadSummary(); screens that need sub-lists call their own methods.
      emit(EHRSummaryLoaded(EHRSummaryModel(
        medicalRecord: record,
        visitNotes: const [],
        prescriptions: const [],
        labReports: const [],
        imagingRecords: const [],
      )));
    } on ApiException catch (e) {
      emit(EHRError(e.message));
    } catch (_) {
      emit(const EHRError('Unable to load medical history.'));
    }
  }

  // ── Update history ───────────────────────────────────────────────────────────
  Future<void> updateRecord(Map<String, dynamic> data) async {
    emit(const EHRLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const EHRError('Session expired.')); return; }
      emit(EHRRecordUpdated(await _repo.updateMyRecord(token, data)));
    } on ApiException catch (e) {
      emit(EHRError(e.message));
    } catch (_) {
      emit(const EHRError('Update failed.'));
    }
  }

  // ── Prescriptions ────────────────────────────────────────────────────────────
  Future<void> loadPrescriptions() async {
    emit(const EHRLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const EHRError('Session expired.')); return; }
      emit(PrescriptionsLoaded(await _repo.getPrescriptions(token)));
    } on ApiException catch (e) {
      emit(EHRError(e.message));
    } catch (_) {
      emit(const EHRError('Unable to load prescriptions.'));
    }
  }

  // ── Doctor notes ─────────────────────────────────────────────────────────────
  Future<void> loadVisitNotes() async {
    emit(const EHRLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const EHRError('Session expired.')); return; }
      emit(VisitNotesLoaded(await _repo.getVisitNotes(token)));
    } on ApiException catch (e) {
      emit(EHRError(e.message));
    } catch (_) {
      emit(const EHRError('Unable to load notes.'));
    }
  }

  // ── Imaging ──────────────────────────────────────────────────────────────────
  Future<void> loadImaging() async {
    emit(const EHRLoading());
    try {
      final token = await _token();
      if (token == null) { emit(const EHRError('Session expired.')); return; }
      emit(ImagingLoaded(await _repo.getImagingRecords(token)));
    } on ApiException catch (e) {
      emit(EHRError(e.message));
    } catch (_) {
      emit(const EHRError('Unable to load imaging records.'));
    }
  }
}