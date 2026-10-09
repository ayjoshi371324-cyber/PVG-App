import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

class PuneMapWidget extends StatefulWidget {
  const PuneMapWidget({
    super.key,
    this.pickup,
    this.dropoff,
    this.polylinePoints = const [],
    this.extraMarkers = const [],
    this.extraPolylines = const [],
    this.onMapTap,
  });

  final PuneLocation? pickup;
  final PuneLocation? dropoff;
  final List<LatLng> polylinePoints;
  final List<Marker> extraMarkers;
  final List<Polyline> extraPolylines;
  final void Function(LatLng point)? onMapTap;

  static const LatLng defaultPuneCenter = LatLng(18.5204, 73.8567);

  @override
  State<PuneMapWidget> createState() => _PuneMapWidgetState();
}

class _PuneMapWidgetState extends State<PuneMapWidget> {
  final MapController _mapController = MapController();

  LatLng get _initialCenter {
    if (widget.pickup != null && widget.dropoff != null) {
      return LatLng(
        (widget.pickup!.latitude + widget.dropoff!.latitude) / 2,
        (widget.pickup!.longitude + widget.dropoff!.longitude) / 2,
      );
    } else if (widget.pickup != null) {
      return widget.pickup!.toLatLng();
    } else if (widget.dropoff != null) {
      return widget.dropoff!.toLatLng();
    }
    return PuneMapWidget.defaultPuneCenter;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (widget.pickup != null) {
      markers.add(
        Marker(
          point: widget.pickup!.toLatLng(),
          width: 32,
          height: 32,
          child: Center(
            child: Container(
              key: const Key('pickup_marker_dot'),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: UberColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: UberColors.canvas, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.dropoff != null) {
      markers.add(
        Marker(
          point: widget.dropoff!.toLatLng(),
          width: 32,
          height: 32,
          child: Center(
            child: Container(
              key: const Key('dropoff_marker_square'),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: UberColors.primary,
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(color: UberColors.canvas, width: 3.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  color: UberColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 12.0,
            minZoom: 10.0,
            maxZoom: 18.0,
            onTap: widget.onMapTap != null
                ? (tapPosition, point) => widget.onMapTap!(point)
                : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.pvg.ridepool',
              maxZoom: 19,
            ),
            if (widget.polylinePoints.isNotEmpty || widget.extraPolylines.isNotEmpty)
              PolylineLayer(
                polylines: [
                  if (widget.polylinePoints.isNotEmpty)
                    Polyline(
                      points: widget.polylinePoints,
                      strokeWidth: 4.5,
                      color: UberColors.primary,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ...widget.extraPolylines,
                ],
              ),
            MarkerLayer(markers: [...markers, ...widget.extraMarkers]),
          ],
        ),

        // Map control overlays (Zoom in / out)
        Positioned(
          right: UberSpacing.lg,
          top: 70.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapControlButton(
                icon: Icons.add_rounded,
                onTap: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom + 1.0,
                  );
                },
              ),
              const SizedBox(height: UberSpacing.xs),
              _buildMapControlButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _mapController.camera.center,
                    currentZoom - 1.0,
                  );
                },
              ),
              const SizedBox(height: UberSpacing.xs),
              _buildMapControlButton(
                icon: Icons.my_location_rounded,
                onTap: () {
                  _mapController.move(PuneMapWidget.defaultPuneCenter, 12.5);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: UberColors.canvas,
      shape: const CircleBorder(),
      elevation: 3.0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(UberSpacing.sm),
          child: Icon(
            icon,
            size: 20.0,
            color: UberColors.ink,
          ),
        ),
      ),
    );
  }
}
