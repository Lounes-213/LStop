import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import '../transport/fourgon_model.dart';
import '../transport/fourgon_provider.dart';

enum SearchResultType {
  place,
  line,
  fourgon;

  String get label => switch (this) {
        SearchResultType.place => 'Lieu / Arrêt',
        SearchResultType.line => 'Ligne de transport',
        SearchResultType.fourgon => 'Fourgon / Chauffeur',
      };
}

class UnifiedSearchResult {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final LatLng location;
  final TransportLine? line;
  final Fourgon? fourgon;

  const UnifiedSearchResult({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.location,
    this.line,
    this.fourgon,
  });
}

class UnifiedSearchService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
      headers: {'User-Agent': 'LStop-Algeria-App/1.0'},
    ),
  );

  static const List<UnifiedSearchResult> _localHubs = [
    UnifiedSearchResult(
      title: 'Gare Multimodale de Tizi Ouzou',
      subtitle: 'Kef Naadja, Tizi Ouzou (Hub central bus & fourgons)',
      type: SearchResultType.place,
      location: LatLng(36.7020, 4.0410),
    ),
    UnifiedSearchResult(
      title: 'Université Mouloud Mammeri (Hasnaoua)',
      subtitle: 'Boulevard des Frères Ouamrane, Tizi Ouzou',
      type: SearchResultType.place,
      location: LatLng(36.7145, 4.0580),
    ),
    UnifiedSearchResult(
      title: 'Timizart Loghbar',
      subtitle: 'Route Nationale 12, Tizi Ouzou',
      type: SearchResultType.place,
      location: LatLng(36.7350, 4.0720),
    ),
    UnifiedSearchResult(
      title: 'Azazga Centre',
      subtitle: 'Centre ville & Arrêt principal fourgons, RN12',
      type: SearchResultType.place,
      location: LatLng(36.7480, 4.3720),
    ),
    UnifiedSearchResult(
      title: 'Nouvelle Ville',
      subtitle: 'Cité 20 Août / Sud, Tizi Ouzou',
      type: SearchResultType.place,
      location: LatLng(36.6890, 4.0610),
    ),
    UnifiedSearchResult(
      title: 'Draa Ben Khedda (DBK)',
      subtitle: 'Centre Ville & Gare routière DBK',
      type: SearchResultType.place,
      location: LatLng(36.7320, 3.9610),
    ),
    UnifiedSearchResult(
      title: 'Alger — Place des Martyrs',
      subtitle: 'Alger Centre, Station Métro & Bus',
      type: SearchResultType.place,
      location: LatLng(36.7850, 3.0600),
    ),
  ];

  static Future<List<UnifiedSearchResult>> search({
    required String query,
    required List<Fourgon> activeFourgons,
  }) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    final results = <UnifiedSearchResult>[];

    // 1. Search in Fourgons (Chauffeur, Véhicule, Matricule)
    for (final f in activeFourgons) {
      if (f.driverName.toLowerCase().contains(clean) ||
          f.vehicleName.toLowerCase().contains(clean) ||
          f.plate.toLowerCase().contains(clean) ||
          f.lineTitle.toLowerCase().contains(clean)) {
        results.add(
          UnifiedSearchResult(
            title: f.driverName,
            subtitle: '${f.lineTitle} • ${f.vehicleName} (${f.seatsAvailable} places)',
            type: SearchResultType.fourgon,
            location: f.currentLocation,
            fourgon: f,
          ),
        );
      }
    }

    // 2. Search in Transport Lines
    for (final l in availableTransportLines) {
      if (l.name.toLowerCase().contains(clean) ||
          l.startPlace.toLowerCase().contains(clean) ||
          l.endPlace.toLowerCase().contains(clean) ||
          l.id.toLowerCase().contains(clean)) {
        results.add(
          UnifiedSearchResult(
            title: l.name,
            subtitle: 'Trajet : ${l.startPlace} ➔ ${l.endPlace}',
            type: SearchResultType.line,
            location: l.waypoints.first,
            line: l,
          ),
        );
      }
    }

    // 3. Search in Algerian Hubs
    for (final hub in _localHubs) {
      if (hub.title.toLowerCase().contains(clean) ||
          hub.subtitle.toLowerCase().contains(clean)) {
        results.add(hub);
      }
    }

    // 4. Online Nominatim Geocoding (if length >= 3 and internet available)
    if (clean.length >= 3) {
      try {
        final url =
            'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(clean)}&format=json&countrycodes=dz&limit=4';
        final resp = await _dio.get<String>(url);
        if (resp.statusCode == 200 && resp.data != null) {
          final list = jsonDecode(resp.data!) as List<dynamic>;
          for (final item in list) {
            final map = item as Map<String, dynamic>;
            final name = (map['display_name'] as String? ?? '').split(',').first.trim();
            final address = map['display_name'] as String? ?? '';
            final lat = double.tryParse(map['lat']?.toString() ?? '');
            final lon = double.tryParse(map['lon']?.toString() ?? '');

            if (lat != null && lon != null) {
              // Avoid duplicates
              if (!results.any((r) => (r.location.latitude - lat).abs() < 0.001 &&
                  (r.location.longitude - lon).abs() < 0.001)) {
                results.add(
                  UnifiedSearchResult(
                    title: name,
                    subtitle: address,
                    type: SearchResultType.place,
                    location: LatLng(lat, lon),
                  ),
                );
              }
            }
          }
        }
      } catch (_) {
        // Fallback silently if offline
      }
    }

    return results;
  }
}
