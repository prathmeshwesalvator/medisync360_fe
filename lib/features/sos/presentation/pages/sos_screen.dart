import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:medisync_app/features/sos/data/model/sos_model.dart';
import 'package:medisync_app/features/sos/data/repository/sos_repository.dart';
import 'package:medisync_app/features/sos/presentation/bloc/sos_cubit.dart';
import 'package:medisync_app/global/storage/token_storage.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Entry point — launched from user_dashboard SOS button.
/// Creates a SosCubit, gets GPS, and pushes the SOS flow screen.
class SosLauncher extends StatelessWidget {
  const SosLauncher({super.key});

  /// Used when the caller already provides a SosCubit via BlocProvider.
  static Widget buildFlow(BuildContext context) => const _SosFlowScreen();

  static Future<void> launch(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BlocProvider(
        create: (_) => SosCubit(SosRepository(), TokenStorage()),
        child: const _SosFlowScreen(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── Flow screen: manages state transitions ───────────────────────────────────

class _SosFlowScreen extends StatefulWidget {
  const _SosFlowScreen();

  @override
  State<_SosFlowScreen> createState() => _SosFlowScreenState();
}

class _SosFlowScreenState extends State<_SosFlowScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SosCubit, SosState>(
      listener: (context, state) {
        if (state is SosCancelled) {
          Navigator.of(context).pop();
        }
        if (state is SosError) {
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
        if (state is SosInitial || state is SosLoading) {
          return const _SosTriggerScreen();
        }
        if (state is SosTriggered || state is SosDetailLoaded) {
          final sos = state is SosTriggered
              ? (state as SosTriggered).sos
              : (state as SosDetailLoaded).sos;
          return _SosActiveScreen(sos: sos);
        }
        return const _SosTriggerScreen();
      },
    );
  }
}

// ─── Trigger screen — confirm + optional medical info ─────────────────────────

class _SosTriggerScreen extends StatefulWidget {
  const _SosTriggerScreen();

  @override
  State<_SosTriggerScreen> createState() => _SosTriggerScreenState();
}

class _SosTriggerScreenState extends State<_SosTriggerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  String _severity = 'high';
  final _descCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _ecNameCtrl = TextEditingController();
  final _ecPhoneCtrl = TextEditingController();
  bool _showMedInfo = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Lock to portrait for SOS
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _descCtrl.dispose();
    _bloodCtrl.dispose();
    _allergiesCtrl.dispose();
    _medicationsCtrl.dispose();
    _ecNameCtrl.dispose();
    _ecPhoneCtrl.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  Future<void> _sendSOS() async {
    setState(() => _locating = true);
    HapticFeedback.heavyImpact();

    double lat = 0, lon = 0;
    String address = '';
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (svcEnabled && perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } catch (_) { /* continue with 0,0 */ }

    setState(() => _locating = false);

    if (!mounted) return;
    context.read<SosCubit>().triggerSos(
          latitude: lat,
          longitude: lon,
          address: address,
          severity: _severity,
          description: _descCtrl.text.trim(),
          bloodGroup: _bloodCtrl.text.trim(),
          allergies: _allergiesCtrl.text.trim(),
          medications: _medicationsCtrl.text.trim(),
          emergencyContactName: _ecNameCtrl.text.trim(),
          emergencyContactPhone: _ecPhoneCtrl.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<SosCubit>().state is SosLoading || _locating;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Emergency SOS',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(children: [
          const SizedBox(height: AppSpacing.lg),

          // ── Pulsing SOS button ────────────────────────────────────────
          Center(
            child: ScaleTransition(
              scale: _pulseAnim,
              child: GestureDetector(
                onTap: loading ? null : _sendSOS,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.6),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: loading
                        ? const CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sos_rounded,
                                  size: 64, color: Colors.white),
                              SizedBox(height: 4),
                              Text('SEND SOS',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2)),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          const Text(
            'Tap to alert nearby hospitals.\nAn ambulance will be dispatched.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Severity selector ─────────────────────────────────────────
          _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Severity',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: AppSpacing.sm),
                Row(children: [
                  _SeverityChip(
                    label: '🔴 Critical',
                    value: 'critical',
                    selected: _severity == 'critical',
                    onTap: () => setState(() => _severity = 'critical'),
                  ),
                  const SizedBox(width: 8),
                  _SeverityChip(
                    label: '🟠 High',
                    value: 'high',
                    selected: _severity == 'high',
                    onTap: () => setState(() => _severity = 'high'),
                  ),
                  const SizedBox(width: 8),
                  _SeverityChip(
                    label: '🟡 Medium',
                    value: 'medium',
                    selected: _severity == 'medium',
                    onTap: () => setState(() => _severity = 'medium'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Description ───────────────────────────────────────────────
          _DarkCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What happened?',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: _darkInputDecoration(
                      'e.g. Chest pain, accident, difficulty breathing'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Medical info (collapsible) ────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _showMedInfo = !_showMedInfo),
            child: _DarkCard(
              child: Row(children: [
                const Icon(Icons.medical_information_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Add Medical Info (optional)',
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600)),
                ),
                Icon(
                  _showMedInfo
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.white54,
                ),
              ]),
            ),
          ),
          if (_showMedInfo) ...[
            const SizedBox(height: AppSpacing.xs),
            _DarkCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _darkField(_bloodCtrl, 'Blood Group', 'e.g. B+'),
                const SizedBox(height: AppSpacing.sm),
                _darkField(_allergiesCtrl, 'Allergies', 'e.g. Penicillin'),
                const SizedBox(height: AppSpacing.sm),
                _darkField(_medicationsCtrl, 'Current Medications',
                    'e.g. Metformin 500mg'),
                const SizedBox(height: AppSpacing.sm),
                _darkField(
                    _ecNameCtrl, 'Emergency Contact Name', 'Full name'),
                const SizedBox(height: AppSpacing.sm),
                _darkField(_ecPhoneCtrl, 'Emergency Contact Phone',
                    '+91 9999999999',
                    keyboardType: TextInputType.phone),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),

          // ── Emergency call button ────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse('tel:112')),
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            label: const Text('Call 112 (Emergency)',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white30),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ]),
      ),
    );
  }

