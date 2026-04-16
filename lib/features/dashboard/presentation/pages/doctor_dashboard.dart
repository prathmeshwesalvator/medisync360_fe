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
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut || state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            _DoctorHomeTab(),
            _DoctorAppointmentsTab(),
            _DoctorProfileTab(),
          ],
        ),
        bottomNavigationBar: _DoctorBottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ─── Custom bottom nav (matches user dashboard style) ─────────────────────────

class _DoctorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _DoctorBottomNav(
      {required this.currentIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded,          Icons.home_outlined,              'Home'),
    (Icons.calendar_today_rounded, Icons.calendar_today_outlined,   'Appointments'),
    (Icons.person_rounded,         Icons.person_outlined,            'Profile'),
  ];

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
            children: _items.asMap().entries.map((e) {
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.doctorRole.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: AppRadius.full,
                        ),
                        child: Icon(
                          selected ? item.$1 : item.$2,
                          color: selected
                              ? AppColors.doctorRole
                              : AppColors.textHint,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        style: AppTextStyles.caption.copyWith(
                          color: selected
                              ? AppColors.doctorRole
                              : AppColors.textHint,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
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
    context.read<AppointmentCubit>().loadDoctorAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthSuccess ? authState.user : null;
    final name = user?.fullName.split(' ').first ?? 'Doctor';
    final profile = user?.doctorProfile;

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
                onPressed: () => Navigator.push(context,
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
      body: RefreshIndicator(
        onRefresh: () =>
            context.read<AppointmentCubit>().loadDoctorAppointments(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome banner — full bleed ──────────────────────────
              _WelcomeBanner(name: name, profile: profile),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats grid ─────────────────────────────────────
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

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel("Today's Overview"),
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
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ── Schedule ───────────────────────────────────────
                    const _SectionLabel("Today's Schedule"),
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
                                            value: context
                                                .read<AppointmentCubit>(),
                                            child: AppointmentDetailScreen(
                                                appointment: a),
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
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Welcome banner ───────────────────────────────────────────────────────────

class _WelcomeBanner extends StatelessWidget {
  final String name;
  final dynamic profile;
  const _WelcomeBanner({required this.name, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B21B6), AppColors.doctorRole, Color(0xFF7C3AED)],
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
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: Colors.white70)),
              const SizedBox(height: 2),
              Text('Dr. $name',
                  style: AppTextStyles.displayMedium
                      .copyWith(color: Colors.white, height: 1.1)),
              if (profile?.specialization != null &&
                  (profile!.specialization as String).isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: AppRadius.full,
                  ),
                  child: Text(
                    profile!.specialization as String,
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Doctor initials avatar
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
              name.isNotEmpty ? name[0].toUpperCase() : 'D',
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
              color: AppColors.doctorRole, borderRadius: AppRadius.full),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text, style: AppTextStyles.headlineMedium),
      ]);
}

// ── Appointments Tab ──────────────────────────────────────────────────────────

class _DoctorAppointmentsTab extends StatefulWidget {
  const _DoctorAppointmentsTab();

  @override
  State<_DoctorAppointmentsTab> createState() =>
      _DoctorAppointmentsTabState();
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
          // Date filter chip
          if (_date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {
                  setState(() => _date = '');
                  context
                      .read<AppointmentCubit>()
                      .loadDoctorAppointments();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.doctorRole.withOpacity(0.1),
                    borderRadius: AppRadius.full,
                    border: Border.all(
                        color: AppColors.doctorRole.withOpacity(0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_date,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.doctorRole,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 4),
                    const Icon(Icons.close_rounded,
                        size: 12, color: AppColors.doctorRole),
                  ]),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Filter by date',
            onPressed: _pickDate,
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          labelColor: AppColors.doctorRole,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.doctorRole,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.$1)).toList(),
          onTap: (i) => context
              .read<AppointmentCubit>()
              .loadDoctorAppointments(
                  status: _tabs[i].$2, date: _date),
        ),
      ),
      body: BlocConsumer<AppointmentCubit, AppointmentState>(
        listener: (context, state) {
          if (state is AppointmentActionSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('✓ ${state.message}'),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
              ));
            context
                .read<AppointmentCubit>()
                .loadDoctorAppointments(date: _date);
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
              title: 'Could not load',
              subtitle: state.message,
              icon: Icons.calendar_today_rounded,
              buttonLabel: 'Retry',
              onButtonTap: () => context
                  .read<AppointmentCubit>()
                  .loadDoctorAppointments(),
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
              onRefresh: () => context
                  .read<AppointmentCubit>()
                  .loadDoctorAppointments(),
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
      context
          .read<AppointmentCubit>()
          .loadDoctorAppointments(date: _date);
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
    final initials = user?.fullName.isNotEmpty == true
        ? user!.fullName[0].toUpperCase()
        : 'D';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Hero ──────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            child: Column(children: [
              // Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.doctorRole,
                      AppColors.doctorRole.withOpacity(0.5)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      AppColors.doctorRole.withOpacity(0.12),
                  child: Text(initials,
                      style: AppTextStyles.displayMedium
                          .copyWith(color: AppColors.doctorRole)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Dr. ${user?.fullName ?? ''}',
                  style: AppTextStyles.titleLarge),
              const SizedBox(height: 2),
              if (profile?.specialization != null)
                Text(profile!.specialization,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.doctorRole,
                        fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(user?.email ?? '',
                  style: AppTextStyles.caption),
              const SizedBox(height: AppSpacing.sm),
              // Role badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 5),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.doctorRole,
                      Color(0xFF5B21B6)
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: AppRadius.full,
                ),
                child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Doctor',
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

          // ── Professional details ───────────────────────────────────
          if (profile != null) ...[
            _sectionLabel('Professional'),
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.lg,
                  boxShadow: AppShadows.card),
              child: Column(
                children: [
                  _DetailTile(
                      icon: Icons.psychology_rounded,
                      label: 'Specialization',
                      value: profile.specialization,
                      color: AppColors.doctorRole),
                  const Divider(height: 1, indent: 56),
                  _DetailTile(
                      icon: Icons.school_rounded,
                      label: 'Qualification',
                      value: profile.qualification,
                      color: AppColors.primary),
                  const Divider(height: 1, indent: 56),
                  _DetailTile(
                      icon: Icons.work_history_rounded,
                      label: 'Experience',
                      value: '${profile.experienceYears} years',
                      color: AppColors.accent),
                  const Divider(height: 1, indent: 56),
                  _DetailTile(
                      icon: Icons.badge_rounded,
                      label: 'License No.',
                      value: profile.licenseNumber,
                      color: AppColors.warning),
                  const Divider(height: 1, indent: 56),
                  _DetailTile(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Consultation Fee',
                      value:
                          '₹${profile.consultationFee.toStringAsFixed(0)}',
                      color: AppColors.hospitalRole),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // ── Account ────────────────────────────────────────────────
          _sectionLabel('Account'),
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lg,
                boxShadow: AppShadows.card),
            child: Column(children: [
              _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                color: AppColors.warning,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen())),
              ),
              const Divider(height: 1, indent: 56),
              _ProfileMenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                color: AppColors.primary,
                onTap: () {},
              ),
            ]),
          ),

          const SizedBox(height: AppSpacing.md),

          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md),
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

// ─── Detail tile (profile info row with coloured icon) ───────────────────────

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.sm),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600)),
        subtitle: Text(value,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textPrimary)),
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
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: AppRadius.sm),
          child: Icon(icon, size: 18, color: color),
        ),
        title: Text(label, style: AppTextStyles.bodyLarge),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint, size: 18),
        onTap: onTap,
      );
}