import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class RideRequestScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> destination;

  const RideRequestScreen({super.key, required this.destination});

  @override
  ConsumerState<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends ConsumerState<RideRequestScreen> {
  bool _isLoadingEstimate = true;
  bool _isRequesting = false;
  FareBreakdown? _fare;
  RouteInfo? _route;
  String _selectedVehicleClass = 'standard';

  final double _pickupLat = AppConstants.defaultTiziOuzouLat;
  final double _pickupLng = AppConstants.defaultTiziOuzouLng;
  final String _pickupAddress = 'Centre-ville, Tizi Ouzou';

  @override
  void initState() {
    super.initState();
    _fetchEstimate();
  }

  Future<void> _fetchEstimate() async {
    final destLat = (widget.destination['lat'] as num).toDouble();
    final destLng = (widget.destination['lng'] as num).toDouble();

    final api = ref.read(apiClientProvider);
    final res = await api.post<Map<String, dynamic>>(
      ApiEndpoints.tripEstimate,
      data: {
        'pickupLat': _pickupLat,
        'pickupLng': _pickupLng,
        'dropoffLat': destLat,
        'dropoffLng': destLng,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;
    setState(() => _isLoadingEstimate = false);

    res.when(
      success: (data) {
        setState(() {
          _fare = FareBreakdown.fromJson(data['fare'] as Map<String, dynamic>);
          _route = RouteInfo.fromJson(data['route'] as Map<String, dynamic>);
        });
      },
      failure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur calcul itinéraire: $err')),
        );
      },
    );
  }

  Future<void> _requestRide() async {
    setState(() => _isRequesting = true);
    final destLat = (widget.destination['lat'] as num).toDouble();
    final destLng = (widget.destination['lng'] as num).toDouble();
    final destAddress = widget.destination['address'] as String? ?? widget.destination['name'] as String;

    final api = ref.read(apiClientProvider);
    final res = await api.post<Map<String, dynamic>>(
      ApiEndpoints.tripRequest,
      data: {
        'pickupLat': _pickupLat,
        'pickupLng': _pickupLng,
        'pickupAddress': _pickupAddress,
        'dropoffLat': destLat,
        'dropoffLng': destLng,
        'dropoffAddress': destAddress,
      },
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;
    setState(() => _isRequesting = false);

    res.when(
      success: (data) {
        final tripId = data['tripId'] as String;
        context.pushReplacement('/tracking/$tripId');
      },
      failure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de commander: $err'), backgroundColor: AppColors.dangerRed),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final destName = widget.destination['name'] as String? ?? 'Destination';

    return Scaffold(
      body: Stack(
        children: [
          // Map preview
          TimizarMapView(
            initialLat: _pickupLat,
            initialLng: _pickupLng,
          ),

          // Top back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 12.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 24,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),

          // Bottom Ride Options Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x24000000),
                    blurRadius: 24,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Route summary header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _route != null
                                    ? '${_route!.distanceKm.toStringAsFixed(1)} km • ${_route!.durationMins.toStringAsFixed(0)} min de trajet'
                                    : 'Calcul de la distance...',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_fare != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _fare!.formattedFare,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),

                    // Ride vehicle options
                    _buildVehicleOption(
                      id: 'standard',
                      title: 'Timizar Standard',
                      subtitle: 'Course économique • 4 places',
                      priceDzd: _fare?.totalFareDzd ?? 200,
                      icon: Icons.directions_car_rounded,
                    ),
                    const SizedBox(height: 10),
                    _buildVehicleOption(
                      id: 'comfort',
                      title: 'Timizar Confort',
                      subtitle: 'Véhicule récent avec climatisation',
                      priceDzd: (_fare?.totalFareDzd ?? 200) * 1.3,
                      icon: Icons.local_taxi_rounded,
                    ),
                    const SizedBox(height: 16),

                    // Cash payment badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Paiement en espèces directement au chauffeur',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Commander Button
                    TimizarButton(
                      text: 'Commander Timizar',
                      isLoading: _isRequesting || _isLoadingEstimate,
                      onPressed: _fare != null ? _requestRide : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleOption({
    required String id,
    required String title,
    required String subtitle,
    required double priceDzd,
    required IconData icon,
  }) {
    final isSelected = _selectedVehicleClass == id;

    return InkWell(
      onTap: () => setState(() => _selectedVehicleClass = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : const Color(0xFF475569)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${priceDzd.toStringAsFixed(0)} DA',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
