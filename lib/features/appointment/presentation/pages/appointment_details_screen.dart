import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/dashboard/data/models/doctor_model.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class AppointmentDetailScreen extends StatefulWidget {
  final AppointmentModel appointment;
  const AppointmentDetailScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  late AppointmentModel _appt;

  @override
  void initState() {
    super.initState();
    _appt = widget.appointment;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isDoctor {
    final s = context.read<AuthCubit>().state;
    return s is AuthSuccess && s.user.role == UserRole.doctor;
  }

  void _toast(String msg, {Color color = AppColors.accent}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(
            color == AppColors.error
                ? Icons.error_outline_rounded
                : Icons.check_circle_rounded,
            color: Colors.white, size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        margin: const EdgeInsets.all(AppSpacing.md),
      ));
  }

  // ── Bottom sheets ─────────────────────────────────────────────────────────

  void _showCancelSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: const BoxDecoration(
                  color: AppColors.divider, borderRadius: AppRadius.full)),
          const SizedBox(height: 16),
          const Text('Cancel Appointment', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          const Text('This action cannot be undone.',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)'),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep it'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AppointmentCubit>().cancel(
                    _appt.id, reason: ctrl.text);
              },
              child: const Text('Cancel Appointment',
                  style: TextStyle(color: Colors.white)),
            )),
          ]),
        ]),
      ),
    );
  }

  void _showRescheduleSheet() {
    DateTime picked = DateTime.now().add(const Duration(days: 1));
    DoctorSlotModel? selectedSlot;
    AvailableSlotsModel? slotsData;
    bool loadingSlots = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => BlocProvider.value(
        value: context.read<DoctorCubit>(),
        child: StatefulBuilder(builder: (ctx, setModal) {
          void loadSlots(DateTime date) {
            final dcState = context.read<DoctorCubit>().state;
            int? doctorId;
            if (dcState is DoctorDetailLoaded) doctorId = dcState.doctor.id;
            if (dcState is DoctorSlotsLoaded) doctorId = dcState.doctor.id;
            if (doctorId == null) return;
            setModal(() { loadingSlots = true; selectedSlot = null; slotsData = null; });
            final dateStr =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            context.read<DoctorCubit>().loadSlots(doctorId, dateStr);
          }

          return BlocListener<DoctorCubit, DoctorState>(
            listener: (_, state) {
              if (state is DoctorSlotsLoaded) {
                setModal(() { slotsData = state.slots; loadingSlots = false; });
              }
              if (state is DoctorSlotsLoading) setModal(() => loadingSlots = true);
              if (state is DoctorError) setModal(() => loadingSlots = false);
            },
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 36, height: 4,
                    decoration: const BoxDecoration(
                        color: AppColors.divider, borderRadius: AppRadius.full)),
                const SizedBox(height: 16),
                const Text('Reschedule Appointment',
                    style: AppTextStyles.headlineMedium),
                if (_appt.rescheduleCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_appt.rescheduleCount}/3 reschedules used',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.warning),
                    ),
                  ),
                const SizedBox(height: 16),
                // Date row
                ListTile(
                  tileColor: AppColors.inputFill,
                  shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
                  leading: const Icon(Icons.calendar_today_rounded,
                      color: AppColors.primary),
                  title: Text(
                    '${picked.day}/${picked.month}/${picked.year}',
                    style: AppTextStyles.bodyLarge,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: picked,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (d != null) { setModal(() => picked = d); loadSlots(d); }
                  },
                ),
                const SizedBox(height: 12),
                // Slots
                if (loadingSlots)
                  const Padding(padding: EdgeInsets.all(12), child: LoadingWidget())
                else if (slotsData == null)
                  const Text('Tap the date above to see available slots',
                      style: AppTextStyles.bodyMedium)
                else if (slotsData!.slots.isEmpty)
                  const Text('No slots available on this day',
                      style: AppTextStyles.bodyMedium)
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: slotsData!.slots.map((s) {
                      final avail = s.isAvailable;
                      final sel = selectedSlot?.id == s.id;
                      return GestureDetector(
                        onTap: avail ? () => setModal(() => selectedSlot = s) : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: !avail ? AppColors.inputFill
                                : sel ? AppColors.primary : AppColors.surface,
                            border: Border.all(
                                color: sel ? AppColors.primary : AppColors.divider),
                            borderRadius: AppRadius.md,
                          ),
                          child: Text(s.startTime,
                              style: AppTextStyles.labelLarge.copyWith(
                                color: !avail ? AppColors.textHint
                                    : sel ? Colors.white : AppColors.textPrimary,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: selectedSlot == null ? null : () {
                    Navigator.pop(ctx);
                    context.read<AppointmentCubit>()
                        .reschedule(_appt.id, selectedSlot!.id);
                  },
                  child: const Text('Confirm Reschedule'),
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ── Doctor bottom sheets ──────────────────────────────────────────────────

  void _showConfirmSheet() {
    final linkCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: const BoxDecoration(
                  color: AppColors.divider, borderRadius: AppRadius.full)),
          const SizedBox(height: 16),
          const Text('Confirm Appointment', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('Patient: ${_appt.patientName}',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          if (_appt.isVirtual) ...[
            TextField(
              controller: linkCtrl,
              decoration: InputDecoration(
                hintText: 'Meeting link (optional for '
                    '${AppointmentType.label(_appt.appointmentType)})',
                prefixIcon: const Icon(Icons.link_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.doctorRole,
                minimumSize: const Size(double.infinity, 48)),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AppointmentCubit>()
                  .confirm(_appt.id, meetingLink: linkCtrl.text.trim());
            },
            icon: const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            label: const Text('Confirm',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  void _showCompleteSheet() {
    final notesCtrl  = TextEditingController(text: _appt.notes);
    final diagCtrl   = TextEditingController(text: _appt.diagnosis);
    final prescCtrl  = TextEditingController(text: _appt.prescription);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: const BoxDecoration(
                    color: AppColors.divider, borderRadius: AppRadius.full)),
            const SizedBox(height: 16),
            const Text('Complete Appointment', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            _SheetField(ctrl: notesCtrl, label: 'Visit Notes',
                hint: 'Notes about the visit'),
            const SizedBox(height: 12),
            _SheetField(ctrl: diagCtrl, label: 'Diagnosis',
                hint: 'Primary diagnosis'),
            const SizedBox(height: 12),
            _SheetField(ctrl: prescCtrl, label: 'Prescription Summary',
                hint: 'Medicines / dosage summary', maxLines: 3),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AppointmentCubit>().complete(
                  _appt.id,
                  notes: notesCtrl.text.trim(),
                  diagnosis: diagCtrl.text.trim(),
                  prescription: prescCtrl.text.trim(),
                );
              },
              icon: const Icon(Icons.task_alt_rounded,
                  color: Colors.white, size: 18),
              label: const Text('Mark as Completed',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  void _showNotesSheet() {
    final notesCtrl = TextEditingController(text: _appt.notes);
    final diagCtrl  = TextEditingController(text: _appt.diagnosis);
    final prescCtrl = TextEditingController(text: _appt.prescription);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 36, height: 4,
                decoration: const BoxDecoration(
                    color: AppColors.divider, borderRadius: AppRadius.full)),
            const SizedBox(height: 16),
            const Text('Update Visit Notes', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            _SheetField(ctrl: notesCtrl, label: 'Visit Notes',
                hint: 'Notes about the visit'),
            const SizedBox(height: 12),
            _SheetField(ctrl: diagCtrl, label: 'Diagnosis',
                hint: 'Primary diagnosis'),
            const SizedBox(height: 12),
            _SheetField(ctrl: prescCtrl, label: 'Prescription Summary',
                hint: 'Medicines / dosage summary', maxLines: 3),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48)),
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AppointmentCubit>().updateNotes(
                  _appt.id,
                  notes: notesCtrl.text.trim(),
                  diagnosis: diagCtrl.text.trim(),
                  prescription: prescCtrl.text.trim(),
                );
              },
              child: const Text('Save Notes'),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentCubit, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentActionSuccess) {
          _toast(state.message);
          setState(() => _appt = state.appointment);
        }
        if (state is AppointmentError) {
          _toast(state.message, color: AppColors.error);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Appointment Details',
              style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Status banner ───────────────────────────────────────────────
            _StatusBanner(appt: _appt),
            const SizedBox(height: AppSpacing.md),

            // ── Doctor card ─────────────────────────────────────────────────
            _InfoCard(title: 'Doctor', children: [
              Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.doctorRole.withOpacity(0.12),
                  child: Text(
                    _appt.doctorName.isNotEmpty
                        ? _appt.doctorName[0].toUpperCase() : 'D',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.doctorRole),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Dr. ${_appt.doctorName}',
                      style: AppTextStyles.titleLarge),
                  Text(_appt.doctorSpecialty,
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ])),
              ]),
            ]),
            const SizedBox(height: AppSpacing.sm),

            // ── Schedule ────────────────────────────────────────────────────
            _InfoCard(title: 'Schedule', children: [
              _Row(icon: Icons.calendar_today_rounded,
                  label: 'Date', value: _appt.appointmentDate),
              const Divider(height: 16),
              _Row(icon: Icons.access_time_rounded,
                  label: 'Time', value: _appt.slotTime),
              const Divider(height: 16),
              _Row(
                icon: _appt.appointmentType == AppointmentType.video
                    ? Icons.videocam_rounded
                    : _appt.appointmentType == AppointmentType.phone
                        ? Icons.phone_rounded
                        : Icons.person_pin_rounded,
                label: 'Type',
                value: AppointmentType.label(_appt.appointmentType),
              ),
              if (_appt.hospitalName != null) ...[
                const Divider(height: 16),
                _Row(icon: Icons.local_hospital_rounded,
                    label: 'Hospital', value: _appt.hospitalName!),
              ],
            ]),
            const SizedBox(height: AppSpacing.sm),

            // ── Meeting link (virtual + confirmed) ──────────────────────────
            if (_appt.isVirtual && _appt.hasMeetingLink) ...[
              _InfoCard(title: 'Meeting Link', children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _appt.meetingLink));
                    _toast('Link copied to clipboard');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Row(children: [
                      const Icon(Icons.link_rounded,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_appt.meetingLink,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                      const Icon(Icons.copy_rounded,
                          color: AppColors.primary, size: 14),
                    ]),
                  ),
                ),
              ]),
              const SizedBox(height: AppSpacing.sm),
            ],

            // ── Visit info ──────────────────────────────────────────────────
            if (_appt.reason.isNotEmpty || _appt.symptoms.isNotEmpty) ...[
              _InfoCard(title: 'Visit Info', children: [
                if (_appt.reason.isNotEmpty) ...[
                  _TextBlock(label: 'Reason', text: _appt.reason),
                  if (_appt.symptoms.isNotEmpty) const Divider(height: 16),
                ],
                if (_appt.symptoms.isNotEmpty)
                  _TextBlock(label: 'Symptoms', text: _appt.symptoms),
              ]),
              const SizedBox(height: AppSpacing.sm),
            ],

            // ── Clinical notes (visible if present) ─────────────────────────
            if (_appt.hasNotes) ...[
              _InfoCard(title: "Doctor's Notes", children: [
                if (_appt.diagnosis.isNotEmpty) ...[
                  _TextBlock(label: 'Diagnosis', text: _appt.diagnosis),
                  if (_appt.notes.isNotEmpty || _appt.prescription.isNotEmpty)
                    const Divider(height: 16),
                ],
                if (_appt.notes.isNotEmpty) ...[
                  _TextBlock(label: 'Visit Notes', text: _appt.notes),
                  if (_appt.prescription.isNotEmpty) const Divider(height: 16),
                ],
                if (_appt.prescription.isNotEmpty)
                  _TextBlock(label: 'Prescription', text: _appt.prescription),
              ]),
              const SizedBox(height: AppSpacing.sm),
            ],

            // ── Cancellation reason ─────────────────────────────────────────
            if (_appt.cancelReason.isNotEmpty) ...[
              _InfoCard(title: 'Cancellation Reason', children: [
                Text(_appt.cancelReason,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error, height: 1.5)),
              ]),
              const SizedBox(height: AppSpacing.sm),
            ],

            // ── Payment ─────────────────────────────────────────────────────
            _InfoCard(title: 'Payment', children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Consultation Fee', style: AppTextStyles.bodyMedium),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${_appt.consultationFee.toStringAsFixed(0)}',
                      style: AppTextStyles.titleLarge
                          .copyWith(color: AppColors.primary)),
                  Text(_appt.paymentStatus.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: _appt.paymentStatus == PaymentStatus.paid
                            ? AppColors.accent : AppColors.textHint,
                        fontWeight: FontWeight.w700,
                      )),
                ]),
              ]),
            ]),
            const SizedBox(height: AppSpacing.sm),

            // ── Status timeline ─────────────────────────────────────────────
            if (_appt.statusLogs.isNotEmpty) ...[
              _InfoCard(title: 'Timeline', children: [
                ..._appt.statusLogs.map((l) => _LogTile(log: l)),
              ]),
              const SizedBox(height: AppSpacing.sm),
            ],

            const SizedBox(height: AppSpacing.md),

            // ── Action buttons ──────────────────────────────────────────────
            // PATIENT actions
            if (!_isDoctor) ...[
              if (_appt.canPay) ...[
                ElevatedButton.icon(
                  onPressed: () =>
                      context.read<AppointmentCubit>().markPaid(_appt.id),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(double.infinity, 48)),
                  icon: const Icon(Icons.payment_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Mark as Paid',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
              ],
              if (_appt.isCancellable || _appt.isReschedulable)
                Row(children: [
                  if (_appt.isCancellable)
                    Expanded(child: OutlinedButton.icon(
                      onPressed: _showCancelSheet,
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(0, 44)),
                    )),
                  if (_appt.isCancellable && _appt.isReschedulable)
                    const SizedBox(width: 10),
                  if (_appt.isReschedulable)
                    Expanded(child: ElevatedButton.icon(
                      onPressed: _showRescheduleSheet,
                      icon: const Icon(Icons.calendar_month_rounded,
                          size: 16, color: Colors.white),
                      label: const Text('Reschedule',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 44)),
                    )),
                ]),
            ],

            // DOCTOR actions
            if (_isDoctor) ...[
              if (_appt.canConfirm) ...[
                ElevatedButton.icon(
                  onPressed: _showConfirmSheet,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.doctorRole,
                      minimumSize: const Size(double.infinity, 48)),
                  icon: const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Confirm Appointment',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
              ],
              if (_appt.canComplete) ...[
                ElevatedButton.icon(
                  onPressed: _showCompleteSheet,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(double.infinity, 48)),
                  icon: const Icon(Icons.task_alt_rounded,
                      color: Colors.white, size: 18),
                  label: const Text('Mark as Completed',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 10),
              ],
              if (_appt.canMarkNoShow) ...[
                OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Mark as No-Show?'),
                      content: const Text(
                          'Patient did not show up. The slot will be freed.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning),
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<AppointmentCubit>()
                                .markNoShow(_appt.id);
                          },
                          child: const Text('Confirm No-Show',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.person_off_rounded, size: 16),
                  label: const Text('Mark No-Show'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      minimumSize: const Size(double.infinity, 44)),
                ),
                const SizedBox(height: 10),
              ],
              if (_appt.status == AppointmentStatus.completed)
                OutlinedButton.icon(
                  onPressed: _showNotesSheet,
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: const Text('Update Notes'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44)),
                ),
            ],

            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final AppointmentModel appt;
  const _StatusBanner({required this.appt});

  Color get _color {
    switch (appt.status) {
      case AppointmentStatus.confirmed:   return AppColors.accent;
      case AppointmentStatus.completed:   return AppColors.primary;
      case AppointmentStatus.cancelled:   return AppColors.error;
      case AppointmentStatus.rescheduled: return AppColors.warning;
      case AppointmentStatus.noShow:      return AppColors.warning;
      default:                            return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (appt.status) {
      case AppointmentStatus.confirmed:   return Icons.check_circle_rounded;
      case AppointmentStatus.completed:   return Icons.task_alt_rounded;
      case AppointmentStatus.cancelled:   return Icons.cancel_rounded;
      case AppointmentStatus.rescheduled: return Icons.update_rounded;
      case AppointmentStatus.noShow:      return Icons.person_off_rounded;
      default:                            return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: _color.withOpacity(0.08),
            borderRadius: AppRadius.lg,
            border: Border.all(color: _color.withOpacity(0.2))),
        child: Row(children: [
          Icon(_icon, color: _color, size: 24),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Status',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            Text(
              appt.status.replaceAll('_', ' ').toUpperCase(),
              style: AppTextStyles.labelLarge.copyWith(color: _color),
            ),
          ]),
          const Spacer(),
          if (appt.confirmedAt != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Confirmed',
                  style: AppTextStyles.caption),
              Text(appt.confirmedAt!.length > 10
                  ? appt.confirmedAt!.substring(0, 10)
                  : appt.confirmedAt!,
                  style: AppTextStyles.caption
                      .copyWith(fontWeight: FontWeight.w600)),
            ]),
        ]),
      );
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            boxShadow: AppShadows.card),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ]),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Row({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: AppTextStyles.labelLarge),
      ]);
}

class _TextBlock extends StatelessWidget {
  final String label;
  final String text;
  const _TextBlock({required this.label, required this.text});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(text,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      );
}

class _LogTile extends StatelessWidget {
  final StatusLogModel log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              log.fromStatus.isNotEmpty
                  ? '${log.fromStatus.replaceAll('_', ' ')} → ${log.toStatus.replaceAll('_', ' ')}'
                  : log.toStatus.replaceAll('_', ' '),
              style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
            ),
            if (log.reason.isNotEmpty)
              Text(log.reason, style: AppTextStyles.caption),
            if (log.changedByName != null)
              Text('by ${log.changedByName}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textHint)),
          ])),
          Text(
            log.changedAt.length > 10 ? log.changedAt.substring(0, 10) : log.changedAt,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ]),
      );
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final int maxLines;
  const _SheetField({
    required this.ctrl, required this.label,
    required this.hint, this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.labelLarge),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl, maxLines: maxLines,
            decoration: InputDecoration(hintText: hint),
          ),
        ]);
}