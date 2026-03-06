import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
import 'package:medisync_app/features/ehr/data/repository/ehr_repository.dart';
import 'package:medisync_app/features/ehr/presentation/bloc/ehr_cubit.dart';
import 'package:medisync_app/features/lab_report/data/repository/lab_report_repository.dart';
import 'package:medisync_app/features/lab_report/presentation/bloc/lab_report_cubit.dart';
import 'package:medisync_app/features/notification/data/repository/notification_repository.dart';
import 'package:medisync_app/features/notification/presentation/bloc/notification_cubit.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MediSyncApp());
}

class MediSyncApp extends StatelessWidget {
  const MediSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Single shared instance passed to every cubit that needs it
    final tokenStorage = TokenStorage();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(
            AuthRepository(),
            tokenStorage: tokenStorage,
          )..checkSession(),
        ),
        BlocProvider(
          create: (_) =>
              HospitalCubit(HospitalRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) =>
              DoctorCubit(DoctorRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) =>
              AppointmentCubit(AppointmentRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) =>
              EHRCubit(EHRRepository(), tokenStorage),
        ),
        BlocProvider(
          create: (_) => LabReportCubit(
            LabReportRepository(storage: tokenStorage),
          ),
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
          '/login':              (_) => const LoginScreen(),
          '/register':           (_) => const RegisterScreen(),
          '/dashboard/user':     (_) => const UserDashboard(),
          '/dashboard/doctor':   (_) => const DoctorDashboard(),
          '/dashboard/hospital': (_) => const HospitalDashboard(),
          '/dashboard/admin':    (_) => const _AdminPlaceholder(),
        },
      ),
    );
  }
}

// ── Splash / Auth Router ───────────────────────────────────────────────────────
class _SplashRouter extends StatelessWidget {
  const _SplashRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            backgroundColor: AppColors.primary,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }
        if (state is AuthSuccess)         return _dashboardFor(state.user.role);
        if (state is AuthPendingApproval) return const _PendingApprovalScreen();
        return const LoginScreen();
      },
    );
  }

  Widget _dashboardFor(String role) {
    switch (role) {
      case 'doctor':   return const DoctorDashboard();
      case 'hospital': return const HospitalDashboard();
      case 'admin':    return const _AdminPlaceholder();
      default:         return const UserDashboard();
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
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: AppRadius.xl,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 48, color: AppColors.warning),
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



// ── Admin Placeholder ─────────────────────────────────────────────────────────

class _AdminPlaceholder extends StatefulWidget {
  const _AdminPlaceholder({super.key});

  @override
  State<_AdminPlaceholder> createState() => _AdminPlaceholderState();
}

class _AdminPlaceholderState extends State<_AdminPlaceholder> {
  InAppWebViewController? webViewController;

  Future<void> handleBack() async {
    if (webViewController != null) {
      bool canGoBack = await webViewController!.canGoBack();

      if (canGoBack) {
        await webViewController!.goBack();
        return;
      }
    }

    // No web history -> close app
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await handleBack();
      },
      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri("http://10.28.164.173:8000/admin/"),
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
          ),
        ),
      ),
    );
  }
}
