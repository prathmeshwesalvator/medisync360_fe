import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/ehr/data/models/ehr_models.dart';
import 'package:medisync_app/features/ehr/presentation/bloc/ehr_cubit.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import 'package:medisync_app/global/widgets/app_textfield.dart';


class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({super.key});

  @override
  State<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _bloodCtrl     = TextEditingController();
  final _heightCtrl    = TextEditingController();
  final _weightCtrl    = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _chronicCtrl   = TextEditingController();
  final _medsCtrl      = TextEditingController();
  final _ecNameCtrl    = TextEditingController();
  final _ecPhoneCtrl   = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    context.read<EHRCubit>().loadSummary();
  }

  @override
  void dispose() {
    _bloodCtrl.dispose();    _heightCtrl.dispose();
    _weightCtrl.dispose();   _allergiesCtrl.dispose();
    _chronicCtrl.dispose();  _medsCtrl.dispose();
    _ecNameCtrl.dispose();   _ecPhoneCtrl.dispose();
    super.dispose();
  }

  void _populate(MedicalRecordModel r) {
    _bloodCtrl.text     = r.bloodGroup;
    _heightCtrl.text    = r.heightCm != null ? r.heightCm!.toStringAsFixed(1) : '';
    _weightCtrl.text    = r.weightKg != null ? r.weightKg!.toStringAsFixed(1) : '';
    _allergiesCtrl.text = r.allergies;
    _chronicCtrl.text   = r.chronicConditions;
    _medsCtrl.text      = r.currentMedications;
    _ecNameCtrl.text    = r.emergencyContactName;
    _ecPhoneCtrl.text   = r.emergencyContactPhone;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Medical History',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Cancel' : 'Edit',
                style: TextStyle(
                    color: _editing ? AppColors.error : AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: BlocConsumer<EHRCubit, EHRState>(
        listener: (context, state) {
          if (state is EHRSummaryLoaded) {
            _populate(state.summary.medicalRecord);
          }
          if (state is EHRRecordUpdated) {
            setState(() => _editing = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Medical history saved'),
              backgroundColor: AppColors.accent,
            ));
          }
          if (state is EHRError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message),
                  backgroundColor: AppColors.error));
          }
        },
        builder: (context, state) {
          if (state is EHRLoading) return const LoadingWidget();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BMI badge when not editing and data is available
                if (!_editing && _heightCtrl.text.isNotEmpty &&
                    _weightCtrl.text.isNotEmpty)
                  _BMICard(
                      height: double.tryParse(_heightCtrl.text) ?? 0,
                      weight: double.tryParse(_weightCtrl.text) ?? 0),

                _Section('Basic Info', [
                  _Row('Blood Group', _bloodCtrl, _editing,
                      hint: 'e.g. B+'),
                  _Row('Height (cm)', _heightCtrl, _editing,
                      hint: 'e.g. 170',
                      type: TextInputType.number),
                  _Row('Weight (kg)', _weightCtrl, _editing,
                      hint: 'e.g. 65',
                      type: TextInputType.number),
                ]),
                _Section('Health Conditions', [
                  _Row('Allergies', _allergiesCtrl, _editing,
                      maxLines: 3),
                  _Row('Chronic Conditions', _chronicCtrl, _editing,
                      maxLines: 3),
                  _Row('Current Medications', _medsCtrl, _editing,
                      maxLines: 3),
                ]),
                _Section('Emergency Contact', [
                  _Row('Name', _ecNameCtrl, _editing),
                  _Row('Phone', _ecPhoneCtrl, _editing,
                      type: TextInputType.phone),
                ]),
                if (_editing) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.read<EHRCubit>().updateRecord({
                        'blood_group':              _bloodCtrl.text.trim(),
                        'height_cm':                _heightCtrl.text.trim(),
                        'weight_kg':                _weightCtrl.text.trim(),
                        'allergies':                _allergiesCtrl.text.trim(),
                        'chronic_conditions':       _chronicCtrl.text.trim(),
                        'current_medications':      _medsCtrl.text.trim(),
                        'emergency_contact_name':   _ecNameCtrl.text.trim(),
                        'emergency_contact_phone':  _ecPhoneCtrl.text.trim(),
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Save Changes',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── BMI Card ──────────────────────────────────────────────────────────────────
class _BMICard extends StatelessWidget {
  final double height; // cm
  final double weight; // kg
  const _BMICard({required this.height, required this.weight});

  double get _bmi =>
      height > 0 ? weight / ((height / 100) * (height / 100)) : 0;

  String get _label {
    if (_bmi == 0)     return '';
    if (_bmi < 18.5)   return 'Underweight';
    if (_bmi < 25)     return 'Normal';
    if (_bmi < 30)     return 'Overweight';
    return 'Obese';
  }

  Color get _color {
    if (_bmi == 0)     return AppColors.textHint;
    if (_bmi < 18.5)   return const Color(0xFF0891B2);
    if (_bmi < 25)     return AppColors.accent;
    if (_bmi < 30)     return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_bmi == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: AppRadius.lg,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: _color.withOpacity(0.15), shape: BoxShape.circle),
          child: Center(
            child: Text(_bmi.toStringAsFixed(1),
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _color)),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('BMI', style: AppTextStyles.caption),
          Text(_label,
              style: AppTextStyles.titleLarge.copyWith(color: _color)),
          Text('${height.toStringAsFixed(0)} cm  ·  '
              '${weight.toStringAsFixed(1)} kg',
              style: AppTextStyles.caption),
        ]),
      ]),
    );
  }
}

// ── Section ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md,
                bottom: AppSpacing.sm),
            child: Text(title,
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lg,
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: children
                  .expand((w) => [w, const Divider(height: 1)])
                  .toList()
                ..removeLast(), // remove trailing divider
            ),
          ),
        ],
      );
}

// ── Row: view or edit ─────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final bool editing;
  final int maxLines;
  final String? hint;
  final TextInputType type;

  const _Row(this.label, this.ctrl, this.editing, {
    this.maxLines = 1,
    this.hint,
    this.type = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    if (editing) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: AppTextField(
          controller: ctrl,
          label: label,
          hint: hint ?? label,
          maxLines: maxLines,
          keyboardType: type,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(
              ctrl.text.isEmpty ? '—' : ctrl.text,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}