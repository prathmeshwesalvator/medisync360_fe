import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medisync_app/features/dashboard/presentation/widgets/loading.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/hospital_model.dart';
import '../bloc/hospital_cubit.dart';
import '../widgets/hospital_details_screen.dart';
import 'package:medisync_app/global/theme/app_theme.dart';

class HospitalMapScreen extends StatefulWidget {
  const HospitalMapScreen({super.key});

  @override
  State<HospitalMapScreen> createState() => _HospitalMapScreenState();
}

class _HospitalMapScreenState extends State<HospitalMapScreen> {
  final MapController _mapController = MapController();

  LatLng? _userLocation;
  HospitalModel? _selectedHospital;
  bool _locating = false;
  bool _mapReady = false;

  // Default center — India
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);
  static const double _defaultZoom = 5.0;
  static const double _hospitalZoom = 14.0;

  @override
  void initState() {
    super.initState();
    context.read<HospitalCubit>().loadHospitalsForMap();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() => _locating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _locating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _userLocation = loc;
        _locating = false;
      });
      if (_mapReady) {
        _mapController.move(loc, 12.0);
      }
    } catch (_) {
      setState(() => _locating = false);
    }
  }

  void _centerOnUser() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, 13.0);
    } else {
      _getUserLocation();
    }
  }

  void _onHospitalTap(HospitalModel hospital) {
    if (hospital.latitude == null || hospital.longitude == null) return;
    setState(() => _selectedHospital = hospital);
    _mapController.move(
      LatLng(hospital.latitude!, hospital.longitude!),
      _hospitalZoom,
    );
  }

  void _dismissPopup() => setState(() => _selectedHospital = null);

  Future<void> _openDirections(HospitalModel h) async {
    final lat = h.latitude!;
    final lon = h.longitude!;

    // Try Google Maps first, fallback to geo: URI
    final googleUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon&travelmode=driving';
    final geoUri =
        Uri.parse('geo:$lat,$lon?q=$lat,$lon(${Uri.encodeComponent(h.name)})');

    if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl),
          mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps application')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<HospitalCubit, HospitalState>(
        builder: (context, state) {
          final hospitals =
              state is HospitalMapLoaded ? state.hospitals : <HospitalModel>[];
          final isLoading = state is HospitalLoading;

          return Stack(
            children: [
              // ── Map ────────────────────────────────────────────────────────
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation ?? _defaultCenter,
                  initialZoom: _userLocation != null ? 12.0 : _defaultZoom,
                  onMapReady: () => setState(() => _mapReady = true),
                  onTap: (_, __) => _dismissPopup(),
                ),
                children: [
                  // Tile layer — OpenStreetMap
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.medisync.app',
                  ),

                  // Hospital markers
                  MarkerLayer(
                    markers: [
                      // User location marker
                      if (_userLocation != null)
                        Marker(
                          point: _userLocation!,
                          width: 44,
                          height: 44,
                          child: _UserMarker(),
                        ),

                      // Hospital markers
                      ...hospitals
                          .where(
                              (h) => h.latitude != null && h.longitude != null)
                          .map((h) => Marker(
                                point: LatLng(h.latitude!, h.longitude!),
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap: () => _onHospitalTap(h),
                                  child: _HospitalMarker(
                                    isSelected: _selectedHospital?.id == h.id,
                                    hasAvailableBeds: h.hasAvailableBeds,
                                  ),
                                ),
                              )),
                    ],
                  ),
                ],
              ),

              // ── Top bar ────────────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: _MapTopBar(
                    hospitalCount: hospitals.length,
                    onListView: () => Navigator.pop(context),
                    onRefresh: () =>
                        context.read<HospitalCubit>().loadHospitalsForMap(),
                  ),
                ),
              ),

              // ── Loading indicator ──────────────────────────────────────────
              if (isLoading)
                const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(child: LoadingWidget()),
                        SizedBox(width: 10),
                        Text('Loading hospitals…'),
                      ],
                    ),
                  ),
                ),

              // ── Locating indicator ────────────────────────────────────────
              if (_locating)
                Positioned(
                  bottom: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 14, height: 14, child: LoadingWidget()),
                          SizedBox(width: 8),
                          Text('Getting your location…',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── FAB: My location ──────────────────────────────────────────
              Positioned(
                right: 16,
                bottom: _selectedHospital != null ? 280 : 24,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoom_in',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, zoom + 1);
                      },
                      child: const Icon(Icons.add, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoom_out',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final zoom = _mapController.camera.zoom;
                        _mapController.move(
                            _mapController.camera.center, zoom - 1);
                      },
                      child: const Icon(Icons.remove, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'my_location',
                      backgroundColor: AppColors.primary,
                      onPressed: _centerOnUser,
                      child: Icon(
                        _locating
                            ? Icons.hourglass_top_rounded
                            : Icons.my_location_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Hospital popup ────────────────────────────────────────────
              if (_selectedHospital != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _HospitalPopup(
                    hospital: _selectedHospital!,
                    userLocation: _userLocation,
                    onClose: _dismissPopup,
                    onGetDirections: () => _openDirections(_selectedHospital!),
                    onViewDetails: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<HospitalCubit>(),
                            child: HospitalDetailScreen(
                                hospitalId: _selectedHospital!.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── User Location Marker ─────────────────────────────────────────────────────
class _UserMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── Hospital Marker ──────────────────────────────────────────────────────────
class _HospitalMarker extends StatelessWidget {
  final bool isSelected;
  final bool hasAvailableBeds;

  const _HospitalMarker({
    required this.isSelected,
    required this.hasAvailableBeds,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppColors.primary
        : hasAvailableBeds
            ? AppColors.hospitalRole
            : AppColors.error;

    return AnimatedScale(
      scale: isSelected ? 1.25 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.local_hospital_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────
class _MapTopBar extends StatelessWidget {
  final int hospitalCount;
  final VoidCallback onListView;
  final VoidCallback onRefresh;

  const _MapTopBar({
    required this.hospitalCount,
    required this.onListView,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onListView,
            child: const Icon(Icons.arrow_back_rounded, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hospitals Near You',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  hospitalCount > 0
                      ? '$hospitalCount hospitals on map'
                      : 'Loading…',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: onRefresh,
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: AppColors.hospitalRole, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                const Text('Hospital',
                    style: TextStyle(fontSize: 10, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hospital Popup Card ──────────────────────────────────────────────────────
class _HospitalPopup extends StatelessWidget {
  final HospitalModel hospital;
  final LatLng? userLocation;
  final VoidCallback onClose;
  final VoidCallback onGetDirections;
  final VoidCallback onViewDetails;

  const _HospitalPopup({
    required this.hospital,
    required this.userLocation,
    required this.onClose,
    required this.onGetDirections,
    required this.onViewDetails,
  });

  String? get _distanceText {
    if (hospital.distanceKm != null) {
      return '${hospital.distanceKm} km away';
    }
    if (userLocation != null &&
        hospital.latitude != null &&
        hospital.longitude != null) {
      const Distance distance = Distance();
      final meters = distance.as(
        LengthUnit.Meter,
        userLocation!,
        LatLng(hospital.latitude!, hospital.longitude!),
      );
      final km = (meters / 1000).toStringAsFixed(1);
      return '$km km away';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distanceText;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                // Hospital icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.hospitalRole.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded,
                      color: AppColors.hospitalRole, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              hospital.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hospital.isVerified)
                            const Icon(Icons.verified_rounded,
                                color: AppColors.primary, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${hospital.city}, ${hospital.state}',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (dist != null) ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          const Icon(Icons.navigation_rounded,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(dist,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600)),
                        ]),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: onClose,
                  splashRadius: 18,
                ),
              ],
            ),
          ),

          // Capacity chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _CapacityChip(
                  icon: Icons.bed_rounded,
                  label: 'Beds',
                  available: hospital.availableBeds,
                  total: hospital.totalBeds,
                  color: hospital.hasAvailableBeds
                      ? AppColors.accent
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                _CapacityChip(
                  icon: Icons.monitor_heart_rounded,
                  label: 'ICU',
                  available: hospital.icuAvailable,
                  total: hospital.icuTotal,
                  color: hospital.hasAvailableICU
                      ? AppColors.accent
                      : AppColors.error,
                ),
                const SizedBox(width: 8),
                _CapacityChip(
                  icon: Icons.emergency_rounded,
                  label: 'Emergency',
                  available: hospital.emergencyAvailable,
                  total: hospital.emergencyBeds,
                  color: hospital.emergencyAvailable > 0
                      ? AppColors.accent
                      : AppColors.error,
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.info_outline_rounded, size: 16),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onGetDirections,
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: const Text('Get Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CapacityChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int available;
  final int total;
  final Color color;

  const _CapacityChip({
    required this.icon,
    required this.label,
    required this.available,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(height: 3),
            Text('$available/$total',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
