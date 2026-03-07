import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/dashboard/data/repository/hospital_repository.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/hospital_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/hospital_list_screen.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/medisync_appbar.dart';
import 'package:medisync_app/features/appointment/presentation/pages/appointment_list_screen.dart';
import 'package:medisync_app/features/ehr/presentation/pages/ehr_screen.dart';
import 'package:medisync_app/features/notification/presentation/screens/notification_screen.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0 — Home
          _UserHomeTab(user: user, onTabChange: _setTab),

          // Tab 1 — Hospitals
          BlocProvider(
            create: (_) => HospitalCubit(HospitalRepository(), TokenStorage()),
            child: const HospitalListScreen(),
          ),

          // Tab 2 — Appointments ✅ FIXED (was commented out)
          const AppointmentListScreen(),

          // Tab 3 — Records (EHR)
          const EHRScreen(),

          // Tab 4 — Profile
          const _ProfileTab(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: _setTab,
        items: const [
          _NavItem(icon: Icons.home_rounded, label: 'Home'),
          _NavItem(icon: Icons.local_hospital_rounded, label: 'Hospitals'),
          _NavItem(icon: Icons.calendar_today_rounded, label: 'Appointments'),
          _NavItem(icon: Icons.folder_open_rounded, label: 'Records'),
          _NavItem(icon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  void _setTab(int i) => setState(() => _currentIndex = i);
}

// ─── Home Tab ─────────────────────────────────────────────────────────────────
class _UserHomeTab extends StatelessWidget {
  final UserModel? user;
  final ValueChanged<int> onTabChange;

  const _UserHomeTab({this.user, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MediSyncAppBar(
        title: 'MediSync 360',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GreetingCard(user: user),
            const SizedBox(height: AppSpacing.lg),
            const Text('Quick Actions', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                _QuickAction(
                  icon: Icons.local_hospital_rounded,
                  label: 'Find Hospital',
                  color: AppColors.hospitalRole,
                  onTap: () => onTabChange(1),
                ),
                _QuickAction(
                  icon: Icons.calendar_today_rounded,
                  label: 'Appointments',
                  color: AppColors.primary,
                  onTap: () => onTabChange(2),
                ),
                _QuickAction(
                  icon: Icons.folder_open_rounded,
                  label: 'My Records',
                  color: AppColors.accent,
                  onTap: () => onTabChange(3),
                ),
                _QuickAction(
                  icon: Icons.sos_rounded,
                  label: 'SOS Alert',
                  color: AppColors.error,
                  onTap: () {/* TODO: SOS */},
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Upcoming Appointments',
                style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            _UpcomingPlaceholder(onBook: () => onTabChange(2)),
          ],
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final UserModel? user;
  const _GreetingCard({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName.split(' ').first ?? 'User';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFF3B82F6)],
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
              Text('$greeting,',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
              Text(name,
                  style: AppTextStyles.displayMedium
                      .copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text('How are you feeling today?',
                  style:
                      AppTextStyles.bodyMedium.copyWith(color: Colors.white70)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.health_and_safety_rounded,
              color: Colors.white, size: 32),
        ),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppRadius.sm,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Text(label, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPlaceholder extends StatelessWidget {
  final VoidCallback onBook;
  const _UpcomingPlaceholder({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBook,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(children: [
          Icon(Icons.calendar_today_outlined,
              color: AppColors.textHint, size: 36),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No upcoming appointments',
                    style: AppTextStyles.labelLarge),
                Text('Tap to book your first appointment',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ]),
      ),
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;

    return Scaffold(
      appBar: const MediSyncAppBar(title: 'My Profile'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(user?.fullName ?? '', style: AppTextStyles.titleLarge),
              Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: AppRadius.full,
                ),
                child: Text('Patient',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileMenuItem(
            icon: Icons.folder_open_rounded,
            label: 'My Medical Records',
            onTap: () {
              final state =
                  context.findAncestorStateOfType<_UserDashboardState>();
              state?.setState(() => state._currentIndex = 3);
            },
          ),
          _ProfileMenuItem(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          _ProfileMenuItem(
            icon: Icons.lock_outline_rounded,
            label: 'Change Password',
            onTap: () {},
          ),
          _ProfileMenuItem(
            icon: Icons.help_outline_rounded,
            label: 'Help & Support',
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

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
            color: AppColors.inputFill, borderRadius: AppRadius.sm),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      onTap: onTap,
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon,
                          color:
                              selected ? AppColors.primary : AppColors.textHint,
                          size: 22),
                      const SizedBox(height: 3),
                      Text(item.label,
                          style: AppTextStyles.caption.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            fontSize: 10,
                          )),
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
