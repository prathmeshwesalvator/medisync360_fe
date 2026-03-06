import 'package:flutter/material.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class HospitalSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback? onFilterTap;

  const HospitalSearchBar({
    super.key,
    required this.onSearch,
    this.onFilterTap,
  });

  @override
  State<HospitalSearchBar> createState() => _HospitalSearchBarState();
}

class _HospitalSearchBarState extends State<HospitalSearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onSearch,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Search hospitals by name or city…',
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 20, color: AppColors.textSecondary),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        _ctrl.clear();
                        widget.onSearch('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        if (widget.onFilterTap != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppRadius.md,
            ),
            child: IconButton(
              onPressed: widget.onFilterTap,
              icon: const Icon(Icons.tune_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ],
    );
  }
}