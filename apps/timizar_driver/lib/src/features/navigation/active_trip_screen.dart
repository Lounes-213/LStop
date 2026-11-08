import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timizar_core/timizar_core.dart';
import '../../providers.dart';

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String tripId;

  const ActiveTripScreen({super.key, required this.tripId});

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  Trip? _trip;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _fetchTrip();
  }

  Future<void> _fetchTrip() async {
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

  Future<void> _updateTripStatus(String status) async {
    setState(() => _isUpdating = true);
    final api = ref.read(apiClientProvider);
    final res = await api.post<Map<String, dynamic>>(
      ApiEndpoints.tripStatus(widget.tripId),
      data: {'status': status},
      parser: (data) => data as Map<String, dynamic>,
    );

    if (!mounted) return;
    setState(() => _isUpdating = false);

    res.when(
      success: (data) {
        _fetchTrip();
        if (status == 'completed') {
          _showCompletionReceipt();
        }
      },
      failure: (err) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $err'), backgroundColor: AppColors.dangerRed),
        );
      },
    );
  }

  void _showCompletionReceipt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Course terminée !', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 54),
            const SizedBox(height: 16),
            const Text('Montant à encaisser auprès du client :'),
            const SizedBox(height: 8),
            Text(
              _trip?.formattedFare ?? '350 DA',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Paiement en espèces uniquement.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TimizarButton(
            text: 'Encaissé • Retour au Cockpit',
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = _trip?.status ?? TripStatus.accepted;

    return Scaffold(
      body: Stack(
        children: [
          // Navigation Map View
          TimizarMapView(
            initialLat: _trip?.pickupLat ?? AppConstants.defaultTiziOuzouLat,
            initialLng: _trip?.pickupLng ?? AppConstants.defaultTiziOuzouLng,
          ),

          // Top Navigation Banner
          SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.turn_right_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          status == TripStatus.inProgress ? 'Vers la destination' : 'Vers le point de prise en charge',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          status == TripStatus.inProgress ? (_trip?.dropoffAddress ?? '') : (_trip?.pickupAddress ?? ''),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Color(0x24000000), blurRadius: 20, offset: Offset(0, -6)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Passenger info row
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          radius: 24,
                          child: Icon(Icons.person_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _trip?.passengerName ?? 'Client Timizar',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                _trip?.passengerPhone ?? '0555 12 34 56',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Dynamic action button based on state
                    if (status == TripStatus.accepted)
                      TimizarButton(
                        text: 'Je suis arrivé au rendez-vous',
                        isLoading: _isUpdating,
                        onPressed: () => _updateTripStatus('arrived'),
                      )
                    else if (status == TripStatus.arrived)
                      TimizarButton(
                        text: 'Démarrer la course',
                        isLoading: _isUpdating,
                        onPressed: () => _updateTripStatus('in_progress'),
                      )
                    else if (status == TripStatus.inProgress)
                      TimizarButton(
                        text: 'Terminer la course',
                        variant: ButtonVariant.primary,
                        isLoading: _isUpdating,
                        onPressed: () => _updateTripStatus('completed'),
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
}
