import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/lab_report/data/repository/lab_report_repository.dart';
import 'lab_report_state.dart';

class LabReportCubit extends Cubit<LabReportState> {
  final LabReportRepository _repository;

  LabReportCubit(this._repository) : super(LabReportInitial());

  // ── Upload + auto-poll ───────────────────────────────────────────────────────

  Future<void> uploadReport({
    required File imageFile,
    required String reportType,
    String title = '',
    String notes = '',
  }) async {
    emit(LabReportUploading());
    try {
      final result = await _repository.uploadReport(
        imageFile: imageFile,
        reportType: reportType,
        title: title,
        notes: notes,
      );
      final int reportId = result['report_id'];
      emit(LabReportAnalyzing(reportId: reportId));
      _pollStatus(reportId);
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  void _pollStatus(int reportId) {
    Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final statusStr = await _repository.getStatus(reportId);
        if (statusStr == 'completed') {
          timer.cancel();
          await _loadReport(reportId);
        } else if (statusStr == 'failed') {
          timer.cancel();
          emit(const LabReportError(
              message: 'Analysis failed. Please upload a clearer image.'));
        }
        // 'pending' | 'processing' → keep polling
      } catch (_) {
        timer.cancel();
        emit(const LabReportError(message: 'Error checking report status.'));
      }
    });
  }

  Future<void> _loadReport(int reportId) async {
    try {
      final report = await _repository.getReport(reportId);
      emit(LabReportLoaded(report: report));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  // ── List ─────────────────────────────────────────────────────────────────────

  Future<void> loadAllReports() async {
    emit(LabReportListLoading());
    try {
      final reports = await _repository.listReports();
      emit(LabReportListLoaded(reports: reports));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  // ── Detail ───────────────────────────────────────────────────────────────────

  Future<void> loadReportDetail(int reportId) async {
    emit(LabReportDetailLoading());
    try {
      final report = await _repository.getReport(reportId);
      emit(LabReportLoaded(report: report));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteReport(int reportId) async {
    try {
      await _repository.deleteReport(reportId);
      await loadAllReports();
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  // ── Ask AI question ──────────────────────────────────────────────────────────

  Future<void> askQuestion(int reportId, String question) async {
    emit(LabReportAsking());
    try {
      final result = await _repository.askQuestion(reportId, question);
      emit(LabReportAnswered(
        question: result['question'] as String,
        answer: result['answer'] as String,
      ));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  // ── Q&A history ──────────────────────────────────────────────────────────────

  Future<void> loadQuestions(int reportId) async {
    try {
      final questions = await _repository.getQuestions(reportId);
      emit(LabReportQuestionsLoaded(questions: questions));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }
}
