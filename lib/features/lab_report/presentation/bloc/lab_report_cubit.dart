import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/lab_report/data/repository/lab_report_repository.dart';
import 'lab_report_state.dart';

class LabReportCubit extends Cubit<LabReportState> {
  final LabReportRepository _repo;

  LabReportCubit(this._repo) : super(LabReportInitial());

  Future<void> loadReports() async {
    emit(LabReportLoading());
    try {
      emit(LabReportLoaded(await _repo.getMyReports()));
    } catch (e) {
      emit(LabReportError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> loadReport(int id) async {
    emit(LabReportLoading());
    try {
      emit(LabReportDetail(await _repo.getReport(id)));
    } catch (e) {
      emit(LabReportError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> uploadReport({
    required String title,
    required String reportType,
    required String fileUrl,
    required String testDate,
    String notes = '',
  }) async {
    emit(LabReportLoading());
    try {
      final report = await _repo.uploadReport(
        title: title,
        reportType: reportType,
        fileUrl: fileUrl,
        testDate: testDate,
        notes: notes,
      );
      emit(LabReportUploaded(report));
    } catch (e) {
      emit(LabReportError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}