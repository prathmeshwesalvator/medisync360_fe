import 'package:flutter/material.dart';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class RoleOption {
  final String role;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const RoleOption({
    required this.role,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const _roleOptions = [
  RoleOption(
    role: UserRole.user,
    label: 'Patient',
    description: 'Book appointments & manage health',
    icon: Icons.person_rounded,
    color: AppColors.userRole,
  ),
  RoleOption(
    role: UserRole.doctor,
    label: 'Doctor',
    description: 'Manage patients & appointments',
    icon: Icons.medical_services_rounded,
    color: AppColors.doctorRole,
  ),
  RoleOption(
    role: UserRole.hospital,
    label: 'Hospital',
    description: 'Manage facility & staff',
    icon: Icons.local_hospital_rounded,
    color: AppColors.hospitalRole,
  ),
];

class RoleSelectorWidget extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _roleOptions.map((option) {
        final isSelected = selectedRole == option.role;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option.role != UserRole.hospital ? AppSpacing.sm : 0,
            ),
            child: _RoleCard(
              option: option,
              isSelected: isSelected,
              onTap: () => onRoleChanged(option.role),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final RoleOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? option.color.withOpacity(0.08) : AppColors.inputFill,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: isSelected ? option.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              color: isSelected ? option.color : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              option.label,
              style: AppTextStyles.labelLarge.copyWith(
                color: isSelected ? option.color : AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}