part of 'ehr_cubit.dart';

abstract class EHRState {
  const EHRState();
}

class EHRInitial extends EHRState {
  const EHRInitial();
}

class EHRLoading extends EHRState {
  const EHRLoading();
}

class EHRSummaryLoaded extends EHRState {
  final EHRSummaryModel summary;
  const EHRSummaryLoaded(this.summary);
}

class EHRRecordUpdated extends EHRState {
  final MedicalRecordModel record;
  const EHRRecordUpdated(this.record);
}

class PrescriptionsLoaded extends EHRState {
  final List<PrescriptionModel> prescriptions;
  const PrescriptionsLoaded(this.prescriptions);
}

class VisitNotesLoaded extends EHRState {
  final List<VisitNoteModel> notes;
  const VisitNotesLoaded(this.notes);
}

class ImagingLoaded extends EHRState {
  final List<ImagingRecordModel> records;
  const ImagingLoaded(this.records);
}

class EHRError extends EHRState {
  final String message;
  const EHRError(this.message);
}
