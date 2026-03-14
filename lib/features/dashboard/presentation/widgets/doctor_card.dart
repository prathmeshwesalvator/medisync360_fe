import 'package:flutter/material.dart';
import 'package:medisync_app/features/dashboard/data/models/doctor_model.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class DoctorCard extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  const DoctorCard({super.key, required this.doctor, required this.onTap});

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
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.doctorRole.withOpacity(0.12),
            backgroundImage: doctor.profileImage.isNotEmpty
                ? NetworkImage(doctor.profileImage)
                : null,
            child: doctor.profileImage.isEmpty
                ? Text(
                    doctor.fullName.isNotEmpty
                        ? doctor.fullName[0].toUpperCase()
                        : 'D',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: AppColors.doctorRole))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Row(children: [
                Expanded(
                    child: Text('Dr. ${doctor.fullName}',
                        style: AppTextStyles.titleLarge)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    doctor.isAvailable ? 'Available' : 'Unavailable',
                    style: AppTextStyles.caption.copyWith(
                      color:
                          doctor.isAvailable ? AppColors.accent : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Text(doctor.specialization.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(
                  '${doctor.qualification}  •  ${doctor.experienceYears} yrs exp',
                  style: AppTextStyles.caption),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 3),
                Text(
                    '${doctor.averageRating.toStringAsFixed(1)} (${doctor.totalReviews})',
                    style: AppTextStyles.caption
                        .copyWith(fontWeight: FontWeight.w600)),
                // FIX: removed doctor.city — field no longer exists in DoctorModel
                // (backend DoctorProfile has no city; city belongs to Hospital)
                // Show hospital name instead if available
                if (doctor.hospitalName != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.local_hospital_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(doctor.hospitalName!,
                        style: AppTextStyles.caption,
                        overflow: TextOverflow.ellipsis),
                  ),
                ] else
                  const Spacer(),
                Text('₹${doctor.consultationFee.toStringAsFixed(0)}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primary)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}