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
            const _HospitalOverviewTab(),
            const _CapacityManagementTab(),
            BlocProvider(
              create: (_) => SosCubit(SosRepository(), TokenStorage()),
              child: const HospitalSosScreen(),
            ),
            const _DepartmentsTab(),
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

// ─── Custom bottom nav ────────────────────────────────────────────────────────

class _HospitalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _HospitalBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // (filledIcon, outlinedIcon, label, isSOS)
    const items = [
      (Icons.dashboard_rounded, Icons.dashboard_outlined, 'Overview', false),
      (Icons.bed_rounded, Icons.bed_outlined, 'Capacity', false),
      (Icons.emergency_rounded, Icons.emergency_rounded, 'SOS', true),
      (
        Icons.account_tree_rounded,
        Icons.account_tree_outlined,
        'Departments',
        false
      ),
      (Icons.person_rounded, Icons.person_outlined, 'Account', false),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == currentIndex;
              final isSos = item.$4;
              final accent = isSos ? AppColors.error : AppColors.hospitalRole;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? accent.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: AppRadius.full,
                        ),
                        child: Icon(
                          selected ? item.$1 : item.$2,
                          color:
                              (selected || isSos) ? accent : AppColors.textHint,
                          size: (selected && isSos) ? 26 : 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: AppTextStyles.caption.copyWith(
                          color: selected ? accent : AppColors.textHint,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 10,
                        ),
                        child: Text(item.$3),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
      backgroundColor: AppColors.background,
      appBar: MediSyncAppBar(
        title: 'Dashboard',
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen())),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppColors.error, shape: BoxShape.circle),
                ),
              ),
            ],
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
              onButtonTap: () => context.read<HospitalCubit>().loadMyHospital(),
            );
          }
          if (state is MyHospitalLoaded) {
            final h = state.hospital;
            return RefreshIndicator(
              onRefresh: () => context.read<HospitalCubit>().loadMyHospital(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeBanner(
                      hospitalName: h.name,
                      userName: user?.fullName ?? '',
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Live Capacity'),
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
                          const _SectionLabel('Bed Occupancy'),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: AppRadius.lg,
                              boxShadow: AppShadows.card,
                            ),
                            child: Column(children: [
                              CapacityBar(
                                  label: 'General Beds',
                                  available: h.availableBeds,
                                  total: h.totalBeds),
                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.md),
                              CapacityBar(
                                  label: 'ICU',
                                  available: h.icuAvailable,
                                  total: h.icuTotal),
                              const SizedBox(height: AppSpacing.md),
                              const Divider(height: 1),
                              const SizedBox(height: AppSpacing.md),
                              CapacityBar(
                                  label: 'Emergency',
                                  available: h.emergencyAvailable,
                                  total: h.emergencyBeds),
                            ]),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ],
                ),
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

// ─── Welcome banner ───────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String hospitalName;
  final String userName;

  const _WelcomeBanner({required this.hospitalName, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF047857),
            AppColors.hospitalRole,
            Color(0xFF10B981),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back 👋',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              const SizedBox(height: 2),
              Text(hospitalName,
                  style: AppTextStyles.titleLarge
                      .copyWith(color: Colors.white, height: 1.2),
                  maxLines: 2),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: AppRadius.full,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.manage_accounts_rounded,
                      color: Colors.white70, size: 12),
                  const SizedBox(width: 4),
                  Text('Managed by $userName',
                      style: AppTextStyles.caption
                          .copyWith(color: Colors.white70)),
                ]),
              ),
            ],
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
          ),
          child: Center(
            child: Text(
              hospitalName.isNotEmpty ? hospitalName[0].toUpperCase() : 'H',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 18,
          decoration: const BoxDecoration(
              color: AppColors.hospitalRole, borderRadius: AppRadius.full),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTextStyles.headlineMedium),
      ]);
}

// ─── Capacity Management Tab ──────────────────────────────────────────────────

class _CapacityManagementTab extends StatefulWidget {
  const _CapacityManagementTab();

  @override
  State<_CapacityManagementTab> createState() => _CapacityManagementTabState();
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
      backgroundColor: AppColors.background,
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: AppRadius.md,
                      border:
                          Border.all(color: AppColors.primary.withOpacity(0.2)),
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

                  // Fields grouped in a card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.lg,
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CapacityField(
                          label: 'General Beds',
                          hint: 'Available general beds',
                          icon: Icons.bed_rounded,
                          iconColor: AppColors.accent,
                          controller: _bedsCtrl,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                        _CapacityField(
                          label: 'ICU Beds',
                          hint: 'Available ICU beds',
                          icon: Icons.monitor_heart_rounded,
                          iconColor: AppColors.error,
                          controller: _icuCtrl,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Divider(height: 1),
                        const SizedBox(height: AppSpacing.md),
                        _CapacityField(
                          label: 'Emergency Beds',
                          hint: 'Available emergency beds',
                          icon: Icons.local_hospital_rounded,
                          iconColor: AppColors.warning,
                          controller: _emergencyCtrl,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.hospitalRole,
                      minimumSize: const Size(double.infinity, 52),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.md),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Update Capacity',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
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

class _CapacityField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;

  const _CapacityField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), borderRadius: AppRadius.sm),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTextStyles.labelLarge),
      ]),
      const SizedBox(height: AppSpacing.xs),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: hint),
        validator: (v) => v == null || v.isEmpty
            ? 'Required'
            : int.tryParse(v) == null
                ? 'Enter a number'
                : null,
      ),
    ]);
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
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final hospitalName = user?.hospitalProfile?.hospitalName ?? '';
    final initials =
        hospitalName.isNotEmpty ? hospitalName[0].toUpperCase() : 'H';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        title: const Text('Account',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Hero
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.hospitalRole,
                      AppColors.hospitalRole.withOpacity(0.5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.hospitalRole.withOpacity(0.12),
                  child: Text(initials,
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.hospitalRole)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                hospitalName.isNotEmpty ? hospitalName : user?.fullName ?? '',
                style: AppTextStyles.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.hospitalRole, Color(0xFF10B981)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: AppRadius.full,
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Hospital',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3)),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: AppSpacing.sm),

          _sectionLabel('Manage'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lg,
                boxShadow: AppShadows.card),
            child: Column(children: [
              _ProfileMenuItem(
                icon: Icons.edit_rounded,
                label: 'Edit Profile',
                color: AppColors.primary,
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _ProfileMenuItem(
                icon: Icons.history_rounded,
                label: 'Capacity History',
                color: AppColors.accent,
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              _ProfileMenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                color: AppColors.warning,
                onTap: () {},
              ),
            ]),
          ),

          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: OutlinedButton.icon(
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textHint),
        ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), borderRadius: AppRadius.sm),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 18),
        onTap: onTap,
      );
}
