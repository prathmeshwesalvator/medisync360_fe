import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/hospital_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/capacity_bar.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/empty_state.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/medisync_appbar.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:medisync_app/features/notification/presentation/screens/notification_screen.dart';
import 'package:medisync_app/features/sos/data/repository/sos_repository.dart';
import 'package:medisync_app/features/sos/presentation/bloc/sos_cubit.dart';
import 'package:medisync_app/features/sos/presentation/pages/hospital_sos_screen.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class HospitalDashboard extends StatefulWidget {
  const HospitalDashboard({super.key});

  @override
  State<HospitalDashboard> createState() => _HospitalDashboardState();
}

class _HospitalDashboardState extends State<HospitalDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // BlocListener at top level handles logout navigation cleanly
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut || state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 0 — Overview
            const _HospitalOverviewTab(),

            // Tab 1 — Capacity
            const _CapacityManagementTab(),

            // Tab 2 — SOS Alerts (scoped BlocProvider)
            BlocProvider(
              create: (_) => SosCubit(SosRepository(), TokenStorage()),
              child: const HospitalSosScreen(),
            ),

            // Tab 3 — Departments
            const _DepartmentsTab(),

            // Tab 4 — Account
            const _HospitalProfileTab(),
          ],
        ),
        bottomNavigationBar: _HospitalBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _HospitalOverviewTab extends StatefulWidget {
  const _HospitalOverviewTab();

  @override
  State<_HospitalOverviewTab> createState() => _HospitalOverviewTabState();
}

class _HospitalOverviewTabState extends State<_HospitalOverviewTab> {
  @override
  void initState() {
    super.initState();
    context.read<HospitalCubit>().loadMyHospital();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;

    return Scaffold(
      appBar: MediSyncAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
        ],
      ),
      body: BlocBuilder<HospitalCubit, HospitalState>(
        builder: (context, state) {
          if (state is HospitalLoading) {
            return const LoadingWidget(message: 'Loading your hospital…');
          }
          if (state is HospitalError) {
            return EmptyStateWidget(
              title: 'Error',
              subtitle: state.message,
              icon: Icons.error_outline_rounded,
              buttonLabel: 'Retry',
              onButtonTap: () =>
                  context.read<HospitalCubit>().loadMyHospital(),
            );
          }
          if (state is MyHospitalLoaded) {
            final h = state.hospital;
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<HospitalCubit>().loadMyHospital(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _WelcomeCard(
                    hospitalName: h.name,
                    userName: user?.fullName ?? '',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const Text('Live Capacity',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: AppSpacing.md),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: [
                      StatCard(
                        label: 'Available Beds',
                        value: '${h.availableBeds}',
                        subtitle: 'of ${h.totalBeds} total',
                        icon: Icons.bed_rounded,
                        color: h.hasAvailableBeds
                            ? AppColors.accent
                            : AppColors.error,
                      ),
                      StatCard(
                        label: 'ICU Available',
                        value: '${h.icuAvailable}',
                        subtitle: 'of ${h.icuTotal} total',
                        icon: Icons.monitor_heart_rounded,
                        color: h.hasAvailableICU
                            ? AppColors.accent
                            : AppColors.error,
                      ),
                      StatCard(
                        label: 'Emergency',
                        value: '${h.emergencyAvailable}',
                        subtitle: 'of ${h.emergencyBeds} total',
                        icon: Icons.local_hospital_rounded,
                        color: AppColors.warning,
                      ),
                      StatCard(
                        label: 'Occupancy',
                        value: '${h.bedOccupancyPercent}%',
                        subtitle: 'Bed occupancy rate',
                        icon: Icons.analytics_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const Text('Bed Occupancy',
                      style: AppTextStyles.headlineMedium),
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
                            label: 'ICU',
                            available: h.icuAvailable,
                            total: h.icuTotal),
                        const SizedBox(height: AppSpacing.md),
                        CapacityBar(
                            label: 'Emergency',
                            available: h.emergencyAvailable,
                            total: h.emergencyBeds),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const EmptyStateWidget(
            title: 'No hospital profile',
            subtitle:
                'Your hospital profile has not been created yet. Contact your admin.',
            icon: Icons.local_hospital_outlined,
          );
        },
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String hospitalName;
  final String userName;

  const _WelcomeCard(
      {required this.hospitalName, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.hospitalRole, Color(0xFF10B981)],
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
              Text('Welcome back,',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white70)),
              Text(hospitalName,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: Colors.white),
                  maxLines: 2),
              const SizedBox(height: 2),
              Text('Managed by $userName',
                  style: AppTextStyles.caption
                      .copyWith(color: Colors.white70)),
            ],
          ),
        ),
        const Icon(Icons.local_hospital_rounded,
            color: Colors.white54, size: 48),
      ]),
    );
  }
}

