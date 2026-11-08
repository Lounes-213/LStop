import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'fourgon_model.dart';
import 'routing_service.dart';

final availableTransportLines = [
  const TransportLine(
    id: 'L1',
    name: 'Ligne 01 : Gare Multimodale — Azazga',
    color: Color(0xFF2563EB), // Blue
    startPlace: 'Gare Multimodale',
    endPlace: 'Azazga Centre',
    majorStops: [
      'Gare Multimodale',
      'Centre-Ville',
      'Hasnaoua',
      'Timizart Loghbar',
      'Chaib',
      'Azazga Centre',
    ],
    waypoints: [
      LatLng(36.7020, 4.0410), // Gare Multimodale
      LatLng(36.7118, 4.0459), // Centre Ville
      LatLng(36.7210, 4.0550), // Hasnaoua
      LatLng(36.7350, 4.0720), // Timizart Loghbar
      LatLng(36.7450, 4.1400), // Chaib
      LatLng(36.7480, 4.3720), // Azazga
    ],
  ),
  const TransportLine(
    id: 'L2',
    name: 'Ligne 02 : Tizi Centre — Nouvelle Ville',
    color: Color(0xFF059669), // Emerald
    startPlace: 'Place de l\'Olivier',
    endPlace: 'Nouvelle Ville',
    majorStops: [
      'Place de l\'Olivier',
      'Boulevard Stiti',
      'Cité 20 Août',
      'Nouvelle Ville Sud',
    ],
    waypoints: [
      LatLng(36.7118, 4.0459), // Centre
      LatLng(36.7080, 4.0490), // Rue Stiti
      LatLng(36.6980, 4.0530), // Cité 20 Août
      LatLng(36.6890, 4.0610), // Nouvelle Ville
    ],
  ),
  const TransportLine(
    id: 'L3',
    name: 'Ligne 03 : Tizi Ouzou — Draa Ben Khedda',
    color: Color(0xFFD97706), // Amber
    startPlace: 'Gare Routière',
    endPlace: 'DBK Centre',
    majorStops: [
      'Gare Routière',
      'Boukhalfa',
      'Oued Fali',
      'DBK Centre',
    ],
    waypoints: [
      LatLng(36.7020, 4.0410), // Gare
      LatLng(36.7150, 4.0200), // Boukhalfa
      LatLng(36.7280, 3.9800), // Oued Fali
      LatLng(36.7320, 3.9610), // Draa Ben Khedda
    ],
  ),
  const TransportLine(
    id: 'L4',
    name: 'Ligne 04 : Gare — Campus Tamda',
    color: Color(0xFF7C3AED), // Purple
    startPlace: 'Gare Multimodale',
    endPlace: 'Université Tamda',
    majorStops: [
      'Gare Multimodale',
      'Oued Aissi',
      'Zone Industrielle',
      'Campus Tamda',
    ],
    waypoints: [
      LatLng(36.7020, 4.0410),
      LatLng(36.7120, 4.0950), // Oued Aissi
      LatLng(36.7190, 4.1350), // Zone Ind
      LatLng(36.7310, 4.1850), // Tamda
    ],
  ),
];

class TransportState {
  final List<Fourgon> fourgons;
  final String? selectedFourgonId;
  final String selectedLineFilter; // 'all', 'L1', 'L2', 'L3', 'L4'
  final List<LatLng> activeRoutePolyline;
  final String? routeSummary;
  final String driverCustomName;
  final String driverSelectedLineId;
  final bool isDriverVisibleOnMap;
  final bool isDriverDriving;

  const TransportState({
    required this.fourgons,
    this.selectedFourgonId,
    this.selectedLineFilter = 'all',
    this.activeRoutePolyline = const [],
    this.routeSummary,
    this.driverCustomName = 'Karim Chauffeur',
    this.driverSelectedLineId = 'L1',
    this.isDriverVisibleOnMap = true,
    this.isDriverDriving = false,
  });

