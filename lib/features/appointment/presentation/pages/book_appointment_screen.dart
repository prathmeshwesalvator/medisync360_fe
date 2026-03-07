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
  String _type = 'in_person';
  final _reasonCtrl = TextEditingController();
  final _symptomsCtrl = TextEditingController();
  AvailableSlotsModel? _slotsData;
  bool _loadingSlots = false;

  static const _types = [
    ('in_person', 'In Person', Icons.person_rounded),
    ('video', 'Video Call', Icons.videocam_rounded),
    ('phone', 'Phone Call', Icons.phone_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _symptomsCtrl.dispose();
    super.dispose();
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _loadSlots() {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });
    context
        .read<DoctorCubit>()
        .loadSlots(widget.doctor.id, _dateStr(_selectedDate));
  }

  void _confirm() {
    context.read<AppointmentCubit>().book(
          doctorId: widget.doctor.id,
          date: _dateStr(_selectedDate),
          slotTime: _selectedSlot!.startTime,
          type: _type,
          reason: _reasonCtrl.text.trim(),
          symptoms: _symptomsCtrl.text.trim(),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment booked successfully! ✓'),
                    backgroundColor: AppColors.accent,
                  ),
                );
                // Pop back to appointments list
                Navigator.of(context)
                  ..pop() // book screen
                  ..pop(); // doctor detail
              }
              if (state is AppointmentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
          BlocListener<DoctorCubit, DoctorState>(
            listener: (context, state) {
              if (state is DoctorSlotsLoaded) {
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Doctor summary card ─────────────────────────────────────
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
                    widget.doctor.fullName[0].toUpperCase(),
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

            // ── Date picker ─────────────────────────────────────────────
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
                  _loadSlots();
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

            // ── Slot picker ─────────────────────────────────────────────
            const _Label('Select Time Slot'),
            const SizedBox(height: AppSpacing.xs),
            if (_loadingSlots)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
              )
            else if (_slotsData == null)
              const _NoSlots(message: 'No slots available')
            else if (_slotsData!.isOnLeave)
              const _NoSlots(message: 'Doctor is on leave this day')
            else if (_slotsData!.slots.isEmpty)
              const _NoSlots(message: 'No available slots for this day')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _slotsData!.slots.map((s) {
                  final booked = _slotsData!.bookedTimes.contains(s.startTime);
                  final selected = _selectedSlot?.id == s.id;
                  return GestureDetector(
                    onTap:
                        booked ? null : () => setState(() => _selectedSlot = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: booked
                            ? AppColors.inputFill
                            : selected
                                ? AppColors.primary
                                : AppColors.surface,
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.divider,
                        ),
                        borderRadius: AppRadius.md,
                      ),
                      child: Text(
                        s.startTime,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: booked
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

            // ── Consultation type ───────────────────────────────────────
            const _Label('Consultation Type'),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: _types.map((t) {
                final selected = _type == t.$1;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = t.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.surface,
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.divider,
                        ),
                        borderRadius: AppRadius.md,
                      ),
                      child: Column(children: [
                        Icon(t.$3,
                            size: 20,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint),
                        const SizedBox(height: 4),
                        Text(
                          t.$2,
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Reason ──────────────────────────────────────────────────
            const _Label('Reason for Visit'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  hintText: 'Brief reason (e.g. fever, checkup)'),
            ),
            const SizedBox(height: AppSpacing.md),

            const _Label('Symptoms'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _symptomsCtrl,
              maxLines: 3,
              decoration:
                  const InputDecoration(hintText: 'Describe your symptoms…'),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Payment note ────────────────────────────────────────────
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
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Confirm button ──────────────────────────────────────────
            BlocBuilder<AppointmentCubit, AppointmentState>(
              builder: (context, state) {
                final loading = state is AppointmentLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        loading || _selectedSlot == null ? null : _confirm,
                    child: loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirm Booking',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
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
          Text(message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error)),
        ]),
      );
}
