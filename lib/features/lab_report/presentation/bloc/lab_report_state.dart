import 'package:equatable/equatable.dart';
import '../../data/model/lab_report_model.dart';

abstract class LabReportState extends Equatable {
  const LabReportState();
  @override
  List<Object?> get props => [];
}

class LabReportInitial extends LabReportState {}
class LabReportUploading extends LabReportState {}
class LabReportListLoading extends LabReportState {}
class LabReportDetailLoading extends LabReportState {}
class LabReportAsking extends LabReportState {}

class LabReportLoaded extends LabReportState {
  final LabReport report;
  const LabReportLoaded({required this.report});
  @override
  List<Object?> get props => [report];
}

class LabReportListLoaded extends LabReportState {
  final List<LabReport> reports;
  const LabReportListLoaded({required this.reports});
  @override
  List<Object?> get props => [reports];
}

class LabReportAnswered extends LabReportState {
  final String question;
  final String answer;
  const LabReportAnswered({required this.question, required this.answer});
  @override
  List<Object?> get props => [question, answer];
}

class LabReportQuestionsLoaded extends LabReportState {
  final List<ReportQA> questions;
  const LabReportQuestionsLoaded({required this.questions});
  @override
  List<Object?> get props => [questions];
}

class LabReportError extends LabReportState {
  final String message;
  const LabReportError({required this.message});
  @override
  List<Object?> get props => [message];
}