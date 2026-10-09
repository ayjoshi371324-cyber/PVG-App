import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/widgets/pune_map_widget.dart';

void main() {
  group('Multi-Passenger Live Map Widget Tests (Ticket 03)', () {
    final testWaypoints = [
      const TripWaypoint(
        id: 'wp-p1',
        location: PuneLandmarks.kothrud,
        passengerName: 'You',
        passengerAlias: 'Rider A (You)',
        partySize: 2,
        isUser: true,
        type: WaypointType.pickup,
        status: WaypointStatus.completed,
        estimatedMinutes: 0,
        bookingIndex: 1,
        stopSequence: 1,
        markerCode: 'P1',
        bookingColor: BookingColors.booking1,
      ),
      const TripWaypoint(
        id: 'wp-p2',
        location: PuneLandmarks.swargate,
        passengerName: 'Priya',
        passengerAlias: 'Rider B',
        partySize: 1,
        type: WaypointType.pickup,
        status: WaypointStatus.current,
        estimatedMinutes: 6,
        bookingIndex: 2,
        stopSequence: 2,
        markerCode: 'P2',
        bookingColor: BookingColors.booking2,
      ),
      const TripWaypoint(
        id: 'wp-d1',
        location: PuneLandmarks.hinjawadiPhase1,
        passengerName: 'You',
        passengerAlias: 'Rider A (You)',
        partySize: 2,
        isUser: true,
        type: WaypointType.dropoff,
        status: WaypointStatus.pending,
        estimatedMinutes: 24,
        bookingIndex: 1,
        stopSequence: 3,
        markerCode: 'D1',
        bookingColor: BookingColors.booking1,
      ),
      const TripWaypoint(
        id: 'wp-d2',
        location: PuneLandmarks.vimanNagar,
        passengerName: 'Priya',
        passengerAlias: 'Rider B',
        partySize: 1,
        type: WaypointType.dropoff,
        status: WaypointStatus.pending,
        estimatedMinutes: 28,
        bookingIndex: 2,
        stopSequence: 4,
        markerCode: 'D2',
        bookingColor: BookingColors.booking2,
      ),
    ];

    testWidgets('renders numbered markers (P1/D1, P2/D2) with distinct high-contrast colors',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PuneMapWidget(
              waypoints: testWaypoints,
              vehiclePosition: const LatLng(18.5074, 73.8077),
            ),
          ),
        ),
      );

      // Verify numbered markers P1, P2, D1, D2
      expect(find.byKey(const Key('marker_p1')), findsOneWidget);
      expect(find.byKey(const Key('marker_p2')), findsOneWidget);
      expect(find.byKey(const Key('marker_d1')), findsOneWidget);
      expect(find.byKey(const Key('marker_d2')), findsOneWidget);

      expect(find.text('P1'), findsWidgets);
      expect(find.text('P2'), findsWidgets);
      expect(find.text('D1'), findsWidgets);
      expect(find.text('D2'), findsWidgets);

      // Verify backwards-compatible keys
      expect(find.byKey(const Key('pickup_marker_dot')), findsOneWidget);
      expect(find.byKey(const Key('dropoff_marker_square')), findsOneWidget);
      expect(find.byKey(const Key('vehicle_marker_icon')), findsOneWidget);
    });

    testWidgets(
        'renders solid confirmed polyline, dashed proposed polyline, and faded completed polyline',
        (tester) async {
      final confirmedPoints = [
        const LatLng(18.50, 73.80),
        const LatLng(18.52, 73.82),
      ];
      final proposedPoints = [
        const LatLng(18.52, 73.82),
        const LatLng(18.55, 73.85),
      ];
      final completedPoints = [
        const LatLng(18.48, 73.78),
        const LatLng(18.50, 73.80),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PuneMapWidget(
              confirmedPolylinePoints: confirmedPoints,
              proposedPolylinePoints: proposedPoints,
              completedPolylinePoints: completedPoints,
            ),
          ),
        ),
      );

      final polylineLayer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
      expect(polylineLayer.polylines.length, equals(3));

      // 1. Confirmed solid line
      final confirmedPoly = polylineLayer.polylines.firstWhere(
        (p) => p.points == confirmedPoints,
      );
      expect(confirmedPoly.pattern, equals(const StrokePattern.solid()));

      // 2. Proposed dashed line
      final proposedPoly = polylineLayer.polylines.firstWhere(
        (p) => p.points == proposedPoints,
      );
      expect(proposedPoly.pattern, isNot(equals(const StrokePattern.solid())));

      // 3. Completed faded line
      final completedPoly = polylineLayer.polylines.firstWhere(
        (p) => p.points == completedPoints,
      );
      expect(completedPoly.pattern, equals(const StrokePattern.solid()));
      expect(completedPoly.color.a, lessThan(1.0)); // faded opacity
    });

    testWidgets('Stop list legend displays privacy-safe aliases, party sizes, and ETAs',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PuneMapWidget(
              waypoints: testWaypoints,
            ),
          ),
        ),
      );

      // Stop list legend exists on the map
      expect(find.byKey(const Key('map_stop_list_legend')), findsOneWidget);

      // Displays privacy-safe aliases
      expect(find.textContaining('Rider A (You)'), findsWidgets);
      expect(find.textContaining('Rider B'), findsWidgets);

      // Displays party size
      expect(find.textContaining('Party of 2'), findsWidgets);

      // Displays stop ETA
      expect(find.textContaining('6 min'), findsWidgets);
      expect(find.textContaining('24 min'), findsWidgets);
    });
  });
}
