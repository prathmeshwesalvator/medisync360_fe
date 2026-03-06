class MedicalRecordModel {
  final int id;
  final String bloodGroup;
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String allergies;
  final String chronicConditions;
  final String currentMedications;
  final String emergencyContactName;
  final String emergencyContactPhone;

  const MedicalRecordModel({
    required this.id,
    this.bloodGroup = '',
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.allergies = '',
    this.chronicConditions = '',
    this.currentMedications = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
  });

  factory MedicalRecordModel.fromJson(Map<String, dynamic> j) => MedicalRecordModel(
        id: j['id'] ?? 0,
        bloodGroup: j['blood_group'] ?? '',
        heightCm: j['height_cm'] != null ? double.tryParse('${j['height_cm']}') : null,
        weightKg: j['weight_kg'] != null ? double.tryParse('${j['weight_kg']}') : null,
        bmi: j['bmi'] != null ? double.tryParse('${j['bmi']}') : null,
        allergies: j['allergies'] ?? '',
        chronicConditions: j['chronic_conditions'] ?? '',
        currentMedications: j['current_medications'] ?? '',
        emergencyContactName: j['emergency_contact_name'] ?? '',
        emergencyContactPhone: j['emergency_contact_phone'] ?? '',
      );
}

class VisitNoteModel {
  final int id;
  final String doctorName;
  final String doctorSpecialty;
  final String visitDate;
  final String chiefComplaint;
  final String diagnosis;
  final String treatmentPlan;
  final String? followUpDate;
  final String examinationNotes;

  const VisitNoteModel({
    required this.id,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.visitDate,
    required this.chiefComplaint,
    required this.diagnosis,
    this.treatmentPlan = '',
    this.followUpDate,
    this.examinationNotes = '',
  });

  factory VisitNoteModel.fromJson(Map<String, dynamic> j) => VisitNoteModel(
        id: j['id'] ?? 0,
        doctorName: j['doctor_name'] ?? '',
        doctorSpecialty: j['doctor_specialty'] ?? '',
        visitDate: j['visit_date'] ?? '',
        chiefComplaint: j['chief_complaint'] ?? '',
        diagnosis: j['diagnosis'] ?? '',
        treatmentPlan: j['treatment_plan'] ?? '',
        followUpDate: j['follow_up_date'],
        examinationNotes: j['examination_notes'] ?? '',
      );
}

class PrescriptionItemModel {
  final int id;
  final String medicineName;
  final String dosage;
  final String frequency;
  final String duration;
  final String instructions;

  const PrescriptionItemModel({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions = '',
  });

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> j) => PrescriptionItemModel(
        id: j['id'] ?? 0,
        medicineName: j['medicine_name'] ?? '',
        dosage: j['dosage'] ?? '',
        frequency: j['frequency'] ?? '',
        duration: j['duration'] ?? '',
        instructions: j['instructions'] ?? '',
      );
}

class PrescriptionModel {
  final int id;
  final String doctorName;
  final String doctorSpecialty;
  final String issuedDate;
  final String? validUntil;
  final String diagnosis;
  final String notes;
  final String status;
  final List<PrescriptionItemModel> items;

  const PrescriptionModel({
    required this.id,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.issuedDate,
    this.validUntil,
    required this.diagnosis,
    this.notes = '',
    required this.status,
    this.items = const [],
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> j) => PrescriptionModel(
        id: j['id'] ?? 0,
        doctorName: j['doctor_name'] ?? '',
        doctorSpecialty: j['doctor_specialty'] ?? '',
        issuedDate: j['issued_date'] ?? '',
        validUntil: j['valid_until'],
        diagnosis: j['diagnosis'] ?? '',
        notes: j['notes'] ?? '',
        status: j['status'] ?? 'active',
        items: (j['items'] as List? ?? []).map((i) => PrescriptionItemModel.fromJson(i)).toList(),
      );
}

class LabReportItemModel {
  final int id;
  final String parameter;
  final String value;
  final String unit;
  final String normalRange;
  final bool isAbnormal;

