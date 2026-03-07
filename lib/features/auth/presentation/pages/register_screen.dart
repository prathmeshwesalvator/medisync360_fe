import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medisync_app/features/auth/data/models/auth_model.dart';
import 'package:medisync_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:medisync_app/features/auth/presentation/widgets/auth_header.dart';
import 'package:medisync_app/features/auth/presentation/widgets/role_selector.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import 'package:medisync_app/global/validators/validator.dart';
import 'package:medisync_app/global/widgets/app_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Role
  String _selectedRole = UserRole.user;

  // Common
  final _emailCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Doctor
  final _specializationCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();

  // Hospital
  final _hospitalNameCtrl = TextEditingController();
  final _regNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _totalBedsCtrl = TextEditingController();
  final _icuBedsCtrl = TextEditingController();
  final _hospitalPhoneCtrl = TextEditingController();

  // ── BUG 2 FIX: coordinates declared but never stored — added these two fields
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _specializationCtrl.dispose();
    _qualificationCtrl.dispose();
    _experienceCtrl.dispose();
    _licenseCtrl.dispose();
    _hospitalNameCtrl.dispose();
    _regNumberCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _totalBedsCtrl.dispose();
    _icuBedsCtrl.dispose();
    _hospitalPhoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();

    switch (_selectedRole) {
      case UserRole.user:
        cubit.registerUser(
          email: _emailCtrl.text.trim(),
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          confirmPassword: _confirmPasswordCtrl.text,
        );
        break;

      case UserRole.doctor:
        cubit.registerDoctor(
          email: _emailCtrl.text.trim(),
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          confirmPassword: _confirmPasswordCtrl.text,
          doctorProfile: DoctorProfile(
            specialization: _specializationCtrl.text.trim(),
            qualification: _qualificationCtrl.text.trim(),
            experienceYears: int.tryParse(_experienceCtrl.text) ?? 0,
            licenseNumber: _licenseCtrl.text.trim(),
          ),
        );
        break;

      case UserRole.hospital:
        // ── BUG 3 FIX: latitude/longitude were never passed to registerHospital
        cubit.registerHospital(
          email: _emailCtrl.text.trim(),
          fullName: _fullNameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          confirmPassword: _confirmPasswordCtrl.text,
          latitude: _latitude ?? 0.0, // ← was missing entirely
          longitude: _longitude ?? 0.0, // ← was missing entirely
          hospitalProfile: HospitalProfile(
            hospitalName: _hospitalNameCtrl.text.trim(),
            registrationNumber: _regNumberCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            state: _stateCtrl.text.trim(),
            pincode: _pincodeCtrl.text.trim(),
            totalBeds: int.tryParse(_totalBedsCtrl.text) ?? 0,
            icuBeds: int.tryParse(_icuBedsCtrl.text) ?? 0,
            phone: _hospitalPhoneCtrl.text.trim(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _routeToDashboard(context, state.user.role);
          } else if (state is AuthPendingApproval) {
            _showPendingDialog(context, state.message);
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
                    const SizedBox(height: AppSpacing.md),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const AuthHeaderWidget(
                      title: 'Create account',
                      subtitle:
                          'Join MediSync 360 — choose your role to get started',
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Role Selector
                    const Text('I am a', style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    RoleSelectorWidget(
                      selectedRole: _selectedRole,
                      onRoleChanged: (role) =>
                          setState(() => _selectedRole = role),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Common Fields ────────────────────────────────────────
                    const _SectionHeader(title: 'Basic Information'),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Full name',
                      hint: 'John Doe',
                      controller: _fullNameCtrl,
                      prefixIcon:
                          const Icon(Icons.person_outline_rounded, size: 18),
                      validator: (v) =>
                          Validators.required(v, field: 'Full name'),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Email address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined, size: 18),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Phone number',
                      hint: '+91 98765 43210',
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Password',
                      hint: 'Min. 8 characters',
                      controller: _passwordCtrl,
                      isPassword: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 18),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    AppTextField(
                      label: 'Confirm password',
                      hint: '••••••••',
                      controller: _confirmPasswordCtrl,
                      isPassword: true,
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded, size: 18),
                      textInputAction: _selectedRole == UserRole.user
                          ? TextInputAction.done
                          : TextInputAction.next,
                      validator: Validators.confirmPassword(
                        () => _passwordCtrl.text,
                      ),
                    ),

                    // ── Doctor Fields ────────────────────────────────────────
                    if (_selectedRole == UserRole.doctor) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(
                        title: 'Professional Details',
                        subtitle: 'Required for verification',
                        iconData: Icons.medical_services_rounded,
                        iconColor: AppColors.doctorRole,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Specialization',
                        hint: 'e.g. Cardiologist',
                        controller: _specializationCtrl,
                        prefixIcon:
                            const Icon(Icons.psychology_outlined, size: 18),
                        validator: (v) =>
                            Validators.required(v, field: 'Specialization'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Qualification',
                        hint: 'e.g. MBBS, MD (Cardiology)',
                        controller: _qualificationCtrl,
                        prefixIcon: const Icon(Icons.school_outlined, size: 18),
                        validator: (v) =>
                            Validators.required(v, field: 'Qualification'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Experience (years)',
                              hint: '5',
                              controller: _experienceCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.positiveNumber(v,
                                  field: 'Experience'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              label: 'License number',
                              hint: 'MCI-XXXXXX',
                              controller: _licenseCtrl,
                              validator: Validators.licenseNumber,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // ── Hospital Fields ──────────────────────────────────────
                    if (_selectedRole == UserRole.hospital) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(
                        title: 'Hospital Information',
                        subtitle: 'Required for admin verification',
                        iconData: Icons.local_hospital_rounded,
                        iconColor: AppColors.hospitalRole,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Hospital name',
                        hint: 'Apollo Hospitals',
                        controller: _hospitalNameCtrl,
                        validator: (v) =>
                            Validators.required(v, field: 'Hospital name'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Registration number',
                        hint: 'HRP-XXXXXXXX',
                        controller: _regNumberCtrl,
                        validator: (v) => Validators.required(v,
                            field: 'Registration number'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        label: 'Full address',
                        hint: '123, Street Name, Area',
                        controller: _addressCtrl,
                        maxLines: 2,
                        validator: (v) =>
                            Validators.required(v, field: 'Address'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'City',
                              hint: 'Mumbai',
                              controller: _cityCtrl,
                              validator: (v) =>
                                  Validators.required(v, field: 'City'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              label: 'State',
                              hint: 'Maharashtra',
                              controller: _stateCtrl,
                              validator: (v) =>
                                  Validators.required(v, field: 'State'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Pincode',
                              hint: '400001',
                              controller: _pincodeCtrl,
                              keyboardType: TextInputType.number,
                              validator: Validators.pincode,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              label: 'Hospital phone',
                              hint: '+91 22 XXXX XXXX',
                              controller: _hospitalPhoneCtrl,
                              keyboardType: TextInputType.phone,
                              validator: (v) =>
                                  Validators.required(v, field: 'Phone'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Total beds',
                              hint: '200',
                              controller: _totalBedsCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.positiveNumber(v,
                                  field: 'Total beds'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              label: 'ICU beds',
                              hint: '20',
                              controller: _icuBedsCtrl,
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.positiveNumber(v,
                                  field: 'ICU beds'),
                            ),
                          ),
                        ],
                      ),

                      // ── BUG 4 FIX: HospitalLocationPicker was defined at bottom
                      // but never placed inside the hospital fields section in the UI
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(
                        title: 'Hospital Location',
                        subtitle: 'For map visibility',
                        iconData: Icons.location_on_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      HospitalLocationPicker(
                        onLocationSelected: (lat, lon) {
                          _latitude = lat;
                          _longitude = lon;
                        },
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    _SubmitButton(
                      role: _selectedRole,
                      isLoading: isLoading,
                      onPressed: _submit,
                    ),

                    if (_selectedRole != UserRole.user) ...[
                      const SizedBox(height: AppSpacing.md),
                      _ApprovalNotice(role: _selectedRole),
                    ],

                    const SizedBox(height: AppSpacing.lg),

                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: AppTextStyles.bodyMedium,
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Sign in',
                                  style: AppTextStyles.labelLarge
                                      .copyWith(color: AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
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
      default:
        Navigator.pushReplacementNamed(context, '/user-dashboard');
    }
  }

  void _showPendingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lg),
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pending_actions_rounded,
            color: AppColors.warning,
            size: 36,
          ),
        ),
        title: const Text('Registration Submitted'),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? iconData;
  final Color? iconColor;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.iconData,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (iconData != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor!.withOpacity(0.1),
              borderRadius: AppRadius.sm,
            ),
            child: Icon(iconData, color: iconColor, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headlineMedium),
            if (subtitle != null) Text(subtitle!, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String role;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.role,
    required this.isLoading,
    required this.onPressed,
  });

  String get _label {
    switch (role) {
      case UserRole.doctor:
        return 'Submit Doctor Application';
      case UserRole.hospital:
        return 'Submit Hospital Application';
      default:
        return 'Create Account';
    }
  }

  Color get _color {
    switch (role) {
      case UserRole.doctor:
        return AppColors.doctorRole;
      case UserRole.hospital:
        return AppColors.hospitalRole;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _color,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(
                _label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

class _ApprovalNotice extends StatelessWidget {
  final String role;

  const _ApprovalNotice({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.08),
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              role == UserRole.doctor
                  ? 'Doctor accounts require admin approval before you can log in.'
                  : 'Hospital accounts require admin verification before activation.',
              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hospital Location Picker ─────────────────────────────────────────────────

class HospitalLocationPicker extends StatefulWidget {
  final void Function(double lat, double lon) onLocationSelected;

  const HospitalLocationPicker({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<HospitalLocationPicker> createState() => _HospitalLocationPickerState();
}

class _HospitalLocationPickerState extends State<HospitalLocationPicker> {
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  bool _detecting = false;
  String? _status;

  Future<void> _detect() async {
    setState(() {
      _detecting = true;
      _status = null;
    });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() {
          _detecting = false;
          _status = 'Location permission denied. Enter manually.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _latCtrl.text = pos.latitude.toStringAsFixed(7);
      _lonCtrl.text = pos.longitude.toStringAsFixed(7);
      widget.onLocationSelected(pos.latitude, pos.longitude);
      setState(() {
        _detecting = false;
        _status = '✓ Location detected';
      });
    } catch (_) {
      setState(() {
        _detecting = false;
        _status = 'Could not detect location. Enter manually.';
      });
    }
  }

  void _onManualChange() {
    final lat = double.tryParse(_latCtrl.text);
    final lon = double.tryParse(_lonCtrl.text);
    if (lat != null && lon != null) {
      widget.onLocationSelected(lat, lon);
    }
  }

  @override
  void dispose() {
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hospital Location',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        const Text(
          'Required for map view. Tap "Detect" or enter coordinates manually.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _detecting ? null : _detect,
            icon: _detecting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location_rounded, size: 16),
            label: Text(_detecting
                ? 'Detecting location…'
                : 'Auto-detect Hospital Location'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        if (_status != null) ...[
          const SizedBox(height: 6),
          Text(
            _status!,
            style: TextStyle(
              fontSize: 12,
              color:
                  _status!.startsWith('✓') ? AppColors.accent : AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: 'e.g. 19.0760',
                  prefixIcon: Icon(Icons.straighten_rounded, size: 16),
                ),
                onChanged: (_) => _onManualChange(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _lonCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: 'e.g. 72.8777',
                  prefixIcon: Icon(Icons.straighten_rounded, size: 16),
                ),
                onChanged: (_) => _onManualChange(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