  Widget _darkField(TextEditingController ctrl, String label, String hint,
      {TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _darkInputDecoration(hint),
      ),
    ]);
  }

  InputDecoration _darkInputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: Colors.white12),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadius.md,
          borderSide: BorderSide(color: AppColors.error),
        ),
      );
}

// ─── Active SOS screen — status tracker + ambulance map ──────────────────────

class _SosActiveScreen extends StatefulWidget {
  final SosAlertModel sos;
  const _SosActiveScreen({required this.sos});

  @override
  State<_SosActiveScreen> createState() => _SosActiveScreenState();
}

class _SosActiveScreenState extends State<_SosActiveScreen> {
  late SosAlertModel _sos;
  final MapController _mapCtrl = MapController();

  @override
  void initState() {
    super.initState();
    _sos = widget.sos;
    HapticFeedback.heavyImpact();
  }

  @override
  void didUpdateWidget(_SosActiveScreen old) {
    super.didUpdateWidget(old);
    if (widget.sos != old.sos) {
      setState(() => _sos = widget.sos);
      if (_sos.hasAmbulanceLocation) {
        _mapCtrl.move(
          LatLng(_sos.ambulanceLatitude!, _sos.ambulanceLongitude!),
          15,
        );
      }
    }
  }

  Color get _statusColor {
    switch (_sos.status) {
      case SosStatus.active:   return AppColors.error;
      case SosStatus.accepted: return AppColors.warning;
      case SosStatus.enroute:  return const Color(0xFF3B82F6);
      case SosStatus.arrived:  return AppColors.accent;
      default:                 return AppColors.textSecondary;
    }
  }