  const LabReportItemModel({
    required this.id,
    required this.parameter,
    required this.value,
    this.unit = '',
    this.normalRange = '',
    this.isAbnormal = false,
  });

  factory LabReportItemModel.fromJson(Map<String, dynamic> j) => LabReportItemModel(
        id: j['id'] ?? 0,
        parameter: j['parameter'] ?? '',
        value: j['value'] ?? '',
        unit: j['unit'] ?? '',
        normalRange: j['normal_range'] ?? '',
        isAbnormal: j['is_abnormal'] ?? false,
      );
}

class LabReportModel {
  final int id;
  final String testName;
  final String testDate;
  final String labName;
  final bool isAbnormal;
  final String status;
  final String resultSummary;
  final String? orderedByName;
  final List<LabReportItemModel> items;

  const LabReportModel({
    required this.id,
    required this.testName,
    required this.testDate,
    this.labName = '',
    this.isAbnormal = false,
    required this.status,
    this.resultSummary = '',
    this.orderedByName,
    this.items = const [],
  });

  factory LabReportModel.fromJson(Map<String, dynamic> j) => LabReportModel(
        id: j['id'] ?? 0,
        testName: j['test_name'] ?? '',
        testDate: j['test_date'] ?? '',
        labName: j['lab_name'] ?? '',
        isAbnormal: j['is_abnormal'] ?? false,
        status: j['status'] ?? 'pending',
        resultSummary: j['result_summary'] ?? '',
        orderedByName: j['ordered_by_name'],
        items: (j['items'] as List? ?? []).map((i) => LabReportItemModel.fromJson(i)).toList(),
      );
}

class ImagingRecordModel {
  final int id;
  final String imagingType;
  final String imagingTypeDisplay;
  final String bodyPart;
  final String scanDate;
  final String facility;
  final String findings;
  final String impression;
  final String? orderedByName;

  const ImagingRecordModel({
    required this.id,
    required this.imagingType,
    required this.imagingTypeDisplay,
    required this.bodyPart,
    required this.scanDate,
    this.facility = '',
    this.findings = '',
    this.impression = '',
    this.orderedByName,
  });

  factory ImagingRecordModel.fromJson(Map<String, dynamic> j) => ImagingRecordModel(
        id: j['id'] ?? 0,
        imagingType: j['imaging_type'] ?? '',
        imagingTypeDisplay: j['imaging_type_display'] ?? j['imaging_type'] ?? '',
        bodyPart: j['body_part'] ?? '',
        scanDate: j['scan_date'] ?? '',
        facility: j['facility'] ?? '',
        findings: j['findings'] ?? '',
        impression: j['impression'] ?? '',
        orderedByName: j['ordered_by_name'],
      );
}

class EHRSummaryModel {
  final MedicalRecordModel medicalRecord;
  final List<VisitNoteModel> visitNotes;
  final List<PrescriptionModel> prescriptions;
  final List<LabReportModel> labReports;
  final List<ImagingRecordModel> imagingRecords;

  const EHRSummaryModel({
    required this.medicalRecord,
    required this.visitNotes,
    required this.prescriptions,
    required this.labReports,
    required this.imagingRecords,
  });

  factory EHRSummaryModel.fromJson(Map<String, dynamic> j) => EHRSummaryModel(
        medicalRecord: MedicalRecordModel.fromJson(j['medical_record'] ?? {}),
        visitNotes: (j['visit_notes'] as List? ?? []).map((v) => VisitNoteModel.fromJson(v)).toList(),
        prescriptions: (j['prescriptions'] as List? ?? []).map((p) => PrescriptionModel.fromJson(p)).toList(),
        labReports: (j['lab_reports'] as List? ?? []).map((l) => LabReportModel.fromJson(l)).toList(),
        imagingRecords: (j['imaging_records'] as List? ?? []).map((i) => ImagingRecordModel.fromJson(i)).toList(),
      );
}