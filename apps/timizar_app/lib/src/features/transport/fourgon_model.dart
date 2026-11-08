import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TransportLine {
  final String id;
  final String name;
  final Color color;
  final String startPlace;
  final String endPlace;
  final List<String> majorStops;
  final List<LatLng> waypoints;

  const TransportLine({
    required this.id,
    required this.name,
    required this.color,
    required this.startPlace,
    required this.endPlace,
    required this.majorStops,
    required this.waypoints,
  });
}

class Fourgon {
  final String id;
  final String driverName;
  final String vehicleName;
  final String plate;
  final String lineId;
  final String lineTitle;
  final Color lineColor;
  final LatLng currentLocation;
  final double heading;
  final double distanceKm;
  final int etaMinutes;
  final int seatsAvailable;
  final bool isVisible;
  final bool isDriverControlled;
  final String currentStatusText;
  final String nextStop;
  final double speedKmh;
  final String? avatarUrl;
  final String phone;
  final double rating;
  final int totalTrips;
  final int experienceYears;
  final List<LatLng> routePoints;
  final int currentWaypointIndex;

  const Fourgon({
    required this.id,
    required this.driverName,
    required this.vehicleName,
    required this.plate,
    required this.lineId,
    required this.lineTitle,
    required this.lineColor,
    required this.currentLocation,
    required this.heading,
    required this.distanceKm,
    required this.etaMinutes,
    required this.seatsAvailable,
    this.isVisible = true,
    this.isDriverControlled = false,
    this.currentStatusText = 'En circulation',
    this.nextStop = '',
    this.speedKmh = 28.0,
    this.avatarUrl,
    this.phone = '0550 12 34 56',
    this.rating = 4.9,
    this.totalTrips = 840,
    this.experienceYears = 6,
    this.routePoints = const [],
    this.currentWaypointIndex = 0,
  });

  Fourgon copyWith({
    String? id,
    String? driverName,
    String? vehicleName,
    String? plate,
    String? lineId,
    String? lineTitle,
    Color? lineColor,
    LatLng? currentLocation,
    double? heading,
    double? distanceKm,
    int? etaMinutes,
    int? seatsAvailable,
    bool? isVisible,
    bool? isDriverControlled,
    String? currentStatusText,
    String? nextStop,
    double? speedKmh,
    String? avatarUrl,
    String? phone,
    double? rating,
    int? totalTrips,
    int? experienceYears,
    List<LatLng>? routePoints,
    int? currentWaypointIndex,
  }) {
    return Fourgon(
      id: id ?? this.id,
      driverName: driverName ?? this.driverName,
      vehicleName: vehicleName ?? this.vehicleName,
      plate: plate ?? this.plate,
      lineId: lineId ?? this.lineId,
      lineTitle: lineTitle ?? this.lineTitle,
      lineColor: lineColor ?? this.lineColor,
      currentLocation: currentLocation ?? this.currentLocation,
      heading: heading ?? this.heading,
      distanceKm: distanceKm ?? this.distanceKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      seatsAvailable: seatsAvailable ?? this.seatsAvailable,
      isVisible: isVisible ?? this.isVisible,
      isDriverControlled: isDriverControlled ?? this.isDriverControlled,
      currentStatusText: currentStatusText ?? this.currentStatusText,
      nextStop: nextStop ?? this.nextStop,
      speedKmh: speedKmh ?? this.speedKmh,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      experienceYears: experienceYears ?? this.experienceYears,
      routePoints: routePoints ?? this.routePoints,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
    );
  }
}
