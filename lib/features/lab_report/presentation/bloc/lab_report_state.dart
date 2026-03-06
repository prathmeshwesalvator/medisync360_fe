import 'package:medisync_app/features/lab_report/data/model/lab_report_model.dart';


abstract class LabReportState {}

class LabReportInitial  extends LabReportState {}
class LabReportLoading  extends LabReportState {}
class LabReportLoaded   extends LabReportState {
  final List<LabReport> reports;
  LabReportLoaded(this.reports);
}
class LabReportDetail   extends LabReportState {
  final LabReport report;
  LabReportDetail(this.report);
}
class LabReportUploaded extends LabReportState {
  final LabReport report;
  LabReportUploaded(this.report);
}
class LabReportError    extends LabReportState {
  final String message;
  LabReportError(this.message);
}