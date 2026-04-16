import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:medisync_app/features/appointment/data/repository/appointment_repository.dart';
import 'package:medisync_app/features/appointment/presentation/bloc/appointment_cubit.dart';
import 'package:medisync_app/features/auth/data/repository/auth_repository.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/auth/presentation/pages/login_screen.dart';
import 'package:medisync_app/features/auth/presentation/pages/register_screen.dart';
import 'package:medisync_app/features/dashboard/data/repository/doctor_repository.dart';
import 'package:medisync_app/features/dashboard/data/repository/hospital_repository.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/doctor_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/bloc/hospital_cubit.dart';
import 'package:medisync_app/features/dashboard/presentation/pages/doctor_dashboard.dart';
import 'package:medisync_app/features/dashboard/presentation/pages/hospital_dashboard.dart';
import 'package:medisync_app/features/dashboard/presentation/pages/user_dashboard.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:medisync_app/features/ehr/data/repository/ehr_repository.dart';
import 'package:medisync_app/features/ehr/presentation/bloc/ehr_cubit.dart';
import 'package:medisync_app/features/lab_report/data/repository/lab_report_repository.dart';
import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_cubit.dart';
import 'package:medisync_app/features/notification/data/repository/notification_repository.dart';
import 'package:medisync_app/features/notification/presentation/bloc/notification_cubit.dart';
import 'package:medisync_app/global/constants/app_constants.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

// ── Entry point ───────────────────────────────────────────────────────────────
// FIX: TokenStorage is created once here and passed down, so it is never
// re-instantiated on a widget rebuild.  Any async initialisation (e.g.
// FlutterSecureStorage warm-up) can be awaited here before runApp, keeping
// the main thread free during the first frame.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(
    widgetsBinding: WidgetsBinding.instance,
  );

  await dotenv.load(fileName: ".env");

  // Create (and optionally await-initialise) TokenStorage before the widget
  // tree is built.
  final tokenStorage = TokenStorage();
  // If TokenStorage exposes an async init method, call it here:
  // await tokenStorage.init();

  FlutterNativeSplash.remove();

  runApp(MediSyncApp(tokenStorage: tokenStorage));
}

// ── Root application widget ───────────────────────────────────────────────────
class MediSyncApp extends StatelessWidget {
  // FIX: Accept the pre-built TokenStorage so build() never creates objects.
  final TokenStorage tokenStorage;

  const MediSyncApp({super.key, required this.tokenStorage});

  @override
  Widget build(BuildContext context) {
    // tokenStorage is a final field — safe to reference here without creating
    // a new instance on every rebuild.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            AuthRepository(),
            tokenStorage: tokenStorage,
          )..checkSession(),
        ),
        BlocProvider(
          create: (_) => HospitalCubit(HospitalRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) => DoctorCubit(DoctorRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) =>
              AppointmentCubit(AppointmentRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) => EHRCubit(EHRRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) => LabReportCubit(LabReportRepository()),
        ),
        BlocProvider(
          create: (_) => NotificationCubit(
            NotificationRepository(storage: tokenStorage),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MediSync 360',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const _SplashRouter(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/dashboard/user': (_) => const UserDashboard(),
          '/dashboard/doctor': (_) => const DoctorDashboard(),
          '/dashboard/hospital': (_) => const HospitalDashboard(),
          '/dashboard/admin': (_) => const _AdminPlaceholder(),
        },
      ),
    );
  }
}

// ── Splash / Auth Router ──────────────────────────────────────────────────────
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(child: LoadingWidget()),
          );
        }

        if (state is AuthSuccess) return _dashboardFor(state.user.role);
        if (state is AuthPendingApproval) return const _PendingApprovalScreen();

        // AuthLoggedOut | AuthUnauthenticated | any other state → login
        return const LoginScreen();
      },
    );
  }

  Widget _dashboardFor(String role) {
    switch (role) {
      case 'doctor':
        return const DoctorDashboard();
      case 'hospital':
        return const HospitalDashboard();
      case 'admin':
        return const _AdminPlaceholder();
      default:
        return const UserDashboard();
    }
  }
}

// ── Pending Approval ──────────────────────────────────────────────────────────
class _PendingApprovalScreen extends StatelessWidget {
  const _PendingApprovalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: AppRadius.xl,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 48,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('Awaiting Approval',
                  style: AppTextStyles.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Your account is under review by our admin team.\n'
                'You will be notified once approved.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton(
                // FIX: Only call logout(); _SplashRouter's BlocBuilder handles
                // the navigation when AuthLoggedOut is emitted — no manual
                // Navigator call needed here.
                onPressed: () => context.read<AuthCubit>().logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin Placeholder (embedded web panel) ────────────────────────────────────
class _AdminPlaceholder extends StatefulWidget {
  const _AdminPlaceholder();

  @override
  State<_AdminPlaceholder> createState() => _AdminPlaceholderState();
}

class _AdminPlaceholderState extends State<_AdminPlaceholder> {
  InAppWebViewController? _webViewController;

  // FIX: Guard against an empty/malformed adminBase URL so WebUri never
  // throws on a bad string.
  bool get _hasValidUrl =>
      AppConstants.adminBase.isNotEmpty &&
      Uri.tryParse(AppConstants.adminBase) != null;

  Future<void> _handleBack() async {
    if (_webViewController != null) {
      final canGoBack = await _webViewController!.canGoBack();
      if (canGoBack) {
        await _webViewController!.goBack();
        return;
      }
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // FIX: BlocListener lets the admin screen react to logout just like every
    // other screen, pushing /login when AuthLoggedOut / AuthUnauthenticated is
    // emitted.
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthLoggedOut || state is AuthUnauthenticated) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          await _handleBack();
        },
        child: Scaffold(
          body: SafeArea(
            child: _hasValidUrl
                ? InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(AppConstants.adminBase),
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                  )
                : const Center(
                    // FIX: Show a friendly error instead of crashing when
                    // adminBase is empty or misconfigured.
                    child: Text(
                      'Admin panel URL is not configured.\n'
                      'Please check AppConstants.adminBase.',
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