  String get _statusMessage {
    switch (_sos.status) {
      case SosStatus.active:
        return 'Waiting for hospital to respond…';
      case SosStatus.accepted:
        return '${_sos.respondingHospitalName ?? "Hospital"} accepted!\n'
            'Ambulance #${_sos.ambulanceNumber} — ETA ${_sos.etaMinutes} min';
      case SosStatus.enroute:
        return 'Ambulance is on the way!\nETA: ${_sos.etaMinutes} min';
      case SosStatus.arrived:
        return 'Ambulance has arrived!';
      default:
        return _sos.status.toUpperCase();
    }
  }

  IconData get _statusIcon {
    switch (_sos.status) {
      case SosStatus.active:   return Icons.emergency_rounded;
      case SosStatus.accepted: return Icons.check_circle_rounded;
      case SosStatus.enroute:  return Icons.local_shipping_rounded;
      case SosStatus.arrived:  return Icons.where_to_vote_rounded;
      default:                 return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SosCubit, SosState>(
      listener: (context, state) {
        if (state is SosDetailLoaded) setState(() => _sos = state.sos);
        if (state is SosActionSuccess) setState(() => _sos = state.sos);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text('SOS Active',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          actions: [
            if (_sos.isLive)
              TextButton.icon(
                onPressed: () => _confirmCancel(context),
                icon: const Icon(Icons.cancel_outlined,
                    color: Colors.white54, size: 18),
                label: const Text('Cancel SOS',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(children: [
            // ── Status banner ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: AppRadius.lg,
                border: Border.all(color: _statusColor.withOpacity(0.4)),
              ),
              child: Row(children: [
                Icon(_statusIcon, color: _statusColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.5),
                  ),
                ),
                if (_sos.isActive)
                  _PulsingDot(color: _statusColor),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Progress stepper ──────────────────────────────────────
            _SosProgressStepper(status: _sos.status),
            const SizedBox(height: AppSpacing.md),

            // ── Map ───────────────────────────────────────────────────
            if (_sos.latitude != 0 || _sos.longitude != 0) ...[
              ClipRRect(
                borderRadius: AppRadius.lg,
                child: SizedBox(
                  height: 280,
                  child: FlutterMap(
                    mapController: _mapCtrl,
                    options: MapOptions(
                      initialCenter: LatLng(_sos.latitude, _sos.longitude),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.medisync.app',
                      ),
                      MarkerLayer(markers: [
                        // Patient location
                        Marker(
                          point: LatLng(_sos.latitude, _sos.longitude),
                          width: 48,
                          height: 48,
                          child: const _MapPin(
                            icon: Icons.person_pin_circle_rounded,
                            color: AppColors.error,
                            label: 'You',
                          ),
                        ),
                        // Ambulance location
                        if (_sos.hasAmbulanceLocation)
                          Marker(
                            point: LatLng(_sos.ambulanceLatitude!,
                                _sos.ambulanceLongitude!),
                            width: 52,
                            height: 52,
                            child: const _MapPin(
                              icon: Icons.local_shipping_rounded,
                              color: Color(0xFF3B82F6),
                              label: 'Amb',
                            ),
                          ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // ── Hospital info ─────────────────────────────────────────
            if (_sos.respondingHospitalName != null)
              _DarkCard(
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.hospitalRole.withOpacity(0.15),
                      borderRadius: AppRadius.md,
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: AppColors.hospitalRole, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Responding Hospital',
                          style: TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                      Text(
                        _sos.respondingHospitalName!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      if (_sos.ambulanceNumber.isNotEmpty)
                        Text('Ambulance #${_sos.ambulanceNumber}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12)),
                    ]),
                  ),
                  if (_sos.etaMinutes != null)
                    Column(children: [
                      Text('${_sos.etaMinutes}',
                          style: TextStyle(
                              color: _statusColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w800)),
                      const Text('min',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ]),
                ]),
              ),
            const SizedBox(height: AppSpacing.sm),

            // ── Emergency contacts / quick call ───────────────────────
            Row(children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_rounded,
                  label: 'Call 112',
                  color: AppColors.error,
                  onTap: () => launchUrl(Uri.parse('tel:112')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_location_rounded,
                  label: 'Share Location',
                  color: AppColors.primary,
                  onTap: () => _shareLocation(),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),

            if (_sos.emergencyContactPhone.isNotEmpty)
              _ActionButton(
                icon: Icons.contact_phone_rounded,
                label: 'Call ${_sos.emergencyContactName.isNotEmpty ? _sos.emergencyContactName : "Emergency Contact"}',
                color: AppColors.warning,
                onTap: () =>
                    launchUrl(Uri.parse('tel:${_sos.emergencyContactPhone}')),
              ),
            const SizedBox(height: AppSpacing.md),

            // ── Status log ────────────────────────────────────────────
            if (_sos.statusLogs.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Timeline',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DarkCard(
                child: Column(
                  children: _sos.statusLogs
                      .map((l) => _LogRow(log: l))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }

  void _shareLocation() {
    final url =
        'https://maps.google.com/?q=${_sos.latitude},${_sos.longitude}';
    launchUrl(Uri.parse(url));
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Cancel SOS?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
            'Are you sure? This will notify the hospital that you no longer need help.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, keep SOS',
                style: TextStyle(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SosCubit>().cancelSos(_sos.id);
            },
            child: const Text('Yes, cancel',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─── Progress stepper ────────────────────────────────────────────────────────

class _SosProgressStepper extends StatelessWidget {
  final String status;
  const _SosProgressStepper({required this.status});

  static const _steps = [
    (SosStatus.active, 'Sent', Icons.sos_rounded),
    (SosStatus.accepted, 'Accepted', Icons.check_rounded),
    (SosStatus.enroute, 'En Route', Icons.local_shipping_rounded),
    (SosStatus.arrived, 'Arrived', Icons.where_to_vote_rounded),
  ];

  int get _currentIndex {
    switch (status) {
      case SosStatus.active:   return 0;
      case SosStatus.accepted: return 1;
      case SosStatus.enroute:  return 2;
      case SosStatus.arrived:  return 3;
      default:                 return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: AppRadius.lg,
      ),
      child: Row(
        children: _steps.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          final done = i <= idx;
          final active = i == idx;
          return Expanded(
            child: Row(children: [
              Column(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? (active ? AppColors.error : AppColors.accent)
                        : const Color(0xFF2A2A2A),
                    border: active
                        ? Border.all(color: AppColors.error, width: 2)
                        : null,
                  ),
                  child: Icon(step.$3,
                      size: 18,
                      color: done ? Colors.white : Colors.white24),
                ),
                const SizedBox(height: 4),
                Text(step.$2,
                    style: TextStyle(
                        color: done ? Colors.white : Colors.white30,
                        fontSize: 9,
                        fontWeight: FontWeight.w600)),
              ]),
              if (i < _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < idx ? AppColors.accent : const Color(0xFF2A2A2A),
                  ),
                ),
            ]),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Small widgets ────────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: AppRadius.lg,
          border: Border.all(color: Colors.white12),
        ),
        child: child,
      );
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _SeverityChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppColors.error.withOpacity(0.2) : Colors.transparent,
              border: Border.all(
                  color: selected ? AppColors.error : Colors.white24),
              borderRadius: AppRadius.md,
            ),
            child: Center(
                child: Text(label,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w600))),
          ),
        ),
      );
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1).animate(_c),
        child: Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
              color: widget.color, shape: BoxShape.circle),
        ),
      );
}

class _MapPin extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MapPin(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
                color: color, borderRadius: AppRadius.sm),
            child: Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: AppRadius.md,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      );
}

class _LogRow extends StatelessWidget {
  final SosStatusLogModel log;
  const _LogRow({required this.log});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                log.fromStatus.isNotEmpty
                    ? '${log.fromStatus} → ${log.toStatus}'
                    : log.toStatus,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              if (log.note.isNotEmpty)
                Text(log.note,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
            ]),
          ),
          Text(
            log.changedAt.length > 10
                ? log.changedAt.substring(11, 16)
                : log.changedAt,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ]),
      );
}