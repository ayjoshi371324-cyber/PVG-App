import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

/// Interactive OpenStreetMap widget for Pune pooling routes.
///
/// Features:
/// 1. Numbered markers (P1/D1, P2/D2) with distinct high-contrast colors per booking.
/// 2. Multi-state polyline rendering: solid confirmed, dashed proposed modifications, faded completed segments.
/// 3. Privacy-safe stop list legend displaying aliases, party sizes, and ETAs.
/// 4. Auto-fits bounds to active waypoints with interactive control buttons.
class PuneMapWidget extends StatefulWidget {
  const PuneMapWidget({
    super.key,
    this.pickup,
    this.dropoff,
    this.polylinePoints = const [],
    this.confirmedPolylinePoints,
    this.proposedPolylinePoints,
    this.completedPolylinePoints,
    this.vehiclePosition,
    this.waypoints = const [],
    this.extraMarkers = const [],
    this.extraPolylines = const [],
    this.showStopLegend = true,
    this.onMapTap,
  });

  final PuneLocation? pickup;
  final PuneLocation? dropoff;
  final List<LatLng> polylinePoints;
  final List<LatLng>? confirmedPolylinePoints;
  final List<LatLng>? proposedPolylinePoints;
  final List<LatLng>? completedPolylinePoints;
  final LatLng? vehiclePosition;
  final List<TripWaypoint> waypoints;
  final List<Marker> extraMarkers;
  final List<Polyline> extraPolylines;
  final bool showStopLegend;
  final void Function(LatLng point)? onMapTap;

  static const LatLng defaultPuneCenter = LatLng(18.5204, 73.8567);

  @override
  State<PuneMapWidget> createState() => _PuneMapWidgetState();
}

