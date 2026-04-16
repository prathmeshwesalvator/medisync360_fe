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
import 'package:medisync_app/features/lab_report/presentation/pages/upload_lab_report_screen.dart';
import 'package:medisync_app/features/notification/presentation/screens/notification_screen.dart';
import 'package:medisync_app/features/sos/data/repository/sos_repository.dart';
import 'package:medisync_app/features/sos/presentation/bloc/sos_cubit.dart';
import 'package:medisync_app/features/sos/presentation/pages/sos_screen.dart';
import 'package:medisync_app/features/x-ray_analyzer/analyzer_page.dart';
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
            _UserHomeTab(user: user, onTabChange: _setTab),
            BlocProvider(
              create: (_) =>
                  HospitalCubit(HospitalRepository(), TokenStorage()),
              child: const HospitalListScreen(),
            ),
            const AppointmentListScreen(),
            const EHRScreen(),
            const _ProfileTab(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: _setTab,
          items: const [
            _NavItem(
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: 'Home'),
            _NavItem(
                icon: Icons.local_hospital_rounded,
                outlinedIcon: Icons.local_hospital_outlined,
                label: 'Hospitals'),
            _NavItem(
                icon: Icons.calendar_today_rounded,
                outlinedIcon: Icons.calendar_today_outlined,
                label: 'Appointments'),
            _NavItem(
                icon: Icons.folder_rounded,
                outlinedIcon: Icons.folder_outlined,
                label: 'Records'),
            _NavItem(
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outlined,
                label: 'Profile'),
          ],
        ),
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
      backgroundColor: AppColors.background,
      appBar: MediSyncAppBar(
        title: 'MediSync 360',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-bleed greeting card
            _GreetingCard(user: user),

            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Quick Actions'),
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
                      _SOSQuickAction(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _SectionLabel('Upcoming Appointments'),
                  const SizedBox(height: AppSpacing.md),
                  _UpcomingPlaceholder(onBook: () => onTabChange(2)),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label with accent bar ───────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 3,
          height: 18,
          decoration: const BoxDecoration(
              color: AppColors.primary, borderRadius: AppRadius.full),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTextStyles.headlineMedium),
      ]);
}

// ─── Greeting card ────────────────────────────────────────────────────────────

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
    final emoji = hour < 12
        ? '☀️'
        : hour < 17
            ? '🌤️'
            : '🌙';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$greeting $emoji',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white70)),
                  const SizedBox(height: 2),
                  Text(name,
                      style: AppTextStyles.displayMedium
                          .copyWith(color: Colors.white, height: 1.1)),
                  const SizedBox(height: 4),
                  Text('How are you feeling today?',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: Colors.white60)),
                ],
              ),
            ),
            // Initials avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.3), width: 1.5),
              ),
              child: Center(
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          // Health tip pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: AppRadius.full,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.health_and_safety_rounded,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text('Stay healthy — drink water & rest well',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Quick action tile ────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: AppRadius.md),
              child: Icon(icon, color: color, size: 22),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 10, color: color.withOpacity(0.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SOS Quick Action ─────────────────────────────────────────────────────────

class _SOSQuickAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _PulsingSOSButton(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BlocProvider(
          create: (_) => SosCubit(SosRepository(), TokenStorage()),
          child: const _SosFlowEntry(),
        ),
      )),
    );
  }
}

class _SosFlowEntry extends StatelessWidget {
  const _SosFlowEntry();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SosCubit, SosState>(
      listener: (context, state) {
        if (state is SosCancelled) Navigator.of(context).pop();
      },
      child: SosLauncher.buildFlow(context),
    );
  }
}

class _PulsingSOSButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingSOSButton({required this.onTap});

  @override
  State<_PulsingSOSButton> createState() => _PulsingSOSButtonState();
}

class _PulsingSOSButtonState extends State<_PulsingSOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.04 + _anim.value * 0.04),
            borderRadius: AppRadius.lg,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.12 + _anim.value * 0.22),
                blurRadius: 14 + _anim.value * 14,
                spreadRadius: _anim.value * 3,
              ),
            ],
            border: Border.all(
              color: AppColors.error.withOpacity(0.25 + _anim.value * 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1 + _anim.value * 0.08),
                  borderRadius: AppRadius.md,
                ),
                child: const Icon(Icons.sos_rounded,
                    color: AppColors.error, size: 22),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('SOS Alert',
                      style: AppTextStyles.labelLarge
                          .copyWith(fontSize: 13, color: AppColors.error)),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: AppColors.error.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Upcoming placeholder ─────────────────────────────────────────────────────

class _UpcomingPlaceholder extends StatelessWidget {
  final VoidCallback onBook;
  const _UpcomingPlaceholder({required this.onBook});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onBook,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lg,
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.card,
        ),
        child: Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, borderRadius: AppRadius.md),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No upcoming appointments',
                    style: AppTextStyles.labelLarge),
                SizedBox(height: 2),
                Text('Tap to book your first appointment',
                    style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, borderRadius: AppRadius.sm),
            child: const Icon(Icons.add_rounded,
                color: AppColors.primary, size: 16),
          ),
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
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const MediSyncAppBar(title: 'My Profile'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Hero section ───────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              // Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(initials,
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(user?.fullName ?? '', style: AppTextStyles.titleLarge),
              const SizedBox(height: 2),
              Text(user?.email ?? '', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              // Gradient role badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF3B82F6)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: AppRadius.full,
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text('Patient',
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

          // ── Health section ─────────────────────────────────────────────
          _MenuSection(title: 'Health', items: [
            _ProfileMenuItem(
              icon: Icons.folder_open_rounded,
              label: 'My Medical Records',
              color: AppColors.accent,
              onTap: () {
                final s =
                    context.findAncestorStateOfType<_UserDashboardState>();
                s?.setState(() => s._currentIndex = 3);
              },
            ),
            _ProfileMenuItem(
              icon: Icons.biotech_rounded,
              label: 'Lab Report Analyzer',
              color: AppColors.doctorRole,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UploadLabReportScreen()),
              ),
            ),
            _ProfileMenuItem(
              icon: Icons.one_x_mobiledata_outlined,
              label: 'X-RAY Analyzer',
              color: AppColors.doctorRole,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const XRayAnalyzerPage()),
              ),
            ),
          ]),

          const SizedBox(height: AppSpacing.sm),

          // ── Account section ────────────────────────────────────────────
          _MenuSection(title: 'Account', items: [
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              color: AppColors.warning,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen())),
            ),
            _ProfileMenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              color: AppColors.primary,
              onTap: () {},
            ),
            _ProfileMenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              color: AppColors.textSecondary,
              onTap: () {},
            ),
          ]),

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
}

// ─── Menu section with card container ────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_ProfileMenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.textHint),
        ),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            boxShadow: AppShadows.card),
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            return Column(children: [
              e.value,
              if (!isLast)
                const Divider(
                    height: 1,
                    indent: AppSpacing.md + 36 + AppSpacing.md,
                    endIndent: 0),
            ]);
          }).toList(),
        ),
      ),
    ]);
  }
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
  Widget build(BuildContext context) {
    return ListTile(
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
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
  });
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _BottomNav(
      {required this.currentIndex, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pill indicator around icon when selected
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: AppRadius.full,
                        ),
                        child: Icon(
                          selected ? item.icon : item.outlinedIcon,
                          color:
                              selected ? AppColors.primary : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: AppTextStyles.caption.copyWith(
                          color:
                              selected ? AppColors.primary : AppColors.textHint,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 10,
                        ),
                        child: Text(item.label),
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
