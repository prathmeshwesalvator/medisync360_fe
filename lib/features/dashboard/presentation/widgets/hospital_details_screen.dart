import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/hospital_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/capacity_bar.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class HospitalDetailScreen extends StatefulWidget {
  final int hospitalId;

  const HospitalDetailScreen({super.key, required this.hospitalId});

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HospitalCubit>().loadHospitalDetail(widget.hospitalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HospitalCubit, HospitalState>(
        builder: (context, state) {
          if (state is HospitalLoading) {
            return const Scaffold(
                body: LoadingWidget(message: 'Loading hospital details…'));
          }
          if (state is HospitalError) {
            return Scaffold(
              appBar: AppBar(),
              body: EmptyStateWidget(
                title: 'Could not load',
                subtitle: state.message,
                icon: Icons.wifi_off_rounded,
                buttonLabel: 'Retry',
                onButtonTap: () => context
                    .read<HospitalCubit>()
                    .loadHospitalDetail(widget.hospitalId),
              ),
            );
          }
          if (state is HospitalDetailLoaded) {
            final h = state.hospital;
            return CustomScrollView(
              slivers: [
                // Hero App Bar
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: h.imageUrl.isNotEmpty
                        ? Image.network(h.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _DefaultHeroBackground())
                        : _DefaultHeroBackground(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                        child: Text(h.name,
                                            style:
                                                AppTextStyles.displayMedium)),
                                    if (h.isVerified)
                                      const Icon(Icons.verified_rounded,
                                          color: AppColors.primary, size: 20),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('${h.city}, ${h.state} — ${h.pincode}',
                                      style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Capacity Section
                        const _SectionTitle(title: 'Live Capacity'),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.lg,
                            boxShadow: AppShadows.card,
                          ),
                          child: Column(
                            children: [
                              CapacityBar(
                                  label: 'General Beds',
                                  available: h.availableBeds,
                                  total: h.totalBeds),
                              const SizedBox(height: AppSpacing.md),
                              CapacityBar(
                                  label: 'ICU Beds',
                                  available: h.icuAvailable,
                                  total: h.icuTotal),
                              const SizedBox(height: AppSpacing.md),
                              CapacityBar(
                                  label: 'Emergency Beds',
                                  available: h.emergencyAvailable,
                                  total: h.emergencyBeds),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Contact
                        const _SectionTitle(title: 'Contact'),
                        const SizedBox(height: AppSpacing.md),
                        _InfoCard(children: [
                          _InfoRow(
                              icon: Icons.phone_rounded,
                              label: 'Phone',
                              value: h.phone),
                          if (h.email.isNotEmpty)
                            _InfoRow(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: h.email),
                          _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: h.address),
                          if (h.website.isNotEmpty)
                            _InfoRow(
                                icon: Icons.language_rounded,
                                label: 'Website',
                                value: h.website),
                        ]),
                        const SizedBox(height: AppSpacing.lg),

                        // Departments
                        if (h.departments.isNotEmpty) ...[
                          const _SectionTitle(title: 'Departments'),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: h.departments
                                .where((d) => d.isActive)
                                .map((d) => _DeptChip(name: d.nameDisplay))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Amenities
                        if (h.amenities.isNotEmpty) ...[
                          const _SectionTitle(title: 'Amenities'),
                          const SizedBox(height: AppSpacing.md),
                          _InfoCard(
                            children: h.amenities
                                .map((a) => _AmenityRow(amenity: a))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // About
                        if (h.description.isNotEmpty) ...[
                          const _SectionTitle(title: 'About'),
                          const SizedBox(height: AppSpacing.md),
                          Text(h.description,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(height: 1.6)),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Book Appointment CTA
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, '/book-appointment',
                              arguments: h),
                          icon: const Icon(Icons.calendar_today_rounded,
                              size: 18),
                          label: const Text('Book Appointment'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _DefaultHeroBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.hospitalRole, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child:
            Icon(Icons.local_hospital_rounded, color: Colors.white54, size: 80),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.headlineMedium);
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children:
            children.expand((w) => [w, const Divider(height: 16)]).toList()
              ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption),
              const SizedBox(height: 1),
              Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeptChip extends StatelessWidget {
  final String name;

  const _DeptChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: AppRadius.full,
      ),
      child: Text(name,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          )),
    );
  }
}

class _AmenityRow extends StatelessWidget {
  final dynamic amenity;

  const _AmenityRow({required this.amenity});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          amenity.isAvailable
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded,
          color: amenity.isAvailable ? AppColors.accent : AppColors.textHint,
          size: 16,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(amenity.name, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}
