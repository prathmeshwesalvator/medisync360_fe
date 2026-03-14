import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/dashboard/data/models/doctor_model.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
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
  final _reasonCtrl = TextEditingController();
  AvailableSlotsModel? _slotsData;
  bool _loadingSlots = false;

  @override
  void initState() {
    super.initState();
    // FIX: check if slots are already loaded in cubit state before firing a
    // new request. BlocListener won't re-fire for the same state, so if we
    // just call loadSlots() and the cubit is already DoctorSlotsLoaded, the
    // listener never triggers and _loadingSlots stays true forever.
    final current = context.read<DoctorCubit>().state;
    if (current is DoctorSlotsLoaded) {
      _slotsData = current.slots;
      _loadingSlots = false;
    } else {
      _triggerLoadSlots();
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  // Separate the cubit call so date changes can reuse it cleanly
  void _triggerLoadSlots() {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
      _slotsData = null;
    });
    context.read<DoctorCubit>().loadSlots(
          widget.doctor.id,
          _dateStr(_selectedDate),
        );
  }

  void _confirm() {
    if (_selectedSlot == null) return;
    context.read<AppointmentCubit>().book(
          doctorId: widget.doctor.id,
          slotId: _selectedSlot!.id,
          reason: _reasonCtrl.text.trim(),
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
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AppointmentCubit, AppointmentState>(
            listener: (context, state) {
              if (state is AppointmentBooked) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('✓ Appointment booked successfully!'),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ));
                Navigator.of(context)
                  ..pop()
                  ..pop();
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
                // FIX: always update _slotsData here, whether it's the first
                // load or a date-change reload
                setState(() {
                  _slotsData = state.slots;
                  _loadingSlots = false;
                });
              }
              if (state is DoctorError) {
                setState(() => _loadingSlots = false);
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ── Doctor summary card ───────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.doctorRole.withOpacity(0.06),
                borderRadius: AppRadius.lg,
                border:
                    Border.all(color: AppColors.doctorRole.withOpacity(0.2)),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.doctorRole.withOpacity(0.15),
                  child: Text(
                    widget.doctor.fullName.isNotEmpty
                        ? widget.doctor.fullName[0].toUpperCase()
                        : 'D',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.doctorRole),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dr. ${widget.doctor.fullName}',
                            style: AppTextStyles.titleLarge),
                        Text(widget.doctor.specialization,
                            style: AppTextStyles.caption),
                      ]),
                ),
                Text(
                  '₹${widget.doctor.consultationFee.toStringAsFixed(0)}',
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Date picker ───────────────────────────────────────────
            const _Label('Select Date'),
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
                  Text(_displayDate(_selectedDate),
                      style: AppTextStyles.bodyLarge),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textHint),
                ]),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Slot picker ───────────────────────────────────────────
            const _Label('Select Time Slot'),
            const SizedBox(height: AppSpacing.xs),
            if (_loadingSlots)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
              )
            else if (_slotsData == null || _slotsData!.slots.isEmpty)
              const _NoSlots(message: 'No available slots for this day')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slotsData!.slots.map((s) {
                  final isAvailable = s.isAvailable;
                  final selected = _selectedSlot?.id == s.id;
                  return GestureDetector(
                    onTap: isAvailable
                        ? () => setState(() => _selectedSlot = s)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: !isAvailable
                            ? AppColors.inputFill
                            : selected
                                ? AppColors.primary
                                : AppColors.surface,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                        borderRadius: AppRadius.md,
                      ),
                      child: Text(
                        s.startTime,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: !isAvailable
                              ? AppColors.textHint
                              : selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: AppSpacing.lg),

            // ── Reason ────────────────────────────────────────────────
            const _Label('Reason for Visit'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Brief reason (e.g. fever, checkup)'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Payment note ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: AppRadius.md,
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment of ₹${widget.doctor.consultationFee.toStringAsFixed(0)} '
                    'will be collected at the time of consultation.',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.warning),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Confirm button ────────────────────────────────────────
            BlocBuilder<AppointmentCubit, AppointmentState>(
              builder: (context, state) {
                final loading = state is AppointmentLoading;
                // FIX: button is enabled as soon as a slot is selected,
                // regardless of reason field (reason is optional)
                final canBook = !loading && _selectedSlot != null;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: canBook ? _confirm : null,
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _selectedSlot == null
                                ? 'Select a time slot'
                                : 'Confirm Booking',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTextStyles.labelLarge);
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
          const Icon(Icons.event_busy_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.error)),
          ),
        ]),
      );
}