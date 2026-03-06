import 'package:flutter/material.dart';
import 'package:medisync_app/features/dashboard/data/models/hospital_model.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class HospitalCard extends StatelessWidget {
  final HospitalModel hospital;
  final VoidCallback onTap;

  const HospitalCard({
    super.key,
    required this.hospital,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / Icon
                  _HospitalAvatar(
                      name: hospital.name, logoUrl: hospital.logoUrl),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                hospital.name,
                                style: AppTextStyles.titleLarge,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hospital.isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Icon(Icons.verified_rounded,
                                    color: AppColors.primary, size: 16),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${hospital.city}, ${hospital.state}',
                                style: AppTextStyles.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (hospital.distanceKm != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${hospital.distanceKm} km away',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Capacity Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: AppRadius.md,
              ),
              child: Row(
                children: [
                  _CapacityChip(
                    label: 'Beds',
                    available: hospital.availableBeds,
                    total: hospital.totalBeds,
                    color: hospital.hasAvailableBeds
                        ? AppColors.accent
                        : AppColors.error,
                  ),
                  const _Divider(),
                  _CapacityChip(
                    label: 'ICU',
                    available: hospital.icuAvailable,
                    total: hospital.icuTotal,
                    color: hospital.hasAvailableICU
                        ? AppColors.accent
                        : AppColors.error,
                  ),
                  const _Divider(),
                  _CapacityChip(
                    label: 'Emergency',
                    available: hospital.emergencyAvailable,
                    total: hospital.emergencyBeds,
                    color: hospital.emergencyAvailable > 0
                        ? AppColors.accent
                        : AppColors.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Footer: status + arrow
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(status: hospital.status),
                  Row(
                    children: [
                      Text('View details',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 11, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _HospitalAvatar extends StatelessWidget {
  final String name;
  final String logoUrl;

  const _HospitalAvatar({required this.name, required this.logoUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.hospitalRole.withOpacity(0.1),
        borderRadius: AppRadius.md,
      ),
      child: logoUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: AppRadius.md,
              child: Image.network(logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _defaultIcon()),
            )
          : _defaultIcon(),
    );
  }

  Widget _defaultIcon() => const Icon(
        Icons.local_hospital_rounded,
        color: AppColors.hospitalRole,
        size: 26,
      );
}

class _CapacityChip extends StatelessWidget {
  final String label;
  final int available;
  final int total;
  final Color color;

  const _CapacityChip({
    required this.label,
    required this.available,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$available/$total',
              style: AppTextStyles.labelLarge
                  .copyWith(color: color, fontSize: 13)),
          const SizedBox(height: 1),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case HospitalStatus.active:
        color = AppColors.accent;
        label = 'Active';
        break;
      case HospitalStatus.maintenance:
        color = AppColors.warning;
        label = 'Maintenance';
        break;
      default:
        color = AppColors.error;
        label = 'Inactive';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.full,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
