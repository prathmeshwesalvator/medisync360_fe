import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/doctor_details_screen.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/medisync_appbar.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import '../widgets/doctor_card.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _searchCtrl = TextEditingController();
  String _spec = '';

  final _specializations = [
    'All',
    'Cardiology',
    'Neurology',
    'Orthopedics',
    'Pediatrics',
    'General',
    'Dermatology',
    'Psychiatry',
    'ENT',
    'Gynecology',
    'Oncology',
  ];

  @override
  void initState() {
    super.initState();
    context.read<DoctorCubit>().loadDoctors();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search([String? q]) {
    context.read<DoctorCubit>().loadDoctors(
          query: q ?? _searchCtrl.text,
          specialization: _spec == 'All' ? '' : _spec,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MediSyncAppBar(title: 'Find Doctors', showBack: true),
      body: Column(children: [
        // ── Search + filter ─────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(children: [
            TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Search by doctor name…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search('');
                        })
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _specializations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final s = _specializations[i];
                  final selected = _spec == s || (_spec.isEmpty && s == 'All');
                  return GestureDetector(
                    onTap: () {
                      setState(() => _spec = s == 'All' ? '' : s);
                      _search();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            selected ? AppColors.primary : AppColors.inputFill,
                        borderRadius: AppRadius.full,
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.caption.copyWith(
                          color:
                              selected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
        const Divider(height: 1),

        // ── Results ──────────────────────────────────────────────────────────
        Expanded(
          child: BlocBuilder<DoctorCubit, DoctorState>(
            builder: (context, state) {
              if (state is DoctorLoading) {
                return const LoadingWidget(message: 'Finding doctors…');
              }

              if (state is DoctorError) {
                return EmptyStateWidget(
                  title: 'Could not load doctors',
                  subtitle: state.message,
                  icon: Icons.wifi_off_rounded,
                  buttonLabel: 'Retry',
                  onButtonTap: () => context.read<DoctorCubit>().loadDoctors(),
                );
              }

              if (state is DoctorListLoaded) {
                if (state.doctors.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No doctors found',
                    subtitle: 'Try a different name or specialization',
                    icon: Icons.person_search_rounded,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: state.doctors.length,
                  itemBuilder: (_, i) => DoctorCard(
                    doctor: state.doctors[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: context.read<DoctorCubit>(),
                          child:
                              DoctorDetailScreen(doctorId: state.doctors[i].id),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ]),
    );
  }
}
