import 'package:flutter/material.dart';
import 'package:maplibre_gl/mapbox_gl.dart';
import '../constants/app_constants.dart';

class TimizarMapView extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final void Function(MaplibreMapController controller)? onMapCreated;
  final void Function(LatLng point)? onMapClick;
  final bool myLocationEnabled;

  const TimizarMapView({
    super.key,
    this.initialLat = AppConstants.defaultTiziOuzouLat,
    this.initialLng = AppConstants.defaultTiziOuzouLng,
    this.initialZoom = 13.5,
    this.onMapCreated,
    this.onMapClick,
    this.myLocationEnabled = true,
  });

  @override
  State<TimizarMapView> createState() => _TimizarMapViewState();
}

class _TimizarMapViewState extends State<TimizarMapView> {
  MaplibreMapController? _controller;

  @override
  Widget build(BuildContext context) {
    const styleString = 'https://demotiles.maplibre.org/style.json';

    return MaplibreMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(widget.initialLat, widget.initialLng),
        zoom: widget.initialZoom,
      ),
      styleString: styleString,
      myLocationEnabled: widget.myLocationEnabled,
      myLocationRenderMode: MyLocationRenderMode.COMPASS,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(controller);
      },
      onMapClick: (point, coordinates) {
        widget.onMapClick?.call(coordinates);
      },
    );
  }
}
