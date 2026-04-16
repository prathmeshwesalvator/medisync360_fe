import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class MediSyncAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? leading;

  const MediSyncAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Container(
        height: preferredSize.height + MediaQuery.of(context).padding.top,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          // Subtle bottom separator instead of elevation shadow
          border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // ── Leading ───────────────────────────────────────────
                if (showBack || leading != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  leading ??
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                ] else
                  const SizedBox(width: AppSpacing.md),

                // ── Title ─────────────────────────────────────────────
                Expanded(
                  child: Row(children: [
                    // Small logo mark only on the main "MediSync 360" bar
                    if (title == 'MediSync 360') ...[
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: AppRadius.sm,
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        style: AppTextStyles.titleLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                ),

                // ── Actions ───────────────────────────────────────────
                if (actions != null) ...actions!,
                const SizedBox(width: AppSpacing.xs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Back button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 12),
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: AppRadius.sm,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}