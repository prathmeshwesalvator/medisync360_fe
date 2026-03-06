import 'package:flutter/material.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class AuthHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeaderWidget({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppRadius.md,
            boxShadow: AppShadows.button,
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, style: AppTextStyles.displayMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}
