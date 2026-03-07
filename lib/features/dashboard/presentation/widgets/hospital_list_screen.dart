import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/hospital_details_screen.dart';
import '../bloc/hospital_cubit.dart';
import 'hospital_card.dart';
import 'hospital_search_bar.dart';
import 'empty_state.dart';
import 'loading.dart';
import 'medisync_appbar.dart';
import '../pages/hospital_map_screen.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class HospitalListScreen extends StatefulWidget {
  const HospitalListScreen({super.key});

  @override
  State<HospitalListScreen> createState() => _HospitalListScreenState();
}

class _HospitalListScreenState extends State<HospitalListScreen> {
  String _query = '';
  bool _icuOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<HospitalCubit>().loadHospitals();
  }

  void _search(String query) {
    setState(() => _query = query);
    context.read<HospitalCubit>().loadHospitals(
          query: query,
          hasIcu: _icuOnly,
        );
  }

  void _toggleIcu(bool value) {
    setState(() => _icuOnly = value);
    context.read<HospitalCubit>().loadHospitals(
          query: _query,
          hasIcu: value,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediSyncAppBar(
        title: 'Find Hospitals',
        actions: [
          // ── Map toggle button ──────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.map_rounded),
            tooltip: 'Map View',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<HospitalCubit>(),
                    child: const HospitalMapScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + Filter bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Column(
              children: [
                HospitalSearchBar(onSearch: _search),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _FilterChip(
                      label: 'ICU Available',
                      selected: _icuOnly,
                      onSelected: _toggleIcu,
                      icon: Icons.local_hospital_rounded,
                    ),
                    const SizedBox(width: 8),
                    // ── Map banner chip ──────────────────────────────────────
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HospitalCubit>(),
                            child: const HospitalMapScreen(),
                          ),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.hospitalRole.withOpacity(0.1),
                          borderRadius: AppRadius.full,
                          border: Border.all(
                              color: AppColors.hospitalRole.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.map_rounded,
                                size: 14, color: AppColors.hospitalRole),
                            SizedBox(width: 6),
                            Text('Map View',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.hospitalRole,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Results
          Expanded(
            child: BlocBuilder<HospitalCubit, HospitalState>(
              builder: (context, state) {
                if (state is HospitalLoading) {
                  return const LoadingWidget(message: 'Finding hospitals…');
                }
                if (state is HospitalError) {
                  return EmptyStateWidget(
                    title: 'Something went wrong',
                    subtitle: state.message,
                    icon: Icons.wifi_off_rounded,
                    buttonLabel: 'Retry',
                    onButtonTap: () =>
                        context.read<HospitalCubit>().loadHospitals(),
                  );
                }
                if (state is HospitalListLoaded) {
                  if (state.hospitals.isEmpty) {
                    return EmptyStateWidget(
                      title: 'No hospitals found',
                      subtitle: _query.isNotEmpty
                          ? 'Try a different search term'
                          : 'No hospitals are available right now',
                      icon: Icons.search_off_rounded,
                      buttonLabel: 'Clear search',
                      onButtonTap: () => _search(''),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                        child: Text(
                          '${state.count} hospitals found',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: state.hospitals.length,
                          itemBuilder: (_, i) => HospitalCard(
                            hospital: state.hospitals[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<HospitalCubit>(),
                                  child: HospitalDetailScreen(
                                      hospitalId: state.hospitals[i].id),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.inputFill,
          borderRadius: AppRadius.full,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color:
                    selected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color:
                    selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}