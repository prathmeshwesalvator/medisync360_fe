import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/lab_report/data/repository/lab_report_repository.dart';
import 'lab_report_state.dart';

class LabReportCubit extends Cubit<LabReportState> {
  final LabReportRepository _repository;

  LabReportCubit(this._repository) : super(LabReportInitial());

  Future<void> uploadReport({
    required File imageFile,
    required String reportType,
    String title = '',
    String notes = '',
  }) async {
    emit(LabReportUploading());
    try {
      final report = await _repository.uploadAndAnalyze(
        imageFile: imageFile,
        reportType: reportType,
        title: title,
        notes: notes,
      );
      emit(LabReportLoaded(report: report));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  Future<void> loadAllReports() async {
    emit(LabReportListLoading());
    try {
      // listReports() is sync, no await needed
      final reports = _repository.listReports();
      emit(LabReportListLoaded(reports: reports));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  Future<void> loadReportDetail(int reportId) async {
    emit(LabReportDetailLoading());
    try {
      final report = _repository.getReport(reportId);
      if (report == null) throw Exception('Report not found');
      emit(LabReportLoaded(report: report));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  Future<void> deleteReport(int reportId) async {
    try {
      // deleteReport() is sync, no await needed
      _repository.deleteReport(reportId);
      await loadAllReports();
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  Future<void> askQuestion(int reportId, String question) async {
    emit(LabReportAsking());
    try {
      // repository returns ReportQA directly, NOT a Map
      final qa = await _repository.askQuestion(reportId, question);
      emit(LabReportAnswered(
        question: qa.question,
        answer: qa.answer,
      ));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }

  Future<void> loadQuestions(int reportId) async {
    try {
      // getQuestions() is sync, no await needed
      final questions = _repository.getQuestions(reportId);
      emit(LabReportQuestionsLoaded(questions: questions));
    } catch (e) {
      emit(LabReportError(message: e.toString()));
    }
  }
}