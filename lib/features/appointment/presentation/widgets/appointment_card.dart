import 'package:flutter/material.dart';
import 'package:medisync_app/features/appointment/data/models/appointment_model.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onTap;
  /// When set, shows a "Confirm" button on the card (doctor view only).
  final VoidCallback? onConfirm;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onTap,
    this.onConfirm,
  });

  Color get _statusColor {
    switch (appointment.status) {
      case AppointmentStatus.confirmed:   return AppColors.accent;
      case AppointmentStatus.completed:   return AppColors.primary;
      case AppointmentStatus.cancelled:   return AppColors.error;
      case AppointmentStatus.noShow:      return AppColors.warning;
      case AppointmentStatus.rescheduled: return AppColors.warning;
      default:                            return AppColors.textSecondary;
    }
  }

  IconData get _typeIcon {
    switch (appointment.appointmentType) {
      case AppointmentType.video: return Icons.videocam_rounded;
      case AppointmentType.phone: return Icons.phone_rounded;
      default:                    return Icons.person_pin_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.card,
          border: Border(
            left: BorderSide(color: _statusColor, width: 3.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: type icon + doctor name + status badge ───────────
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: AppRadius.sm,
                  ),
                  child: Icon(_typeIcon, size: 14, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
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

              // ── Specialty ─────────────────────────────────────────────────
              Text(
                appointment.doctorSpecialty.toUpperCase(),
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),

              // ── Date / time / payment ──────────────────────────────────────
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(appointment.appointmentDate, style: AppTextStyles.bodyMedium),
                const SizedBox(width: 12),
                const Icon(Icons.access_time_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(appointment.slotTime, style: AppTextStyles.bodyMedium),
                const Spacer(),
                _PaymentChip(status: appointment.paymentStatus),
              ]),

              // ── Appointment type label for virtual ─────────────────────────
              if (appointment.isVirtual) ...[
                const SizedBox(height: 5),
                Row(children: [
                  Icon(_typeIcon, size: 12, color: AppColors.doctorRole),
                  const SizedBox(width: 4),
                  Text(
                    AppointmentType.label(appointment.appointmentType),
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.doctorRole, fontWeight: FontWeight.w600),
                  ),
                  if (appointment.hasMeetingLink) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.link_rounded, size: 12, color: AppColors.accent),
                    const SizedBox(width: 2),
                    Text('Link attached',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.accent)),
                  ],
                ]),
              ],

              // ── Reason snippet ─────────────────────────────────────────────
              if (appointment.reason.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  appointment.reason,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // ── Doctor confirm CTA (doctor-view only) ──────────────────────
              if (onConfirm != null && appointment.canConfirm) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.doctorRole,
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.md),
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16, color: Colors.white),
                    label: const Text('Confirm Appointment',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
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