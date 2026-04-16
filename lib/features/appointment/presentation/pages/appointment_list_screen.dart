import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/appointment/presentation/pages/appointment_details_screen.dart';
import 'package:medisync_app/features/appointment/presentation/widgets/appointment_card.dart';
import 'package:medisync_app/features/dashboard/data/repository/doctor_repository.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/doctor_list_screen.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const _tabs = [
    ('All', ''),
    ('Upcoming', 'pending'),
    ('Confirmed', 'confirmed'),
    ('Completed', 'completed'),
    ('Cancelled', 'cancelled'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    context.read<AppointmentCubit>().loadMyAppointments();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        title: const Text('My Appointments',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Book appointment',
            onPressed: () => _goBook(context),
          ),
        ],
      ),
      body: Column(children: [
        // ── Tab bar ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2.5,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
            onTap: (i) => context
                .read<AppointmentCubit>()
                .loadMyAppointments(status: _tabs[i].$2),
          ),
        ),
        // ── Content ──────────────────────────────────────────────────────────
        Expanded(
          child: BlocConsumer<AppointmentCubit, AppointmentState>(
            listener: (context, state) {
              if (state is AppointmentActionSuccess) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Row(children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(state.message),
                    ]),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.md),
                    margin: const EdgeInsets.all(AppSpacing.md),
                  ));
                context.read<AppointmentCubit>().loadMyAppointments();
              }
              if (state is AppointmentBooked) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('✓ Appointment booked! Awaiting confirmation.'),
                    backgroundColor: AppColors.accent,
                    behavior: SnackBarBehavior.floating,
                  ));
                context.read<AppointmentCubit>().loadMyAppointments();
              }
              if (state is AppointmentError) {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ));
              }
            },
            builder: (context, state) {
              if (state is AppointmentLoading) return const LoadingWidget();

              if (state is AppointmentError) {
                return EmptyStateWidget(
                  title: 'Could not load appointments',
                  subtitle: state.message,
                  icon: Icons.calendar_today_rounded,
                  buttonLabel: 'Retry',
                  onButtonTap: () =>
                      context.read<AppointmentCubit>().loadMyAppointments(),
                );
              }

              if (state is AppointmentListLoaded) {
                if (state.appointments.isEmpty) {
                  return EmptyStateWidget(
                    title: 'No appointments',
                    subtitle: 'Book your first appointment with a doctor',
                    icon: Icons.calendar_today_rounded,
                    buttonLabel: 'Find a Doctor',
                    onButtonTap: () => _goBook(context),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<AppointmentCubit>().loadMyAppointments(),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.appointments.length,
                    itemBuilder: (_, i) => AppointmentCard(
                      appointment: state.appointments[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<AppointmentCubit>(),
                            child: AppointmentDetailScreen(
                                appointment: state.appointments[i]),
                          ),
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

  void _goBook(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) => DoctorCubit(DoctorRepository(), TokenStorage()),
        child: const DoctorListScreen(),
      ),
    ));
  }
}