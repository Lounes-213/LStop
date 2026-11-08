import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../transport/fourgon_model.dart';
import 'user_position_pin.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng userLocation;
  final double? userHeading;
  final bool isSatellite;
  final List<Fourgon> fourgons;
  final Fourgon? selectedFourgon;
  final List<LatLng> activeRoutePolyline;
  final VoidCallback onMapInteraction;
  final Function(Fourgon) onFourgonSelected;

  const OpenStreetMapWidget({
    super.key,
    required this.mapController,
    required this.userLocation,
    this.userHeading,
    required this.isSatellite,
    required this.fourgons,
    this.selectedFourgon,
    required this.activeRoutePolyline,
    required this.onMapInteraction,
    required this.onFourgonSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Standard OpenStreetMap (avec toutes les couleurs et noms des places)
    // 2. Satellite (Esri World Imagery)
    final tileUrl = isSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: userLocation,
        initialZoom: 14.2,
        onPositionChanged: (pos, hasGesture) {
          if (hasGesture) {
            onMapInteraction();
          }
        },
      ),
      children: [
        // Raster Tile Layer
        TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'dz.lstop.app',
          maxZoom: 19,
        ),

        // Route Polyline (Tracé routier réel reliant Votre Vraie Position au Chauffeur ou Destination)
        if (activeRoutePolyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Outer contrast outline
              Polyline(
                points: activeRoutePolyline,
                color: Colors.white.withValues(alpha: 0.95),
                strokeWidth: 7.0,
              ),
              // Inner route line
              Polyline(
                points: activeRoutePolyline,
                color: selectedFourgon?.lineColor ?? const Color(0xFF2563EB),
                strokeWidth: 4.8,
              ),
            ],
          ),

        // Markers Layer
        MarkerLayer(
          markers: [
            // Votre Vraie Position (Icône semi-transparente personnalisée)
            Marker(
              point: userLocation,
              width: 54,
              height: 54,
              child: UserPositionPin(heading: userHeading),
            ),

            // Chauffeurs / Fourgons Markers (PDP seule avec cercle de couleur de ligne, sans aucun texte)
            ...fourgons.where((f) => f.isVisible).map((fourgon) {
              final isSelected = selectedFourgon?.id == fourgon.id;
              return Marker(
                point: fourgon.currentLocation,
                width: 48,
                height: 48,
                child: GestureDetector(
                  onTap: () => onFourgonSelected(fourgon),
                  child: _buildDriverMarker(fourgon, isSelected),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  /// PDP circulaire du transporteur avec anneau de couleur de la ligne (sans aucun texte)
  Widget _buildDriverMarker(Fourgon fourgon, bool isSelected) {
    final size = isSelected ? 44.0 : 38.0;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: fourgon.lineColor, // Couleur de cercle indiquant la ligne
            width: isSelected ? 3.5 : 2.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: CircleAvatar(
          backgroundColor: fourgon.lineColor.withValues(alpha: 0.15),
          backgroundImage: fourgon.avatarUrl != null
              ? NetworkImage(fourgon.avatarUrl!)
              : null,
          onBackgroundImageError: fourgon.avatarUrl != null ? (_, __) {} : null,
          child: Text(
            fourgon.driverName.isNotEmpty
                ? fourgon.driverName[0].toUpperCase()
                : 'C',
            style: TextStyle(
              fontSize: isSelected ? 15 : 13,
              fontWeight: FontWeight.w800,
              color: fourgon.lineColor,
            ),
          ),
        ),
      ),
    );
  }
}
