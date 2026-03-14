import 'package:flutter/material.dart';
import 'package:medisync_app/features/lab_report/presentation/pages/imaging_screen.dart';
import 'package:medisync_app/features/lab_report/presentation/pages/lab_report_list_screen.dart';
import 'package:medisync_app/features/lab_report/presentation/pages/medical_history_screen.dart';
import 'package:medisync_app/features/lab_report/presentation/pages/prescription_screen.dart';
import 'package:medisync_app/features/notification/presentation/screens/notification_screen.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class EHRScreen extends StatelessWidget {
  const EHRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Health Records',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _EHRTile(
            icon: Icons.favorite_border_rounded,
            iconColor: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            title: 'Medical History',
            subtitle: 'Blood group, allergies, medications',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MedicalHistoryScreen())),
          ),
          const SizedBox(height: 12),
          _EHRTile(
            icon: Icons.medication_outlined,
            iconColor: AppColors.doctorRole,
            bgColor: const Color(0xFFF5F3FF),
            title: 'Prescriptions',
            subtitle: 'Doctor prescriptions and medicines',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PrescriptionsScreen())),
          ),
          const SizedBox(height: 12),
          _EHRTile(
            icon: Icons.note_alt_outlined,
            iconColor: const Color(0xFF0891B2),
            bgColor: const Color(0xFFECFEFF),
            title: 'Doctor Notes',
            subtitle: 'Notes and diagnosis from your visits',
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SizedBox())
                // const VisitNotesScreen())
                ),
          ),
          const SizedBox(height: 12),
          _EHRTile(
            icon: Icons.image_outlined,
            iconColor: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
            title: 'Imaging Records',
            subtitle: 'X-Ray, MRI, CT Scan, Ultrasound',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ImagingScreen())),
          ),
          const SizedBox(height: 12),
          // _EHRTile(
          //   icon: Icons.science_outlined,
          //   iconColor: AppColors.accent,
          //   bgColor: const Color(0xFFF0FDF4),
          //   title: 'Lab Reports',
          //   subtitle: 'Blood tests, urine tests and more',
          //   onTap: () => Navigator.push(context,
          //       MaterialPageRoute(builder: (_) => const LabReportListScreen())),
          // ),
        ],
      ),
    );
  }
}

class _EHRTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EHRTile({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: AppRadius.md,
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(subtitle, style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ]),
      ),
    );
  }
}
