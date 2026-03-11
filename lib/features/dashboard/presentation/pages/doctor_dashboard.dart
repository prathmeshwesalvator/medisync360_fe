import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/appointment/presentation/pages/appointment_details_screen.dart';
import 'package:medisync_app/features/appointment/presentation/widgets/appointment_card.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/medisync_appbar.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:medisync_app/features/notification/presentation/screens/notification_screen.dart';
import 'package:medisync_app/global/theme/app_theme.dart';


class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DoctorHomeTab(),
          _DoctorAppointmentsTab(),
          _DoctorProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.doctorRole,
        unselectedItemColor: AppColors.textHint,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded), label: 'Appointments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────
class _DoctorHomeTab extends StatefulWidget {
  const _DoctorHomeTab();

  @override
  State<_DoctorHomeTab> createState() => _DoctorHomeTabState();
}

class _DoctorHomeTabState extends State<_DoctorHomeTab> {
  @override
  void initState() {
    super.initState();
    // Load today's appointments on home tab
    context.read<AppointmentCubit>().loadDoctorAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final name = user?.fullName.split(' ').first ?? 'Doctor';
    final profile = user?.doctorProfile;

    return Scaffold(
      appBar: MediSyncAppBar(
        title: 'MediSync 360',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<AppointmentCubit>().loadDoctorAppointments(),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Welcome banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.doctorRole, Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.lg,
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, Dr. $name',
                            style: AppTextStyles.titleLarge
                                .copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          profile?.specialization ?? '',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white70),
                        ),
                      ]),
                ),
                const Icon(Icons.medical_services_rounded,
                    color: Colors.white30, size: 48),
              ]),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Today's stats
            BlocBuilder<AppointmentCubit, AppointmentState>(
              builder: (context, state) {
                final appts = state is AppointmentListLoaded
                    ? state.appointments
                    : <dynamic>[];
                final pending =
                    appts.where((a) => a.status == 'pending').length;
                final confirmed =
                    appts.where((a) => a.status == 'confirmed').length;
                final completed =
                    appts.where((a) => a.status == 'completed').length;

                return Column(children: [
                  const Text("Today's Overview", style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        label: 'Total Today',
                        value: '${appts.length}',
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.doctorRole,
                      ),
                      StatCard(
                        label: 'Pending',
                        value: '$pending',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        label: 'Confirmed',
                        value: '$confirmed',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.accent,
                      ),
                      StatCard(
                        label: 'Completed',
                        value: '$completed',
                        icon: Icons.task_alt_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ]);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Today's schedule
            const Text("Today's Schedule", style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),

            BlocBuilder<AppointmentCubit, AppointmentState>(
              builder: (context, state) {
                if (state is AppointmentLoading) {
                  return const LoadingWidget();
                }
                if (state is AppointmentListLoaded) {
                  if (state.appointments.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No appointments today',
                      subtitle: 'Your schedule is clear',
                      icon: Icons.event_available_rounded,
                    );
                  }
                  return Column(
                    children: state.appointments
                        .take(5)
                        .map((a) => AppointmentCard(
                              appointment: a,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<AppointmentCubit>(),
                                    child:
                                        AppointmentDetailScreen(appointment: a),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  );
                }
                return const EmptyStateWidget(
                  title: 'No appointments today',
                  subtitle: 'Your schedule is clear',
                  icon: Icons.event_available_rounded,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Appointments Tab ──────────────────────────────────────────────────────────
class _DoctorAppointmentsTab extends StatefulWidget {
  const _DoctorAppointmentsTab();

  @override
  State<_DoctorAppointmentsTab> createState() => _DoctorAppointmentsTabState();
}

class _DoctorAppointmentsTabState extends State<_DoctorAppointmentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _date = '';

  static const _tabs = [
    ('All', ''),
    ('Pending', 'pending'),
    ('Confirmed', 'confirmed'),
    ('Completed', 'completed'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    context.read<AppointmentCubit>().loadDoctorAppointments();
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
        title: const Text('Appointments',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: _pickDate,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.doctorRole,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.doctorRole,
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
          onTap: (i) => context
              .read<AppointmentCubit>()
              .loadDoctorAppointments(status: _tabs[i].$2, date: _date),
        ),
      ),
      body: BlocBuilder<AppointmentCubit, AppointmentState>(
        builder: (context, state) {
          if (state is AppointmentLoading) return const LoadingWidget();

          if (state is AppointmentError) {
            return EmptyStateWidget(
              title: 'Could not load',
              subtitle: state.message,
              icon: Icons.calendar_today_rounded,
              buttonLabel: 'Retry',
              onButtonTap: () =>
                  context.read<AppointmentCubit>().loadDoctorAppointments(),
            );
          }

          if (state is AppointmentListLoaded) {
            if (state.appointments.isEmpty) {
              return const EmptyStateWidget(
                title: 'No appointments',
                subtitle: 'No appointments for this filter',
                icon: Icons.calendar_today_rounded,
              );
            }
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<AppointmentCubit>().loadDoctorAppointments(),
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (d != null) {
      setState(() => _date =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      context.read<AppointmentCubit>().loadDoctorAppointments(date: _date);
    }
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────
class _DoctorProfileTab extends StatelessWidget {
  const _DoctorProfileTab();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final profile = user?.doctorProfile;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Avatar
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.doctorRole.withOpacity(0.15),
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'D',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: AppColors.doctorRole),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Dr. ${user?.fullName ?? ''}',
                  style: AppTextStyles.titleLarge),
              if (profile?.specialization != null)
                Text(profile!.specialization,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              Text(user?.email ?? '', style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.doctorRole.withOpacity(0.1),
                  borderRadius: AppRadius.full,
                ),
                child: Text('Doctor',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.doctorRole,
                        fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Profile details
          if (profile != null) ...[
            _ProfileCard(children: [
              _InfoRow('Specialization', profile.specialization),
              _InfoRow('Qualification', profile.qualification),
              _InfoRow('Experience', '${profile.experienceYears} years'),
              _InfoRow('License No.', profile.licenseNumber),
              _InfoRow('Consultation Fee',
                  '₹${profile.consultationFee.toStringAsFixed(0)}'),
            ]),
            const SizedBox(height: AppSpacing.md),
          ],

          // Actions
          _ProfileMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            color: AppColors.doctorRole,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          _ProfileMenuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            color: AppColors.doctorRole,
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final List<Widget> children;
  const _ProfileCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            boxShadow: AppShadows.card),
        child: Column(
          children:
              children.expand((w) => [w, const Divider(height: 1)]).toList()
                ..removeLast(),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: AppTextStyles.caption
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary)),
          ),
        ]),
      );
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: AppRadius.sm),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing:
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        onTap: onTap,
      );
}
