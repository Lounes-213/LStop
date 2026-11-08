import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../location/live_location_service.dart';
import '../map/open_street_map_widget.dart';
import '../splash/lstop_emblem.dart';
import '../transport/fourgon_model.dart';
import '../transport/fourgon_provider.dart';
import '../transport/routing_service.dart';
import 'driver_profiles_bottom_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Mode OSM Standard (couleurs & noms des places) vs Satellite
  bool _isSatellite = false;

  /// Déplacement fluide et animé de la caméra vers une destination (et non sec/direct)
  void _smoothMoveTo(LatLng destLocation, double destZoom) {
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    final animation = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOutCubic,
    );

    animController.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animController.dispose();
      }
    });

    animController.forward();
  }

  void _collapseBottomSheet() {
    if (_sheetController.isAttached) {
      if (_sheetController.size > 0.25) {
        _sheetController.animateTo(
          0.22,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  void _expandBottomSheet() {
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.70,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _toggleMapMode() {
    setState(() => _isSatellite = !_isSatellite);
  }

  Future<void> _routeToDriver(Fourgon driver) async {
    final liveLoc = ref.read(liveLocationProvider);
    final userPos = liveLoc.position; // VRAIE POSITION GPS RÉELLE DU USER

    // Calcule le tracé routier réel reliant VOTRE POSITION au CHAUFFEUR
    final route = await RoutingService.getRoadRoute(userPos, driver.currentLocation);

    if (route != null && mounted) {
      final transportNotifier = ref.read(transportProvider.notifier);
      transportNotifier.selectFourgon(
        driver.copyWith(routePoints: route.points),
      );

      _smoothMoveTo(driver.currentLocation, 14.8);
      _collapseBottomSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. VRAIE POSITION GPS RÉELLE DU USER
    final liveLocState = ref.watch(liveLocationProvider);
    final userPos = liveLocState.position;
    final userHeading = liveLocState.heading;

    // 2. Transport State
    final transportState = ref.watch(transportProvider);
    final transportNotifier = ref.read(transportProvider.notifier);
    final visibleFourgons = transportState.visibleFourgons;

    return Scaffold(
      body: Stack(
        children: [
          // 1. OpenStreetMap (OSM Standard avec toutes les couleurs & noms OU Satellite)
          OpenStreetMapWidget(
            mapController: _mapController,
            userLocation: userPos,
            userHeading: userHeading,
            isSatellite: _isSatellite,
            fourgons: transportState.fourgons,
            selectedFourgon: transportState.selectedFourgon,
            activeRoutePolyline: transportState.activeRoutePolyline,
            onMapInteraction: _collapseBottomSheet,
            onFourgonSelected: (driver) {
              _routeToDriver(driver);
            },
          ),

          // 2. BANDEAU SUPÉRIEUR : BOUTON S + ITINÉRAIRE DÉTAILLÉ AU MILIEU + BOUTON POSITION
          Positioned(
            top: 52,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Bouton Circulaire Logo (Emblème 'S' - Bascule OSM / Satellite)
                _buildCircularLogoButton(),
                const SizedBox(width: 8),

                // ITINÉRAIRE DÉTAILLÉ PLACÉ AU MILIEU ENTRE LES DEUX BOUTONS
                if (transportState.routeSummary != null)
                  Expanded(
                    child: _buildDetailedRouteBanner(
                      summary: transportState.routeSummary!,
                      selectedFourgon: transportState.selectedFourgon,
                      onClose: () {
                        transportNotifier.clearSelection();
                      },
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(width: 8),
                // Bouton Circulaire Position GPS
                _buildCircularPositionButton(userPos),
              ],
            ),
          ),

          // 3. VOLET DU BAS AVEC PROFILS DES CHAUFFEURS (Rétractable, Scrollable)
          DriverProfilesBottomSheet(
            sheetController: _sheetController,
            userLocation: userPos,
            fourgons: visibleFourgons,
            selectedFourgon: transportState.selectedFourgon,
            selectedLineFilter: transportState.selectedLineFilter,
            onSelectLineFilter: transportNotifier.setLineFilter,
            onSelectDriver: _routeToDriver,
            onSelectSearchResult: (result) async {
              if (result.fourgon != null) {
                _routeToDriver(result.fourgon!);
              } else {
                final route =
                    await RoutingService.getRoadRoute(userPos, result.location);
                if (route != null && mounted) {
                  transportNotifier.routeToDestination(
                    start: userPos,
                    destination: result.location,
                    destinationName: result.title,
                  );
                  _mapController.move(result.location, 14.5);
                  _collapseBottomSheet();
                }
              }
            },
            onExpandSheet: _expandBottomSheet,
          ),
        ],
      ),
    );
  }

  /// Itinéraire Détaillé placé en haut au milieu entre les 2 boutons (avec PDP, temps approximatif et bouton X)
  Widget _buildDetailedRouteBanner({
    required String summary,
    Fourgon? selectedFourgon,
    required VoidCallback onClose,
  }) {
    final driver = selectedFourgon;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 18,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // PDP avatar du transporteur avec anneau de couleur de la ligne
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: driver?.lineColor ?? const Color(0xFF60A5FA),
                    width: 2.2,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: (driver?.lineColor ?? const Color(0xFF2563EB))
                      .withValues(alpha: 0.2),
                  backgroundImage: driver?.avatarUrl != null
                      ? NetworkImage(driver!.avatarUrl!)
                      : null,
                  onBackgroundImageError:
                      driver?.avatarUrl != null ? (_, __) {} : null,
                  child: driver?.avatarUrl == null
                      ? Text(
                          driver != null && driver.driverName.isNotEmpty
                              ? driver.driverName[0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: driver?.lineColor ?? Colors.white,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),

              // Temps approximatif d'arrivée & détails du trajet
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver?.driverName ?? 'Trajet vers destination',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      driver != null
                          ? 'Arrivée dans ~ ${driver.etaMinutes} min • ${driver.distanceKm} km'
                          : summary,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Bouton X qui fait disparaître immédiatement la carte
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bouton circulaire blanc avec l'emblème S : bascule entre OSM couleur et Satellite
  Widget _buildCircularLogoButton() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.90),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleMapMode,
              borderRadius: BorderRadius.circular(26),
              child: const Center(
                child: LStopEmblem(size: 44),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bouton circulaire de position en forme de flèche bleue : déplace la caméra avec fluidité vers votre position GPS
  Widget _buildCircularPositionButton(LatLng userPos) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _smoothMoveTo(userPos, 15.2);
              },
              borderRadius: BorderRadius.circular(26),
              child: Center(
                child: Transform.rotate(
                  angle: -0.45, // Flèche directionnelle bleue inclinée
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF2563EB), // Bleu vif
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
