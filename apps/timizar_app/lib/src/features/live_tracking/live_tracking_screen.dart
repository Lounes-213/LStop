import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String tripId;

  const LiveTrackingScreen({super.key, required this.tripId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  Trip? _trip;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialTrip();
    _subscribeToTripEvents();
  }

  Future<void> _fetchInitialTrip() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get<Map<String, dynamic>>(
      ApiEndpoints.tripDetails(widget.tripId),
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    res.when(
      success: (data) {
        setState(() {
          _trip = Trip.fromJson(data['trip'] as Map<String, dynamic>);
        });
      },
      failure: (err) {
        AppLogger.e('Error fetching trip: $err');
      },
    );
  }

  void _subscribeToTripEvents() {
    final user = ref.read(authStateProvider).value;
    final userId = user?.id ?? 'anon';
    final realtime = ref.read(realtimeClientProvider);

    realtime.connectToTrip(tripId: widget.tripId, userId: userId, role: 'passenger');

    realtime.messageStream.listen((msg) {
      if (!mounted) return;
      if (msg is TripUpdateMessage) {
        setState(() {
          _trip = msg.trip;
        });

        if (msg.trip.status == TripStatus.completed) {
          _showRatingDialog();
        }
      }
    });
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        int selectedRating = 5;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Course terminée !', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Comment s\'est passée votre course ?', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.warningOrange,
                      size: 32,
                    ),
                    onPressed: () {},
                  );
                }),
              ),
            ],
          ),
          actions: [
            TimizarButton(
              text: 'Valider et retourner à l\'accueil',
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = _trip?.status ?? TripStatus.requested;

    return Scaffold(
      body: Stack(
        children: [
          // Map view
          TimizarMapView(
            initialLat: _trip?.pickupLat ?? AppConstants.defaultTiziOuzouLat,
            initialLng: _trip?.pickupLng ?? AppConstants.defaultTiziOuzouLng,
          ),

          // Top status pill
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusText(status),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom card
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildTrackingCard(context, status),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard(BuildContext context, TripStatus status) {
    return Container(
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
            if (status == TripStatus.requested || status == TripStatus.offered) ...[
              const Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Recherche du chauffeur le plus proche...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nous contactons les chauffeurs autour de votre position.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ] else ...[
              // Driver and Vehicle Details
              Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.person_rounded, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _trip?.driverName ?? 'Chauffeur Timizar',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.warningOrange, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${_trip?.driverRating?.toStringAsFixed(1) ?? '4.9'} • ${_trip?.vehicleMake ?? 'Dacia'} ${_trip?.vehicleModel ?? 'Logan'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Text(
                      _trip?.licensePlate ?? '15-12345',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tarif convenu', style: TextStyle(color: Color(0xFF64748B))),
                  Text(
                    _trip?.formattedFare ?? '250 DA',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Actions row (SOS & Cancel)
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed),
                  label: const Text('SOS', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.dangerRed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => context.push('/sos'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.go('/');
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Retour accueil'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TripStatus status) {
    return switch (status) {
      TripStatus.requested || TripStatus.offered => AppColors.warningOrange,
      TripStatus.accepted || TripStatus.arriving || TripStatus.arrived => AppColors.accentBlue,
      TripStatus.inProgress => AppColors.primary,
      TripStatus.completed => AppColors.primary,
      _ => AppColors.dangerRed,
    };
  }

  String _getStatusText(TripStatus status) {
    return switch (status) {
      TripStatus.requested || TripStatus.offered => 'Recherche d\'un chauffeur...',
      TripStatus.accepted => 'Chauffeur assigné',
      TripStatus.arriving => 'Chauffeur en route vers vous',
      TripStatus.arrived => 'Chauffeur arrivé !',
      TripStatus.inProgress => 'Course en cours',
      TripStatus.completed => 'Course terminée',
      _ => 'Course annulée',
    };
  }
}
