import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medisync_app/features/sos/data/model/sos_model.dart';
import 'package:medisync_app/features/sos/presentation/bloc/sos_cubit.dart';
import 'package:medisync_app/global/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hospital dashboard tab showing active SOS alerts nearby.
/// Auto-refreshes every 10 seconds.
class HospitalSosScreen extends StatefulWidget {
  const HospitalSosScreen({super.key});

  @override
  State<HospitalSosScreen> createState() => _HospitalSosScreenState();
}

class _HospitalSosScreenState extends State<HospitalSosScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    context.read<SosCubit>().loadActiveAlerts();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) context.read<SosCubit>().loadActiveAlerts();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SOS Alerts',
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<SosCubit>().loadActiveAlerts(),
          ),
        ],
      ),
      body: BlocConsumer<SosCubit, SosState>(
        listener: (context, state) {
          if (state is SosActionSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text('✓ ${state.message}'),
                backgroundColor: AppColors.accent,
                behavior: SnackBarBehavior.floating,
              ));
            context.read<SosCubit>().loadActiveAlerts();
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
          if (state is SosLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.error));
          }
          if (state is SosActiveAlertsLoaded) {
            if (state.alerts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.health_and_safety_outlined,
                        size: 64,
                        color: AppColors.accent.withOpacity(0.4)),
                    const SizedBox(height: AppSpacing.md),
                    const Text('No active SOS alerts nearby',
                        style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    const Text('All clear in your area.',
                        style: AppTextStyles.bodyMedium),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<SosCubit>().loadActiveAlerts(),
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: state.alerts.length,
                itemBuilder: (_, i) => _SosAlertCard(
                  sos: state.alerts[i],
                  onRespond: () =>
                      _showRespondSheet(context, state.alerts[i]),
                  onView: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<SosCubit>(),
                        child: HospitalSosDetailScreen(sos: state.alerts[i]),
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

  void _showRespondSheet(BuildContext context, SosAlertModel sos) {
    final etaCtrl = TextEditingController(text: '15');
    final ambCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.divider, borderRadius: AppRadius.full),
          ),
          Text('Respond to SOS #${sos.id}',
              style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Text('Patient: ${sos.patientName}',
              style: AppTextStyles.bodyMedium),
          if (sos.distanceKm != null)
            Text('Distance: ${sos.distanceKm!.toStringAsFixed(1)} km',
                style: AppTextStyles.caption.copyWith(color: AppColors.error)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: etaCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'ETA (minutes)',
              prefixIcon: Icon(Icons.timer_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: ambCtrl,
            decoration: const InputDecoration(
              labelText: 'Ambulance Number (optional)',
              prefixIcon: Icon(Icons.local_shipping_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final eta = int.tryParse(etaCtrl.text) ?? 15;
              context.read<SosCubit>().respondToSos(
                    sosId: sos.id,
                    etaMinutes: eta,
                    ambulanceNumber: ambCtrl.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            icon: const Icon(Icons.local_shipping_rounded),
            label: const Text('Accept & Dispatch Ambulance'),
          ),
        ]),
      ),
    );
  }
}

// ─── Hospital SOS detail — manage en-route, arrived, resolve ─────────────────

class HospitalSosDetailScreen extends StatefulWidget {
  final SosAlertModel sos;
  const HospitalSosDetailScreen({super.key, required this.sos});

  @override
  State<HospitalSosDetailScreen> createState() =>
      _HospitalSosDetailScreenState();
}

class _HospitalSosDetailScreenState extends State<HospitalSosDetailScreen> {
  late SosAlertModel _sos;

  @override
  void initState() {
    super.initState();
    _sos = widget.sos;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SosCubit, SosState>(
      listener: (context, state) {
        if (state is SosActionSuccess) {
          setState(() => _sos = state.sos);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('✓ ${state.message}'),
              backgroundColor: AppColors.accent,
              behavior: SnackBarBehavior.floating,
            ));
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
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('SOS #${_sos.id}',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: AppColors.surface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // ── Status + severity ─────────────────────────────────────
            _InfoCard(
              title: 'Status',
              child: Row(children: [
                _SeverityBadge(severity: _sos.severity),
                const SizedBox(width: 8),
                _StatusBadge(status: _sos.status),
              ]),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Patient info ──────────────────────────────────────────
            _InfoCard(
              title: 'Patient',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _Row(Icons.person_rounded, _sos.patientName),
                if (_sos.patientPhone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () =>
                        launchUrl(Uri.parse('tel:${_sos.patientPhone}')),
                    child: _Row(Icons.phone_rounded, _sos.patientPhone,
                        color: AppColors.primary),
                  ),
                ],
                if (_sos.bloodGroup.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _Row(Icons.bloodtype_rounded,
                      'Blood Group: ${_sos.bloodGroup}'),
                ],
                if (_sos.allergies.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _Row(Icons.warning_amber_rounded,
                      'Allergies: ${_sos.allergies}',
                      color: AppColors.warning),
                ],
                if (_sos.medications.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _Row(Icons.medication_rounded,
                      'Medications: ${_sos.medications}'),
                ],
                if (_sos.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_sos.description,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontStyle: FontStyle.italic)),
                ],
              ]),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Emergency contact ─────────────────────────────────────
            if (_sos.emergencyContactName.isNotEmpty)
              _InfoCard(
                title: 'Emergency Contact',
                child: GestureDetector(
                  onTap: () => launchUrl(
                      Uri.parse('tel:${_sos.emergencyContactPhone}')),
                  child: _Row(
                      Icons.contact_phone_rounded,
                      '${_sos.emergencyContactName} — ${_sos.emergencyContactPhone}',
                      color: AppColors.primary),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),

            // ── Map ───────────────────────────────────────────────────
            if (_sos.latitude != 0)
              ClipRRect(
                borderRadius: AppRadius.lg,
                child: SizedBox(
                  height: 220,
                  child: FlutterMap(
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
                        Marker(
                          point: LatLng(_sos.latitude, _sos.longitude),
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.person_pin_circle_rounded,
                              color: AppColors.error, size: 44),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),

            // ── Directions ────────────────────────────────────────────
            if (_sos.latitude != 0)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final url =
                        'https://www.google.com/maps/dir/?api=1&destination=${_sos.latitude},${_sos.longitude}&travelmode=driving';
                    launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Open Directions in Maps'),
                ),
              ),
            const SizedBox(height: AppSpacing.md),

            // ── Action buttons ────────────────────────────────────────
            if (_sos.status == SosStatus.accepted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<SosCubit>().markEnroute(_sos.id),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('Mark En Route'),
                ),
              ),
            if (_sos.status == SosStatus.enroute)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<SosCubit>().markArrived(_sos.id),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent),
                  icon: const Icon(Icons.where_to_vote_rounded),
                  label: const Text('Mark Arrived'),
                ),
              ),
            if (_sos.status == SosStatus.arrived) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.read<SosCubit>().resolveSos(_sos.id),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Mark Resolved'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
          ]),
        ),
      ),
    );
  }
}

