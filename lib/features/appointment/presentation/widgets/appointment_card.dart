import 'package:flutter/material.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  const AppointmentCard(
      {super.key, required this.appointment, required this.onTap});

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        return AppColors.accent;
      case AppointmentStatus.completed:
        return AppColors.primary;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.noShow:
        return AppColors.warning;
      case AppointmentStatus.rescheduled:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (appointment.appointmentType) {
      case AppointmentType.video:
        return Icons.videocam_rounded;
      case AppointmentType.phone:
        return Icons.phone_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.card,
          border: Border(left: BorderSide(color: _statusColor, width: 3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(_typeIcon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Dr. ${appointment.doctorName}',
                style: AppTextStyles.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _StatusBadge(status: appointment.status, color: _statusColor),
          ]),
          const SizedBox(height: 3),
          Text(
            appointment.doctorSpecialty.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(appointment.appointmentDate, style: AppTextStyles.bodyMedium),
            const SizedBox(width: 14),
            const Icon(Icons.access_time_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(appointment.slotTime, style: AppTextStyles.bodyMedium),
            const Spacer(),
            _PaymentChip(status: appointment.paymentStatus),
          ]),
          if (appointment.reason.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              appointment.reason,
              style: AppTextStyles.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: AppRadius.full),
        child: Text(
          status.replaceAll('_', ' ').toUpperCase(),
          style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.4),
        ),
      );
}

class _PaymentChip extends StatelessWidget {
  final String status;
  const _PaymentChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == PaymentStatus.paid
        ? AppColors.accent
        : status == PaymentStatus.refunded
            ? AppColors.warning
            : AppColors.textHint;
    return Row(children: [
      Icon(Icons.currency_rupee_rounded, size: 11, color: color),
      Text(status,
          style: AppTextStyles.caption
              .copyWith(color: color, fontWeight: FontWeight.w600)),
    ]);
  }
}
