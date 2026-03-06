import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/appointment/presentation/pages/appointment_details_screen.dart';
import 'package:medisync_app/features/dashboard/data/repository/doctor_repository.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/doctor_list_screen.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import '../widgets/appointment_card.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // (label, status filter)
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
        title: const Text('My Appointments',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Book appointment',
            onPressed: () => _goBook(context),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
          onTap: (i) => context
              .read<AppointmentCubit>()
              .loadMyAppointments(status: _tabs[i].$2),
        ),
      ),
      body: BlocBuilder<AppointmentCubit, AppointmentState>(
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
                title: 'No appointments yet',
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
    );
  }

  void _goBook(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => DoctorCubit(DoctorRepository(), TokenStorage()),
          child: const DoctorListScreen(),
        ),
      ),
    );
  }
}
