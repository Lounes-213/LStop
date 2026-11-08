import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connected_device_model.dart';

class ConnectedDevicesState {
  final List<ConnectedDevice> devices;
  final String selectedFilter; // 'all', 'online', 'vehicle', 'tracker'
  final String searchQuery;
  final bool isRefreshing;
  final String? pingingDeviceId;

  const ConnectedDevicesState({
    required this.devices,
    this.selectedFilter = 'all',
    this.searchQuery = '',
    this.isRefreshing = false,
    this.pingingDeviceId,
  });

  List<ConnectedDevice> get filteredDevices {
    return devices.where((d) {
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matches = d.name.toLowerCase().contains(q) ||
            d.id.toLowerCase().contains(q) ||
            d.address.toLowerCase().contains(q);
        if (!matches) return false;
      }

      return switch (selectedFilter) {
        'online' => d.status == DeviceStatus.online || d.status == DeviceStatus.onTrip,
        'vehicle' => d.type == DeviceType.vehicle,
        'tracker' => d.type == DeviceType.tracker,
        _ => true,
      };
    }).toList();
  }

  int get onlineCount => devices
      .where((d) => d.status == DeviceStatus.online || d.status == DeviceStatus.onTrip)
      .length;

  ConnectedDevicesState copyWith({
    List<ConnectedDevice>? devices,
    String? selectedFilter,
    String? searchQuery,
    bool? isRefreshing,
    String? pingingDeviceId,
  }) {
    return ConnectedDevicesState(
      devices: devices ?? this.devices,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      pingingDeviceId: pingingDeviceId,
    );
  }
}

class ConnectedDevicesNotifier extends StateNotifier<ConnectedDevicesState> {
  Timer? _heartbeatTimer;

  ConnectedDevicesNotifier()
      : super(ConnectedDevicesState(devices: _initialDevices)) {
    _startHeartbeat();
  }

  static final List<ConnectedDevice> _initialDevices = [
    ConnectedDevice(
      id: 'HOST-01',
      name: 'Ce Smartphone (Hôte)',
      type: DeviceType.terminal,
      status: DeviceStatus.online,
      batteryLevel: 94,
      isCharging: true,
      signalPercent: 96,
      satellitesCount: 16,
      locationSource: 'microG UnifiedNlp (Nominatim + Cell)',
      latitude: 36.7118,
      longitude: 4.0459,
      address: 'Centre-ville, Tizi Ouzou',
      speedKmh: 0.0,
      lastPing: DateTime.now(),
      firmware: 'Android AOSP • microG v0.3.1',
      isHostDevice: true,
    ),
    ConnectedDevice(
      id: 'TRK-HILUX-07',
      name: 'Toyota Hilux 4x4 (Navette)',
      type: DeviceType.vehicle,
      status: DeviceStatus.onTrip,
      batteryLevel: 100,
      isCharging: true,
      signalPercent: 92,
      satellitesCount: 18,
      locationSource: 'GNSS / Balise OBD-II Direct',
      latitude: 36.7280,
      longitude: 4.0620,
      address: 'Route Nationale 12, Tizi Ouzou',
      speedKmh: 58.4,
      lastPing: DateTime.now().subtract(const Duration(seconds: 4)),
      firmware: 'Teltonika FMB920-v1.4',
    ),
    ConnectedDevice(
      id: 'DEV-CHAUF-03',
      name: 'Terminal Chauffeur Amine',
      type: DeviceType.terminal,
      status: DeviceStatus.online,
      batteryLevel: 78,
      signalPercent: 88,
      satellitesCount: 14,
      locationSource: 'microG UnifiedNlp (GSM Triangulation)',
      latitude: 36.7020,
      longitude: 4.0410,
      address: 'Gare Multimodale, Kef Naadja',
      speedKmh: 12.0,
      lastPing: DateTime.now().subtract(const Duration(seconds: 9)),
      firmware: 'Timizar Driver Engine v2.1',
    ),
    ConnectedDevice(
      id: 'TRK-PARCEL-12',
      name: 'Balise Colis Express',
      type: DeviceType.tracker,
      status: DeviceStatus.standby,
      batteryLevel: 62,
      signalPercent: 74,
      satellitesCount: 11,
      locationSource: 'GPS Autonome / microG Relay',
      latitude: 36.7350,
      longitude: 4.0720,
      address: 'Timizart Loghbar, DZA',
      speedKmh: 0.0,
      lastPing: DateTime.now().subtract(const Duration(minutes: 2)),
      firmware: 'Queclink GL300M v3.0',
    ),
  ];

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      // Gently update host device last ping and jitter coordinates slightly
      final updated = state.devices.map((d) {
        if (d.isHostDevice) {
          return d.copyWith(lastPing: DateTime.now());
        }
        return d;
      }).toList();
      state = state.copyWith(devices: updated);
    });
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> refreshDevices() async {
    state = state.copyWith(isRefreshing: true);
    await Future.delayed(const Duration(milliseconds: 650));
    final updated = state.devices.map((d) {
      return d.copyWith(
        lastPing: DateTime.now(),
        batteryLevel: d.isCharging ? (d.batteryLevel + 1).clamp(0, 100) : d.batteryLevel,
      );
    }).toList();
    state = state.copyWith(devices: updated, isRefreshing: false);
  }

  Future<void> pingDevice(String deviceId) async {
    state = state.copyWith(pingingDeviceId: deviceId);
    await Future.delayed(const Duration(milliseconds: 500));
    final updated = state.devices.map((d) {
      if (d.id == deviceId) {
        return d.copyWith(
          lastPing: DateTime.now(),
          status: d.status == DeviceStatus.offline ? DeviceStatus.online : d.status,
        );
      }
      return d;
    }).toList();
    state = state.copyWith(devices: updated, pingingDeviceId: null);
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

final connectedDevicesProvider =
    StateNotifierProvider<ConnectedDevicesNotifier, ConnectedDevicesState>((ref) {
  return ConnectedDevicesNotifier();
});