class _PuneMapWidgetState extends State<PuneMapWidget> {
  final MapController _mapController = MapController();
  bool _isLegendExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapBounds();
    });
  }

  @override
  void didUpdateWidget(covariant PuneMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.waypoints != oldWidget.waypoints ||
        widget.vehiclePosition != oldWidget.vehiclePosition ||
        widget.confirmedPolylinePoints != oldWidget.confirmedPolylinePoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapBounds();
      });
    }
  }

  List<LatLng> _collectAllRoutePoints() {
    final points = <LatLng>[];
    if (widget.waypoints.isNotEmpty) {
      for (final wp in widget.waypoints) {
        points.add(wp.location.toLatLng());
      }
    }
    if (widget.pickup != null) points.add(widget.pickup!.toLatLng());
    if (widget.dropoff != null) points.add(widget.dropoff!.toLatLng());
    if (widget.vehiclePosition != null) points.add(widget.vehiclePosition!);

    if (widget.confirmedPolylinePoints != null) {
      points.addAll(widget.confirmedPolylinePoints!);
    } else if (widget.polylinePoints.isNotEmpty) {
      points.addAll(widget.polylinePoints);
    }
    if (widget.proposedPolylinePoints != null) {
      points.addAll(widget.proposedPolylinePoints!);
    }
    if (widget.completedPolylinePoints != null) {
      points.addAll(widget.completedPolylinePoints!);
    }
    return points;
  }

  void _fitMapBounds() {
    final points = _collectAllRoutePoints();
    if (points.length >= 2) {
      try {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(50.0),
          ),
        );
      } catch (_) {
        // Fallback gracefully if map is not rendered yet
      }
    }
  }

  LatLng get _initialCenter {
    if (widget.waypoints.isNotEmpty) {
      final first = widget.waypoints.first.location;
      return LatLng(first.latitude, first.longitude);
    }
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

    // 1. Render Multi-Passenger Waypoint Markers (P1/D1, P2/D2...)
    if (widget.waypoints.isNotEmpty) {
      for (final wp in widget.waypoints) {
        final isPickup = wp.type == WaypointType.pickup;
        final isCompleted = wp.status == WaypointStatus.completed;
        final isCurrent = wp.status == WaypointStatus.current;
        final markerCode = wp.markerCode;
        final bookingColor = wp.bookingColor;

        markers.add(
          Marker(
            point: wp.location.toLatLng(),
            width: 44,
            height: 44,
            child: Center(
              child: Opacity(
                opacity: isCompleted ? 0.55 : 1.0,
                child: Container(
                  key: Key('marker_${markerCode.toLowerCase()}'),
                  decoration: BoxDecoration(
                    color: bookingColor,
                    shape: isPickup ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: isPickup ? null : BorderRadius.circular(6.0),
                    border: Border.all(
                      color: isCurrent ? UberColors.ink : UberColors.canvas,
                      width: isCurrent ? 3.0 : 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Backwards compatibility dot / square
                      if (wp.isUser && isPickup)
                        const SizedBox(
                          key: Key('pickup_marker_dot'),
                          width: 0,
                          height: 0,
                        ),
                      if (wp.isUser && !isPickup)
                        const SizedBox(
                          key: Key('dropoff_marker_square'),
                          width: 0,
                          height: 0,
                        ),
                      Center(
                        child: Text(
                          markerCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // Fallback single-passenger markers for backward compatibility
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
    }

    // Vehicle position marker
    if (widget.vehiclePosition != null) {
      markers.add(
        Marker(
          point: widget.vehiclePosition!,
          width: 38,
          height: 38,
          child: Center(
            child: Container(
              key: const Key('vehicle_marker_icon'),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: UberColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: UberColors.canvas, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: UberColors.onPrimary,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }

    // 2. Build multi-state polylines: solid confirmed, dashed proposed, faded completed
    final polylines = <Polyline>[];

    // Faded completed segments
    if (widget.completedPolylinePoints != null &&
        widget.completedPolylinePoints!.isNotEmpty) {
      polylines.add(
        Polyline(
          points: widget.completedPolylinePoints!,
          strokeWidth: 3.5,
          color: UberColors.mute.withValues(alpha: 0.4),
          pattern: const StrokePattern.solid(),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    // Solid confirmed route polylines
    final confirmedPoints = widget.confirmedPolylinePoints ?? widget.polylinePoints;
    if (confirmedPoints.isNotEmpty) {
      polylines.add(
        Polyline(
          points: confirmedPoints,
          strokeWidth: 4.5,
          color: UberColors.primary,
          pattern: const StrokePattern.solid(),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    // Dashed proposed modifications (mid-trip joiner or detour updates)
    if (widget.proposedPolylinePoints != null &&
        widget.proposedPolylinePoints!.isNotEmpty) {
      polylines.add(
        Polyline(
          points: widget.proposedPolylinePoints!,
          strokeWidth: 4.0,
          color: UberColors.accentGreen,
          pattern: StrokePattern.dashed(segments: const [10, 8]),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }

    polylines.addAll(widget.extraPolylines);

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
            if (polylines.isNotEmpty)
              PolylineLayer(polylines: polylines),
            MarkerLayer(markers: [...markers, ...widget.extraMarkers]),
          ],
        ),

        // 3. Floating Route Stop List Legend
        if (widget.waypoints.isNotEmpty && widget.showStopLegend)
          Positioned(
            left: UberSpacing.lg,
            top: 70.0,
            child: _buildStopListLegend(),
          ),

        // Map control overlays (Zoom in / out / Recenter bounds)
        Positioned(
          right: UberSpacing.lg,
          top: 70.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapControlButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom in',
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
                tooltip: 'Zoom out',
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
                icon: Icons.fit_screen_rounded,
                key: const Key('map_fit_bounds_button'),
                tooltip: 'Fit route bounds',
                onTap: _fitMapBounds,
              ),
              const SizedBox(height: UberSpacing.xs),
              _buildMapControlButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Default center',
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

  Widget _buildStopListLegend() {
    return Container(
      key: const Key('map_stop_list_legend'),
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: UberColors.canvas.withValues(alpha: 0.95),
        borderRadius: UberRadii.lg,
        border: Border.all(color: UberColors.surfacePressed),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with collapse toggle
          InkWell(
            key: const Key('toggle_stop_legend_button'),
            borderRadius: UberRadii.lg,
            onTap: () {
              setState(() {
                _isLegendExpanded = !_isLegendExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: UberSpacing.sm,
                vertical: 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.route_rounded,
                        size: 16,
                        color: UberColors.ink,
                      ),
                      const SizedBox(width: UberSpacing.xs),
                      Text(
                        'Route Stops (${widget.waypoints.length})',
                        style: UberTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: UberColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isLegendExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: UberColors.body,
                  ),
                ],
              ),
            ),
          ),

          if (_isLegendExpanded) ...[
            const Divider(height: 1, color: UberColors.canvasSoft),
            Padding(
              padding: const EdgeInsets.all(UberSpacing.xs),
              child: Column(
                children: widget.waypoints.map((wp) {
                  final isPickup = wp.type == WaypointType.pickup;
                  final isCompleted = wp.status == WaypointStatus.completed;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Colored Marker Badge (P1, D1, etc.)
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? UberColors.canvasSoft
                                : wp.bookingColor,
                            shape: isPickup ? BoxShape.circle : BoxShape.rectangle,
                            borderRadius:
                                isPickup ? null : BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              wp.markerCode,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isCompleted
                                    ? UberColors.mute
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: UberSpacing.xs),

                        // Stop details: alias, party size, ETA
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${wp.passengerAlias} (Party of ${wp.partySize})',
                                style: UberTypography.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted
                                      ? UberColors.mute
                                      : UberColors.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${isPickup ? "Pickup" : "Drop-off"} • ${wp.estimatedMinutes} min',
                                style: UberTypography.caption.copyWith(
                                  fontSize: 10,
                                  color: UberColors.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onTap,
    Key? key,
    String? tooltip,
  }) {
    return Material(
      key: key,
      color: UberColors.canvas,
      shape: const CircleBorder(),
      elevation: 3.0,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      clipBehavior: Clip.antiAlias,
      child: Tooltip(
        message: tooltip ?? '',
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
      ),
    );
  }
}