// ─── Alert card for the list ──────────────────────────────────────────────────

class _SosAlertCard extends StatelessWidget {
  final SosAlertModel sos;
  final VoidCallback onRespond;
  final VoidCallback onView;
  const _SosAlertCard(
      {required this.sos, required this.onRespond, required this.onView});

  Color get _severityColor {
    switch (sos.severity) {
      case SosSeverity.critical: return AppColors.error;
      case SosSeverity.high:     return AppColors.warning;
      default:                   return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
        border: Border(left: BorderSide(color: _severityColor, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.emergency_rounded, color: _severityColor, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text('SOS #${sos.id} — ${sos.patientName}',
                  style: AppTextStyles.titleLarge),
            ),
            _SeverityBadge(severity: sos.severity),
          ]),
          const SizedBox(height: 4),
          if (sos.description.isNotEmpty)
            Text(sos.description,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            if (sos.distanceKm != null)
              Text('${sos.distanceKm!.toStringAsFixed(1)} km away',
                  style: AppTextStyles.caption),
            const Spacer(),
            const Icon(Icons.access_time_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(
              sos.createdAt.length > 16
                  ? sos.createdAt.substring(11, 16)
                  : sos.createdAt,
              style: AppTextStyles.caption,
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onView,
                child: const Text('View Details'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onRespond,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error),
                icon: const Icon(Icons.local_shipping_rounded, size: 16),
                label: const Text('Respond'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lg,
            boxShadow: AppShadows.card),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ]),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _Row(this.icon, this.text, {this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodyMedium.copyWith(color: color)),
        ),
      ]);
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  Color get _color {
    switch (severity) {
      case SosSeverity.critical: return AppColors.error;
      case SosSeverity.high:     return AppColors.warning;
      default:                   return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _color.withOpacity(0.1),
            borderRadius: AppRadius.full),
        child: Text(severity.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: _color, fontWeight: FontWeight.w700, fontSize: 9)),
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case SosStatus.active:   return AppColors.error;
      case SosStatus.accepted: return AppColors.warning;
      case SosStatus.enroute:  return AppColors.primary;
      case SosStatus.arrived:  return AppColors.accent;
      default:                 return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: _color.withOpacity(0.1),
            borderRadius: AppRadius.full),
        child: Text(status.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: _color, fontWeight: FontWeight.w700, fontSize: 9)),
      );
}