  Fourgon? get selectedFourgon {
    if (selectedFourgonId == null) return null;
    try {
      return fourgons.firstWhere((f) => f.id == selectedFourgonId);
    } catch (_) {
      return null;
    }
  }

  Fourgon? get driverFourgon {
    try {
      return fourgons.firstWhere((f) => f.isDriverControlled);
    } catch (_) {
      return null;
    }
  }

  List<Fourgon> get visibleFourgons {
    return fourgons.where((f) {
      if (!f.isVisible) return false;
      if (selectedLineFilter != 'all' && f.lineId != selectedLineFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  TransportState copyWith({
    List<Fourgon>? fourgons,
    String? selectedFourgonId,
    String? selectedLineFilter,
    List<LatLng>? activeRoutePolyline,
    String? routeSummary,
    String? driverCustomName,
    String? driverSelectedLineId,
    bool? isDriverVisibleOnMap,
    bool? isDriverDriving,
    bool clearSelectedFourgon = false,
    bool clearRoute = false,
  }) {
    return TransportState(
      fourgons: fourgons ?? this.fourgons,
      selectedFourgonId: clearSelectedFourgon
          ? null
          : (selectedFourgonId ?? this.selectedFourgonId),
      selectedLineFilter: selectedLineFilter ?? this.selectedLineFilter,
      activeRoutePolyline: clearRoute
          ? const []
          : (activeRoutePolyline ?? this.activeRoutePolyline),
      routeSummary: clearRoute ? null : (routeSummary ?? this.routeSummary),
      driverCustomName: driverCustomName ?? this.driverCustomName,
      driverSelectedLineId: driverSelectedLineId ?? this.driverSelectedLineId,
      isDriverVisibleOnMap: isDriverVisibleOnMap ?? this.isDriverVisibleOnMap,
      isDriverDriving: isDriverDriving ?? this.isDriverDriving,
    );
  }
}

class TransportNotifier extends StateNotifier<TransportState> {
  Timer? _movementTimer;
  final Map<String, List<LatLng>> _lineRoadCache = {};

  TransportNotifier() : super(_initialState()) {
    _initRealRoutes();
    _startMovementLoop();
  }

  static TransportState _initialState() {
    return const TransportState(
      fourgons: [
        Fourgon(
          id: 'FRG-01',
          driverName: 'Karim Ait O.',
          vehicleName: 'Toyota HiAce (14 places)',
          plate: '15-119-2022',
          lineId: 'L1',
          lineTitle: 'Ligne 01 : Gare — Azazga',
          lineColor: Color(0xFF2563EB),
          currentLocation: LatLng(36.7118, 4.0459),
          heading: 65,
          distanceKm: 1.2,
          etaMinutes: 4,
          seatsAvailable: 3,
          isVisible: true,
          currentStatusText: 'Vers Hasnaoua',
          nextStop: 'Arrêt Hasnaoua',
          speedKmh: 30.0,
          avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
          phone: '0555 12 34 56',
          rating: 4.9,
          totalTrips: 1140,
        ),
        Fourgon(
          id: 'FRG-02',
          driverName: 'Mourad Transport',
          vehicleName: 'Renault Master Combi',
          plate: '15-204-2021',
          lineId: 'L2',
          lineTitle: 'Ligne 02 : Centre — Nouvelle Ville',
          lineColor: Color(0xFF059669),
          currentLocation: LatLng(36.6980, 4.0530),
          heading: 180,
          distanceKm: 2.8,
          etaMinutes: 7,
          seatsAvailable: 5,
          isVisible: true,
          currentStatusText: 'Vers Cité 20 Août',
          nextStop: 'Arrêt 20 Août',
          speedKmh: 26.0,
          avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
          phone: '0560 98 76 54',
          rating: 4.8,
          totalTrips: 820,
        ),
        Fourgon(
          id: 'FRG-03',
          driverName: 'Slimane Chauffeur',
          vehicleName: 'Peugeot Boxer 15 Places',
          plate: '15-341-2019',
          lineId: 'L3',
          lineTitle: 'Ligne 03 : Tizi — Draa Ben Khedda',
          lineColor: Color(0xFFD97706),
          currentLocation: LatLng(36.7150, 4.0200),
          heading: 275,
          distanceKm: 4.5,
          etaMinutes: 11,
          seatsAvailable: 2,
          isVisible: true,
          currentStatusText: 'Passage Boukhalfa',
          nextStop: 'Arrêt Boukhalfa',
          speedKmh: 32.0,
          avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&auto=format&fit=crop&q=80',
          phone: '0770 45 67 89',
          rating: 4.9,
          totalTrips: 940,
        ),
        Fourgon(
          id: 'FRG-04',
          driverName: 'Farid Transport',
          vehicleName: 'Mercedes Sprinter',
          plate: '15-772-2023',
          lineId: 'L1',
          lineTitle: 'Ligne 01 : Gare — Azazga',
          lineColor: Color(0xFF2563EB),
          currentLocation: LatLng(36.7350, 4.0720),
          heading: 70,
          distanceKm: 6.8,
          etaMinutes: 16,
          seatsAvailable: 4,
          isVisible: true,
          currentStatusText: 'À l\'arrêt : Timizart Loghbar',
          nextStop: 'Arrêt Chaib',
          speedKmh: 28.0,
          avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
          phone: '0541 22 33 44',
          rating: 4.7,
          totalTrips: 650,
        ),
        Fourgon(
          id: 'FRG-05',
          driverName: 'Akli Navette',
          vehicleName: 'Hyundai H1 Minibus',
          plate: '15-812-2020',
          lineId: 'L4',
          lineTitle: 'Ligne 04 : Gare — Campus Tamda',
          lineColor: Color(0xFF7C3AED),
          currentLocation: LatLng(36.7120, 4.0950),
          heading: 85,
          distanceKm: 5.2,
          etaMinutes: 13,
          seatsAvailable: 6,
          isVisible: true,
          currentStatusText: 'Vers Oued Aissi',
          nextStop: 'Arrêt Oued Aissi',
          speedKmh: 34.0,
          avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
          phone: '0661 77 88 99',
          rating: 5.0,
          totalTrips: 1320,
        ),
      ],
    );
  }

  Future<void> _initRealRoutes() async {
    // 1. Precompute real curved road paths for each line via OSRM
    for (final line in availableTransportLines) {
      final route = await RoutingService.getRoadRoute(
        line.waypoints.first,
        line.waypoints.last,
      );
      _lineRoadCache[line.id] = route?.points ?? line.waypoints;
    }

    // 2. Assign real curved road paths to fourgons
    final updated = <Fourgon>[];
    for (final f in state.fourgons) {
      final roadPoints = _lineRoadCache[f.lineId] ??
          availableTransportLines
              .firstWhere(
                (l) => l.id == f.lineId,
                orElse: () => availableTransportLines.first,
              )
              .waypoints;

      updated.add(f.copyWith(
        routePoints: roadPoints,
      ));
    }

    state = state.copyWith(fourgons: updated);
  }

  /// Live movement loop: moves the fourgons along their realistic road trajectories in REAL TIME
  void _startMovementLoop() {
    _movementTimer?.cancel();
    _movementTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!mounted) return;
      _tickLivePositions();
    });
  }

  void _tickLivePositions() {
    final updated = state.fourgons.map((f) {
      if (f.routePoints.isEmpty) return f;

      final points = f.routePoints;
      final nextIdx = (f.currentWaypointIndex + 1) % points.length;
      final nextPos = points[nextIdx];

      // Update "Win wsel" text according to progression
      final line = availableTransportLines.firstWhere(
        (l) => l.id == f.lineId,
        orElse: () => availableTransportLines.first,
      );

      final stopIndex =
          ((nextIdx / points.length) * line.majorStops.length).floor().clamp(
                0,
                line.majorStops.length - 1,
              );
      final nextStop =
          line.majorStops[(stopIndex + 1) % line.majorStops.length];

      return f.copyWith(
        currentLocation: nextPos,
        currentWaypointIndex: nextIdx,
        currentStatusText: 'Vers $nextStop',
        nextStop: nextStop,
      );
    }).toList();

    state = state.copyWith(fourgons: updated);
  }

  void setLineFilter(String lineId) {
    if (lineId == 'all') {
      state = state.copyWith(
        selectedLineFilter: 'all',
        clearRoute: true,
      );
      return;
    }

    final line = availableTransportLines.firstWhere(
      (l) => l.id == lineId,
      orElse: () => availableTransportLines.first,
    );

    // Use REAL road curve points, never straight segments!
    final roadCurve = _lineRoadCache[lineId] ?? line.waypoints;

    state = state.copyWith(
      selectedLineFilter: lineId,
      activeRoutePolyline: roadCurve,
      routeSummary: line.name,
    );
  }

  void selectFourgon(Fourgon fourgon) {
    state = state.copyWith(
      selectedFourgonId: fourgon.id,
      activeRoutePolyline: fourgon.routePoints,
      routeSummary:
          '${fourgon.driverName} (${fourgon.lineId}) • ${fourgon.distanceKm} km • ${fourgon.etaMinutes} min',
    );
  }

  void clearSelection() {
    state = state.copyWith(
      clearSelectedFourgon: true,
      clearRoute: true,
    );
  }

  void routeToDestination({
    required LatLng start,
    required LatLng destination,
    required String destinationName,
  }) async {
    final route =
        await RoutingService.getRoadRoute(start, destination);
    if (route != null) {
      state = state.copyWith(
        activeRoutePolyline: route.points,
        routeSummary:
            '$destinationName • ${route.distanceKm} km • ${route.durationMinutes} min',
      );
    }
  }

  void updateDriverName(String name) {
    state = state.copyWith(driverCustomName: name);
    final updated = state.fourgons.map((f) {
      if (f.isDriverControlled) {
        return f.copyWith(driverName: name.isNotEmpty ? name : 'Mon Fourgon');
      }
      return f;
    }).toList();
    state = state.copyWith(fourgons: updated);
  }

  void updateDriverLine(String lineId) {
    final line = availableTransportLines.firstWhere(
      (l) => l.id == lineId,
      orElse: () => availableTransportLines.first,
    );

    final updated = state.fourgons.map((f) {
      if (f.isDriverControlled) {
        return f.copyWith(
          lineId: line.id,
          lineTitle: line.name,
          lineColor: line.color,
          currentLocation: line.waypoints.first,
        );
      }
      return f;
    }).toList();

    state = state.copyWith(
      driverSelectedLineId: lineId,
      fourgons: updated,
    );
  }

  void toggleDriverVisibility(bool isVisible) {
    state = state.copyWith(isDriverVisibleOnMap: isVisible);
    final updated = state.fourgons.map((f) {
      if (f.isDriverControlled) {
        return f.copyWith(isVisible: isVisible);
      }
      return f;
    }).toList();
    state = state.copyWith(fourgons: updated);
  }

  void toggleDriverDriving(bool isDriving) {
    state = state.copyWith(isDriverDriving: isDriving);
  }

  void advanceDriverPositionManually() {
    final line = availableTransportLines.firstWhere(
      (l) => l.id == state.driverSelectedLineId,
      orElse: () => availableTransportLines.first,
    );

    final updated = state.fourgons.map((f) {
      if (f.isDriverControlled) {
        final nextIdx = (f.currentWaypointIndex + 1) % line.waypoints.length;
        return f.copyWith(
          currentLocation: line.waypoints[nextIdx],
          currentWaypointIndex: nextIdx,
        );
      }
      return f;
    }).toList();

    state = state.copyWith(fourgons: updated);
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }
}

final transportProvider =
    StateNotifierProvider<TransportNotifier, TransportState>((ref) {
  return TransportNotifier();
});
