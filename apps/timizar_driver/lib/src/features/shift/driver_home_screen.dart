import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _isOnline = false;
  bool _isToggling = false;
  Timer? _telemetryTimer;

  // Driver current coordinates (Tizi Ouzou center default)
  double _lat = AppConstants.defaultTiziOuzouLat;
  double _lng = AppConstants.defaultTiziOuzouLng;
  double _lastSentLat = 0.0;
  double _lastSentLng = 0.0;

  // Active incoming ride offer
  RideOfferMessage? _incomingOffer;
  int _countdownSeconds = 15;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _checkInitialOnlineStatus();
  }

  void _checkInitialOnlineStatus() {
    final driver = ref.read(driverAuthProvider).driver;
    if (driver?.isOnline ?? false) {
      _startOnlineSession();
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleOnlineShift() async {
    setState(() => _isToggling = true);
    final targetState = !_isOnline;
    final success = await ref.read(driverAuthProvider.notifier).toggleShift(targetState);

    if (!mounted) return;
    setState(() => _isToggling = false);

    if (success) {
      setState(() => _isOnline = targetState);
      if (_isOnline) {
        _startOnlineSession();
      } else {
        _stopOnlineSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de changer de statut. Vérifiez votre compte.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  void _startOnlineSession() {
    setState(() => _isOnline = true);
    final user = ref.read(driverAuthProvider).user;
    final driverId = user?.id ?? '';
    final geohash5 = GeohashHelper.encode(_lat, _lng, precision: 5);

    final realtime = ref.read(realtimeClientProvider);
    realtime.connectToZone(
      geohash5: geohash5,
      userId: driverId,
      role: 'driver',
      lat: _lat,
      lng: _lng,
    );

    // Listen for incoming ride offers
    realtime.messageStream.listen((msg) {
      if (!mounted) return;
      if (msg is RideOfferMessage) {
        _triggerIncomingOffer(msg);
      }
    });

    // Start battery-aware telemetry timer (every 5 seconds while moving, 15 seconds while idle)
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendLocationUpdate();
    });
  }

  void _sendLocationUpdate() {
    if (!_isOnline) return;
    final user = ref.read(driverAuthProvider).user;
    final driverId = user?.id ?? '';

    // Simulate minor movement for realistic driver telemetry (>15 meters filter)
    _lat += 0.0001;
    _lng += 0.0001;

    final dist = GeohashHelper.distanceMeters(_lat, _lng, _lastSentLat, _lastSentLng);
    if (dist >= AppConstants.minDistanceFilterMeters || _lastSentLat == 0.0) {
      _lastSentLat = _lat;
      _lastSentLng = _lng;

      final realtime = ref.read(realtimeClientProvider);
      realtime.sendDriverLocation(
        driverId: driverId,
        latitude: _lat,
        longitude: _lng,
        heading: 45.0,
        speed: 35.0,
        isMoving: true,
        isAvailable: true,
      );
    }
  }

  void _stopOnlineSession() {
    setState(() => _isOnline = false);
    _telemetryTimer?.cancel();
    final user = ref.read(driverAuthProvider).user;
    final driverId = user?.id ?? '';

    final realtime = ref.read(realtimeClientProvider);
    realtime.sendDriverOffline(driverId);
    realtime.disconnect();
  }

  void _triggerIncomingOffer(RideOfferMessage offer) {
    setState(() {
      _incomingOffer = offer;
      _countdownSeconds = offer.expiresInSeconds;
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() => _countdownSeconds--);
      } else {
        timer.cancel();
        _rejectOffer();
      }
    });
  }

  Future<void> _acceptOffer() async {
    if (_incomingOffer == null) return;
    _countdownTimer?.cancel();
    final tripId = _incomingOffer!.tripId;

    final api = ref.read(apiClientProvider);
    await api.post(ApiEndpoints.tripAccept(tripId));

    if (!mounted) return;
    setState(() => _incomingOffer = null);
    context.push('/active-trip/$tripId');
  }

  Future<void> _rejectOffer() async {
    if (_incomingOffer == null) return;
    _countdownTimer?.cancel();
    final tripId = _incomingOffer!.tripId;

    final api = ref.read(apiClientProvider);
    await api.post(ApiEndpoints.tripReject(tripId));

    if (!mounted) return;
    setState(() => _incomingOffer = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Map View
          TimizarMapView(
            initialLat: _lat,
            initialLng: _lng,
          ),

          // 2. Top Header Bar (Earnings + Profile)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Earnings Pill
                  InkWell(
                    onTap: () => context.push('/earnings'),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Gains : 3 450 DA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Profile Icon Button
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 24,
                    child: IconButton(
                      icon: const Icon(Icons.person_rounded, color: Color(0xFF1E293B)),
                      onPressed: () => context.push('/profile'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Shift Toggle Card
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildShiftCard(context),
          ),

          // 4. Incoming Ride Offer Modal Overlay (15s Countdown)
          if (_incomingOffer != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildIncomingOfferCard(context),
            ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _isOnline ? AppColors.primary : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isOnline ? 'VOUS ÊTES EN LIGNE' : 'VOUS ÊTES HORS LIGNE',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _isOnline ? AppColors.primaryDark : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Text(
                  _isOnline ? 'Recherche active' : 'Prêt à rouler',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TimizarButton(
              text: _isOnline ? 'Passer hors ligne' : 'Passer en ligne',
              variant: _isOnline ? ButtonVariant.danger : ButtonVariant.primary,
              isLoading: _isToggling,
              onPressed: _toggleOnlineShift,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingOfferCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Countdown Indicator + Fare
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: _countdownSeconds / 15.0,
                      strokeWidth: 4,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      backgroundColor: const Color(0xFFE2E8F0),
                    ),
                  ),
                  Text(
                    '$_countdownSeconds',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Rémunération', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  Text(
                    '${_incomingOffer!.fareDzd.toStringAsFixed(0)} DA',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Pickup & Destination
          Row(
            children: [
              const Icon(Icons.circle, color: AppColors.primary, size: 12),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _incomingOffer!.pickupAddress,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.dangerRed, size: 14),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _incomingOffer!.dropoffAddress,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Distance : ${_incomingOffer!.distanceKm.toStringAsFixed(1)} km • Durée : ${_incomingOffer!.durationMins.toStringAsFixed(0)} min',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),

          // Accept / Decline Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _rejectOffer,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.dangerRed),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Refuser', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TimizarButton(
                  text: 'Accepter la course',
                  onPressed: _acceptOffer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
