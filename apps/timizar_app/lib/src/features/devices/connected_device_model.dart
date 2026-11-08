import 'package:flutter/foundation.dart';

enum DeviceStatus {
  online,
  onTrip,
  standby,
  offline;

  String get label => switch (this) {
        DeviceStatus.online => 'En ligne',
        DeviceStatus.onTrip => 'En mission',
        DeviceStatus.standby => 'En veille',
        DeviceStatus.offline => 'Hors-ligne',
      };
}

enum DeviceType {
  vehicle,
  tracker,
  terminal;

  String get label => switch (this) {
        DeviceType.vehicle => 'Véhicule',
        DeviceType.tracker => 'Balise GPS',
        DeviceType.terminal => 'Terminal',
      };
}

@immutable
class ConnectedDevice {
  final String id;
  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final int batteryLevel; // 0 - 100
  final bool isCharging;
  final int signalPercent; // 0 - 100
  final int satellitesCount;
  final String locationSource; // e.g. "microG UnifiedNlp" / "GPS Direct"
  final double latitude;
  final double longitude;
  final String address;
  final double speedKmh;
  final DateTime lastPing;
  final String firmware;
  final bool isHostDevice;

  const ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.batteryLevel,
    this.isCharging = false,
    required this.signalPercent,
    required this.satellitesCount,
    required this.locationSource,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.speedKmh,
    required this.lastPing,
    required this.firmware,
    this.isHostDevice = false,
  });

  ConnectedDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DeviceStatus? status,
    int? batteryLevel,
    bool? isCharging,
    int? signalPercent,
    int? satellitesCount,
    String? locationSource,
    double? latitude,
    double? longitude,
    String? address,
    double? speedKmh,
    DateTime? lastPing,
    String? firmware,
    bool? isHostDevice,
  }) {
    return ConnectedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      signalPercent: signalPercent ?? this.signalPercent,
      satellitesCount: satellitesCount ?? this.satellitesCount,
      locationSource: locationSource ?? this.locationSource,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      speedKmh: speedKmh ?? this.speedKmh,
      lastPing: lastPing ?? this.lastPing,
      firmware: firmware ?? this.firmware,
      isHostDevice: isHostDevice ?? this.isHostDevice,
    );
  }
}
