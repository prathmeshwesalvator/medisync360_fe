import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
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

  // ── Cancel bottom sheet ───────────────────────────────────────────────────
  void _showCancel() {
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
          const Text('Cancel Appointment', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: const InputDecoration(
                hintText: 'Reason for cancellation (optional)'),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Keep it'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () {
                  Navigator.pop(ctx);
                  context
                      .read<AppointmentCubit>()
                      .cancel(_appt.id, reason: ctrl.text);
                },
                child: const Text('Cancel'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Reschedule bottom sheet ───────────────────────────────────────────────
  void _showReschedule() {
    DateTime picked = DateTime.now().add(const Duration(days: 1));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Reschedule', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
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
                if (d != null) setModal(() => picked = d);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                final ds =
                    '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                context
                    .read<AppointmentCubit>()
                    .reschedule(_appt.id, ds, _appt.slotTime);
              },
              child: const Text('Confirm Reschedule'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentCubit, AppointmentState>(
      listener: (context, state) {
        if (state is AppointmentActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.accent,
          ));
          setState(() => _appt = state.appointment);
        }
        if (state is AppointmentError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
          ));
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Status banner
            _StatusBanner(status: _appt.status),
            const SizedBox(height: AppSpacing.md),

            // Doctor
            _Card(
              title: 'Doctor',
              child: Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.doctorRole.withOpacity(0.12),
                  child: Text(
                    _appt.doctorName.isNotEmpty
                        ? _appt.doctorName[0].toUpperCase()
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
                        Text('Dr. ${_appt.doctorName}',
                            style: AppTextStyles.titleLarge),
                        Text(_appt.doctorSpecialty,
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                      ]),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Schedule
            _Card(
              title: 'Schedule',
              child: Column(children: [
                _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Date',
                    value: _appt.appointmentDate),
                const Divider(height: 16),
                _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Time',
                    value: _appt.slotTime),
                const Divider(height: 16),
                _DetailRow(
                  icon: _appt.appointmentType == AppointmentType.video
                      ? Icons.videocam_rounded
                      : _appt.appointmentType == AppointmentType.phone
                          ? Icons.phone_rounded
                          : Icons.person_rounded,
                  label: 'Type',
                  value:
                      _appt.appointmentType.replaceAll('_', ' ').toUpperCase(),
                ),
                if (_appt.hospitalName != null) ...[
                  const Divider(height: 16),
                  _DetailRow(
                      icon: Icons.local_hospital_rounded,
                      label: 'Hospital',
                      value: _appt.hospitalName!),
                ],
              ]),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Visit info
            if (_appt.reason.isNotEmpty || _appt.symptoms.isNotEmpty)
              _Card(
                title: 'Visit Info',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_appt.reason.isNotEmpty) ...[
                        Text('Reason',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_appt.reason,
                            style:
                                AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                      ],
                      if (_appt.symptoms.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Symptoms',
                            style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_appt.symptoms,
                            style:
                                AppTextStyles.bodyMedium.copyWith(height: 1.5)),
                      ],
                    ]),
              ),

            // Doctor notes
            if (_appt.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _Card(
                title: "Doctor's Notes",
                child: Text(_appt.notes,
                    style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
              ),
            ],

            const SizedBox(height: AppSpacing.sm),

            // Payment
            _Card(
              title: 'Payment',
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Consultation Fee',
                        style: AppTextStyles.bodyMedium),
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_appt.consultationFee.toStringAsFixed(0)}',
                            style: AppTextStyles.titleLarge
                                .copyWith(color: AppColors.primary),
                          ),
                          Text(
                            _appt.paymentStatus.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: _appt.paymentStatus == PaymentStatus.paid
                                  ? AppColors.accent
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                  ]),
            ),

            // Status history
            if (_appt.statusLogs.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _Card(
                title: 'History',
                child: Column(
                  children:
                      _appt.statusLogs.map((l) => _LogTile(log: l)).toList(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Action buttons
            if (_appt.isCancellable)
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
                if (_appt.isReschedulable) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showReschedule,
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: const Text('Reschedule'),
                    ),
                  ),
                ],
              ]),

            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  Color get _color {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.accent;
      case AppointmentStatus.completed:
        return AppColors.primary;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.rescheduled:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Icons.check_circle_rounded;
      case AppointmentStatus.completed:
        return Icons.task_alt_rounded;
      case AppointmentStatus.cancelled:
        return Icons.cancel_rounded;
      case AppointmentStatus.rescheduled:
        return Icons.update_rounded;
      default:
        return Icons.pending_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: _color.withOpacity(0.08), borderRadius: AppRadius.lg),
        child: Row(children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Status',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
            Text(status.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.labelLarge.copyWith(color: _color)),
          ]),
        ]),
      );
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
                  color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ]),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

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

class _LogTile extends StatelessWidget {
  final StatusLogModel log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 8, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                log.fromStatus.isNotEmpty
                    ? '${log.fromStatus} → ${log.toStatus}'
                    : log.toStatus,
                style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
              ),
              if (log.reason.isNotEmpty)
                Text(log.reason, style: AppTextStyles.caption),
              if (log.changedByName != null)
                Text('by ${log.changedByName}',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textHint)),
            ]),
          ),
          Text(
            log.changedAt.length > 10
                ? log.changedAt.substring(0, 10)
                : log.changedAt,
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
        ]),
      );
}
