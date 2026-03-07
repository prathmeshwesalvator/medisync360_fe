import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/appointment/presentation/pages/book_appointment_screen.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class DoctorDetailScreen extends StatefulWidget {
  final int doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DoctorCubit>().loadDetail(widget.doctorId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorCubit, DoctorState>(
      builder: (context, state) {
        if (state is DoctorLoading) return const Scaffold(body: LoadingWidget());

        if (state is DoctorError) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyStateWidget(
              title: 'Error',
              subtitle: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () =>
                  context.read<DoctorCubit>().loadDetail(widget.doctorId),
            ),
          );
        }

        if (state is DoctorDetailLoaded) {
          final d = state.doctor;
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                // ── Hero app bar ──────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 180,
                  backgroundColor: AppColors.doctorRole,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.doctorRole, Color(0xFF5B21B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                d.fullName.isNotEmpty
                                    ? d.fullName[0].toUpperCase()
                                    : 'D',
                                style: const TextStyle(
                                    fontSize: 32,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + availability
                        Row(children: [
                          Expanded(
                            child: Text('Dr. ${d.fullName}',
                                style: AppTextStyles.displayMedium),
                          ),
                          _AvailBadge(available: d.isAvailable),
                        ]),
                        const SizedBox(height: 4),
                        Text(
                          d.specialization.toUpperCase(),
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Stats
                        Row(children: [
                          _StatPill(
                              icon: Icons.star_rounded,
                              value:
                                  d.averageRating.toStringAsFixed(1),
                              label: 'Rating',
                              color: Colors.amber),
                          const SizedBox(width: 10),
                          _StatPill(
                              icon: Icons.people_rounded,
                              value: '${d.totalReviews}',
                              label: 'Reviews',
                              color: AppColors.primary),
                          const SizedBox(width: 10),
                          _StatPill(
                              icon: Icons.work_history_rounded,
                              value: '${d.experienceYears}y',
                              label: 'Exp',
                              color: AppColors.doctorRole),
                        ]),
                        const SizedBox(height: AppSpacing.md),

                        // Fee
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: AppRadius.md),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Consultation Fee',
                                  style: AppTextStyles.bodyMedium),
                              Text(
                                '₹${d.consultationFee.toStringAsFixed(0)}',
                                style: AppTextStyles.titleLarge
                                    .copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // About
                        const _SectionTitle('About'),
                        const SizedBox(height: 8),
                        Text(
                          d.bio.isNotEmpty
                              ? d.bio
                              : '${d.qualification}  ·  '
                                  '${d.experienceYears} years of experience',
                          style: AppTextStyles.bodyMedium
                              .copyWith(height: 1.6),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Location
                        if (d.city.isNotEmpty) ...[
                          const _SectionTitle('Location'),
                          const SizedBox(height: 8),
                          Row(children: [
                            const Icon(Icons.location_on_rounded,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text('${d.city}, ${d.state}',
                                style: AppTextStyles.bodyMedium),
                          ]),
                          if (d.hospitalName != null) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(
                                  Icons.local_hospital_outlined,
                                  size: 16,
                                  color: AppColors.hospitalRole),
                              const SizedBox(width: 6),
                              Text(d.hospitalName!,
                                  style: AppTextStyles.bodyMedium),
                            ]),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Availability schedule
                        if (d.slots.isNotEmpty) ...[
                          const _SectionTitle('Availability'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: d.slots
                                .map((s) => Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6),
                                      decoration: const BoxDecoration(
                                          color: AppColors.inputFill,
                                          borderRadius: AppRadius.md),
                                      child: Text(
                                          '${s.dayDisplay}  ${s.startTime}',
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  fontWeight:
                                                      FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Reviews
                        if (d.reviews.isNotEmpty) ...[
                          const _SectionTitle('Patient Reviews'),
                          const SizedBox(height: 8),
                          ...d.reviews
                              .take(3)
                              .map((r) => _ReviewTile(review: r)),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Book button
                        if (d.isAvailable)
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(
                                        value: context
                                            .read<DoctorCubit>()),
                                    BlocProvider.value(
                                        value: context
                                            .read<AppointmentCubit>()),
                                  ],
                                  child: BookAppointmentScreen(
                                      doctor: d),
                                ),
                              ),
                            ),
                            icon: const Icon(
                                Icons.calendar_today_rounded,
                                size: 18),
                            label: const Text('Book Appointment'),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) =>
      Text(title, style: AppTextStyles.headlineMedium);
}

class _AvailBadge extends StatelessWidget {
  final bool available;
  const _AvailBadge({required this.available});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: available
              ? AppColors.accent.withOpacity(0.1)
              : AppColors.error.withOpacity(0.1),
          borderRadius: AppRadius.full,
        ),
        child: Text(
          available ? 'Available' : 'Unavailable',
          style: AppTextStyles.caption.copyWith(
              color: available ? AppColors.accent : AppColors.error,
              fontWeight: FontWeight.w700),
        ),
      );
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatPill(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: AppRadius.md),
          child: Column(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(value,
                style:
                    AppTextStyles.labelLarge.copyWith(color: color)),
            Text(label, style: AppTextStyles.caption),
          ]),
        ),
      );
}

class _ReviewTile extends StatelessWidget {
  final dynamic review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
            color: AppColors.inputFill, borderRadius: AppRadius.md),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(review.patientName,
                    style: AppTextStyles.labelLarge
                        .copyWith(fontSize: 13)),
                const Spacer(),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ]),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(review.comment, style: AppTextStyles.caption),
              ],
            ]),
      );
}