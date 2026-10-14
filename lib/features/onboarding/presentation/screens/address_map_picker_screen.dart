import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';

class AddressMapPickerScreen extends ConsumerStatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const AddressMapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  ConsumerState<AddressMapPickerScreen> createState() => _AddressMapPickerScreenState();
}

class _AddressMapPickerScreenState extends ConsumerState<AddressMapPickerScreen> {
  late final MapController _mapController;
  late LatLng _currentLocation;
  String? _resolvedAddress;
  bool _isLookingUp = false;
  Timer? _debounceTimer;

  // Default to Ho Chi Minh City center if none provided
  static const LatLng defaultHcmCenter = LatLng(10.7769, 106.7009);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _resolvedAddress = widget.initialAddress;
    _currentLocation = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : defaultHcmCenter;

    if (_resolvedAddress == null) {
      _lookupAddress(_currentLocation);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _currentLocation = camera.center;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 600), () {
        _lookupAddress(_currentLocation);
      });
    }
  }

  Future<void> _lookupAddress(LatLng location) async {
    setState(() => _isLookingUp = true);
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      final res = await repo.reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (mounted) {
        setState(() {
          _resolvedAddress = res.address;
          _isLookingUp = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress = 'Tọa độ: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
          _isLookingUp = false;
        });
      }
    }
  }

  Future<void> _moveToCurrentGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật định vị GPS trên điện thoại')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    final newLoc = LatLng(pos.latitude, pos.longitude);

    setState(() => _currentLocation = newLoc);
    _mapController.move(newLoc, 16.0);
    _lookupAddress(newLoc);
  }

  void _confirmSelection() {
    Navigator.of(context).pop({
      'latitude': _currentLocation.latitude,
      'longitude': _currentLocation.longitude,
      'address': _resolvedAddress ?? 'Địa chỉ đã chọn',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí kho lấy hàng'),
      ),
      body: Stack(
        children: [
          // FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'tech.secondlife.seller',
              ),
            ],
          ),

          // Center Pin Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 36.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  Container(
                    width: 3,
                    height: 12,
                    color: AppColors.primary,
                  ),
                  Container(
                    width: 8,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // GPS Button
          Positioned(
            right: 16,
            bottom: 180,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 4,
              onPressed: _moveToCurrentGps,
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Địa chỉ nhận kiện hàng Lalamove',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      const Spacer(),
                      if (_isLookingUp)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _resolvedAddress ?? 'Đang xác định địa chỉ...',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  SlButton(
                    text: 'Xác nhận vị trí này',
                    isLoading: _isLookingUp,
                    onPressed: _confirmSelection,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
