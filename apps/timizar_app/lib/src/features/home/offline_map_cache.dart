import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timizar_core/timizar_core.dart';

class OfflineMapCache {
  static const _keyLastLat = 'timizar_last_lat';
  static const _keyLastLng = 'timizar_last_lng';
  static const _keyLastZoom = 'timizar_last_zoom';

  final FlutterSecureStorage _storage;

  OfflineMapCache([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveLastKnownRegion({
    required double lat,
    required double lng,
    required double zoom,
  }) async {
    await _storage.write(key: _keyLastLat, value: lat.toString());
    await _storage.write(key: _keyLastLng, value: lng.toString());
    await _storage.write(key: _keyLastZoom, value: zoom.toString());
  }

  Future<({double lat, double lng, double zoom})> getLastKnownRegion() async {
    final latStr = await _storage.read(key: _keyLastLat);
    final lngStr = await _storage.read(key: _keyLastLng);
    final zoomStr = await _storage.read(key: _keyLastZoom);

    final lat = double.tryParse(latStr ?? '') ?? AppConstants.defaultTiziOuzouLat;
    final lng = double.tryParse(lngStr ?? '') ?? AppConstants.defaultTiziOuzouLng;
    final zoom = double.tryParse(zoomStr ?? '') ?? 13.5;

    return (lat: lat, lng: lng, zoom: zoom);
  }
}