// ─── Capacity Management Tab ──────────────────────────────────────────────────

class _CapacityManagementTab extends StatefulWidget {
  const _CapacityManagementTab();

  @override
  State<_CapacityManagementTab> createState() =>
      _CapacityManagementTabState();
}

class _CapacityManagementTabState extends State<_CapacityManagementTab> {
  final _formKey = GlobalKey<FormState>();
  final _bedsCtrl = TextEditingController();
  final _icuCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();

  @override
  void dispose() {
    _bedsCtrl.dispose();
    _icuCtrl.dispose();
    _emergencyCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<HospitalCubit>().updateCapacity(
          availableBeds: int.parse(_bedsCtrl.text),
          icuAvailable: int.parse(_icuCtrl.text),
          emergencyAvailable: int.parse(_emergencyCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MediSyncAppBar(title: 'Update Capacity'),
      body: BlocConsumer<HospitalCubit, HospitalState>(
        listener: (context, state) {
          if (state is CapacityUpdated) {
            _bedsCtrl.clear();
            _icuCtrl.clear();
            _emergencyCtrl.clear();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(
                content: Text('✓ Capacity updated successfully!'),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
              ));
          }
          if (state is HospitalError) {
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
          final isLoading = state is HospitalLoading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.md,
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Update the current number of available beds. This is visible to patients in real time.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const Text('General Beds',
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _bedsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Available general beds',
                      prefixIcon: Icon(Icons.bed_rounded, size: 18),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required'
                        : int.tryParse(v) == null
                            ? 'Enter a number'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  const Text('ICU Beds', style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _icuCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Available ICU beds',
                      prefixIcon:
                          Icon(Icons.monitor_heart_rounded, size: 18),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required'
                        : int.tryParse(v) == null
                            ? 'Enter a number'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  const Text('Emergency Beds',
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _emergencyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Available emergency beds',
                      prefixIcon:
                          Icon(Icons.local_hospital_rounded, size: 18),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Required'
                        : int.tryParse(v) == null
                            ? 'Enter a number'
                            : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.hospitalRole),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Update Capacity'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Departments Tab ──────────────────────────────────────────────────────────

class _DepartmentsTab extends StatelessWidget {
  const _DepartmentsTab();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: EmptyStateWidget(
        title: 'Departments',
        subtitle: 'Department management coming soon',
        icon: Icons.account_tree_rounded,
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────

class _HospitalProfileTab extends StatelessWidget {
  const _HospitalProfileTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MediSyncAppBar(title: 'Account'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const _ProfileMenuItem(
              icon: Icons.edit_rounded, label: 'Edit Profile'),
          const _ProfileMenuItem(
              icon: Icons.history_rounded, label: 'Capacity History'),
          const _ProfileMenuItem(
              icon: Icons.lock_outline_rounded, label: 'Change Password'),
          const SizedBox(height: AppSpacing.md),
          // Logout — only calls logout(); BlocListener at dashboard level
          // handles navigation to /login
          OutlinedButton.icon(
            onPressed: () => context.read<AuthCubit>().logout(),
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: AppRadius.sm,
        ),
        child: Icon(icon, size: 18, color: AppColors.hospitalRole),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: () {},
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _HospitalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HospitalBottomNav(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.hospitalRole,
      unselectedItemColor: AppColors.textHint,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded), label: 'Overview'),
        BottomNavigationBarItem(
            icon: Icon(Icons.bed_rounded), label: 'Capacity'),
        // SOS tab with red emergency icon
        BottomNavigationBarItem(
          icon: Icon(Icons.emergency_rounded, color: AppColors.error),
          activeIcon:
              Icon(Icons.emergency_rounded, color: AppColors.error, size: 28),
          label: 'SOS',
        ),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_tree_rounded), label: 'Departments'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded), label: 'Account'),
      ],
    );
  }
}