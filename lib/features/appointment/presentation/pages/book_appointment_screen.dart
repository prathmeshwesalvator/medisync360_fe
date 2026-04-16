import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/dashboard/data/models/doctor_model.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class BookAppointmentScreen extends StatefulWidget {
  final DoctorModel doctor;
  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DoctorSlotModel? _selectedSlot;
  String _appointmentType = AppointmentType.inPerson;
  final _reasonCtrl   = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  AvailableSlotsModel? _slotsData;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<DoctorCubit>().state;
    if (current is DoctorSlotsLoaded) {
      _slotsData = current.slots;
    } else {
      _triggerLoadSlots();
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _symptomsCtrl.dispose();
    super.dispose();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _triggerLoadSlots() {
    setState(() { _loadingSlots = true; _selectedSlot = null; _slotsData = null; });
    context.read<DoctorCubit>().loadSlots(widget.doctor.id, _dateStr(_selectedDate));
  }

  void _confirm() {
    if (_selectedSlot == null) return;
    context.read<AppointmentCubit>().book(
          doctorId: widget.doctor.id,
          slotId: _selectedSlot!.id,
          reason: _reasonCtrl.text.trim(),
          symptoms: _symptomsCtrl.text.trim(),
          appointmentType: _appointmentType,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Appointment',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AppointmentCubit, AppointmentState>(
            listener: (context, state) {
              if (state is AppointmentBooked) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('✓ Appointment booked! Awaiting doctor confirmation.'),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ));
                Navigator.of(context)..pop()..pop();
              }
              if (state is AppointmentError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
              }
            },
          ),
          BlocListener<DoctorCubit, DoctorState>(
            listener: (context, state) {
              if (state is DoctorSlotsLoading) {
                setState(() => _loadingSlots = true);
              }
              if (state is DoctorSlotsLoaded) {
                setState(() { _slotsData = state.slots; _loadingSlots = false; });
              }
              if (state is DoctorError) {
                setState(() => _loadingSlots = false);
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Doctor summary ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.doctorRole.withOpacity(0.06),
                borderRadius: AppRadius.lg,
                border: Border.all(color: AppColors.doctorRole.withOpacity(0.2)),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.doctorRole.withOpacity(0.15),
                  child: Text(
                    widget.doctor.fullName.isNotEmpty
                        ? widget.doctor.fullName[0].toUpperCase() : 'D',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.doctorRole),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Dr. ${widget.doctor.fullName}',
                        style: AppTextStyles.titleLarge),
                    Text(widget.doctor.specialization,
                        style: AppTextStyles.caption),
                    if (widget.doctor.hospitalName != null)
                      Text(widget.doctor.hospitalName!,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.hospitalRole)),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₹${widget.doctor.consultationFee.toStringAsFixed(0)}',
                      style: AppTextStyles.titleLarge
                          .copyWith(color: AppColors.primary)),
                  const Text('fee', style: AppTextStyles.caption),
                ]),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Appointment type ────────────────────────────────────────────
            const _SectionLabel('Appointment Type'),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              _TypeChip(
                icon: Icons.person_pin_rounded,
                label: 'In Person',
                value: AppointmentType.inPerson,
                selected: _appointmentType == AppointmentType.inPerson,
                color: AppColors.primary,
                onTap: () => setState(() => _appointmentType = AppointmentType.inPerson),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TypeChip(
                icon: Icons.videocam_rounded,
                label: 'Video Call',
                value: AppointmentType.video,
                selected: _appointmentType == AppointmentType.video,
                color: AppColors.doctorRole,
                onTap: () => setState(() => _appointmentType = AppointmentType.video),
              ),
              const SizedBox(width: AppSpacing.sm),
              _TypeChip(
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: AppointmentType.phone,
                selected: _appointmentType == AppointmentType.phone,
                color: AppColors.accent,
                onTap: () => setState(() => _appointmentType = AppointmentType.phone),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),

            // ── Date picker ─────────────────────────────────────────────────
            const _SectionLabel('Select Date'),
            const SizedBox(height: AppSpacing.xs),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (d != null) {
                  setState(() => _selectedDate = d);
                  _triggerLoadSlots();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: AppRadius.md,
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: AppTextStyles.bodyLarge,
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Slot picker ─────────────────────────────────────────────────
            const _SectionLabel('Select Time Slot'),
            const SizedBox(height: AppSpacing.xs),
            if (_loadingSlots)
              const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: LoadingWidget()))
            else if (_slotsData == null || _slotsData!.slots.isEmpty)
              _NoSlots(message: _slotsData == null
                  ? 'No available slots for this day'
                  : 'All slots booked. Try another date.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slotsData!.slots.map((s) {
                  final available = s.isAvailable;
                  final sel = _selectedSlot?.id == s.id;
                  return GestureDetector(
                    onTap: available ? () => setState(() => _selectedSlot = s) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: !available
                            ? AppColors.inputFill
                            : sel
                                ? AppColors.primary
                                : AppColors.surface,
                        border: Border.all(
                            color: sel ? AppColors.primary : AppColors.divider),
                        borderRadius: AppRadius.md,
                      ),
                      child: Text(s.startTime,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: !available
                                ? AppColors.textHint
                                : sel ? Colors.white : AppColors.textPrimary,
                          )),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),

            // ── Reason ──────────────────────────────────────────────────────
            const _SectionLabel('Reason for Visit'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Brief reason (e.g. fever, routine checkup)'),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Symptoms ─────────────────────────────────────────────────────
            const _SectionLabel('Symptoms (optional)'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _symptomsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  hintText: 'Describe symptoms so the doctor can prepare'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Payment note ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: AppRadius.md,
                border: Border.all(color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fee of ₹${widget.doctor.consultationFee.toStringAsFixed(0)} '
                    'is due at consultation. Appointment is pending doctor confirmation.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Confirm button ───────────────────────────────────────────────
            BlocBuilder<AppointmentCubit, AppointmentState>(
              builder: (context, state) {
                final loading = state is AppointmentLoading;
                final canBook = !loading && _selectedSlot != null;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canBook ? _confirm : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.md),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text(
                            _selectedSlot == null
                                ? 'Select a time slot to continue'
                                : 'Confirm Booking',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.labelLarge);
}

class _TypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.icon, required this.label, required this.value,
    required this.selected, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? color.withOpacity(0.1) : AppColors.inputFill,
              borderRadius: AppRadius.md,
              border: Border.all(
                  color: selected ? color : Colors.transparent, width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: selected ? color : AppColors.textHint),
              const SizedBox(height: 3),
              Text(label,
                  style: AppTextStyles.caption.copyWith(
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center),
            ]),
          ),
        ),
      );
}

class _NoSlots extends StatelessWidget {
  final String message;
  const _NoSlots({required this.message});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.06),
          borderRadius: AppRadius.md,
        ),
        child: Row(children: [
          const Icon(Icons.event_busy_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
        ]),
      );
}