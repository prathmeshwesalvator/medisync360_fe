import 'package:flutter/material.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class CapacityBar extends StatelessWidget {
  final String label;
  final int available;
  final int total;
  final Color? color;

  const CapacityBar({
    super.key,
    required this.label,
    required this.available,
    required this.total,
    this.color,
  });

  double get _occupancyFraction => total == 0 ? 0 : (total - available) / total;

  Color get _barColor {
    if (color != null) return color!;
    if (_occupancyFraction >= 0.9) return AppColors.error;
    if (_occupancyFraction >= 0.7) return AppColors.warning;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$available',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: _barColor, fontSize: 14),
                  ),
                  TextSpan(
                    text: ' / $total available',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.full,
          child: LinearProgressIndicator(
            value: _occupancyFraction,
            minHeight: 8,
            backgroundColor: AppColors.inputFill,
            valueColor: AlwaysStoppedAnimation<Color>(_barColor),
          ),
        ),
      ],
    );
  }
}
