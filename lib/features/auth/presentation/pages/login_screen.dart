import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/auth/presentation/widgets/auth_header.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import 'package:medisync_app/global/validators/validator.dart';
import 'package:medisync_app/global/widgets/app_textfield.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthCubit>().login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _routeToDashboard(context, state.user.role);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    const AuthHeaderWidget(
                      title: 'Welcome back',
                      subtitle: 'Sign in to your MediSync account',
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Email
                    AppTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passwordCtrl,
                      isPassword: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 18),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password is required'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Login Button
                    _PrimaryButton(
                      label: 'Sign in',
                      isLoading: isLoading,
                      color: AppColors.primary,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.lg),

                    // Register CTA
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: AppTextStyles.bodyMedium,
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/register'),
                                child: Text(
                                  'Create one',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _routeToDashboard(BuildContext context, String role) {
    switch (role) {
      case UserRole.doctor:
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
        break;
      case UserRole.hospital:
        Navigator.pushReplacementNamed(context, '/hospital-dashboard');
        break;
      case UserRole.admin:
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/user-dashboard');
    }
  }
}

// ─── Shared widgets (also used by RegisterScreen) ─────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('or', style: AppTextStyles.caption),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
