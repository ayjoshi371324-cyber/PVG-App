import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/driver_manifest.dart';
import 'package:ridepool_app/widgets/cabin_occupancy_gauge.dart';

void main() {
  group('CabinOccupancyGauge Widget Tests', () {
    testWidgets('renders occupancy fraction and seat breakdown correctly for empty cabin', (tester) async {
      final seats = [
        const CabinSeat(seatIndex: 0, label: 'Front'),
        const CabinSeat(seatIndex: 1, label: 'Rear L'),
        const CabinSeat(seatIndex: 2, label: 'Rear C'),
        const CabinSeat(seatIndex: 3, label: 'Rear R'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: CabinOccupancyGauge(
              currentOccupancy: 0,
              maxCapacity: 4,
              seats: seats,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/4 Seats'), findsOneWidget);
      expect(find.text('Cabin Available'), findsOneWidget);
      expect(find.byKey(const Key('cabin_seat_0')), findsOneWidget);
      expect(find.byKey(const Key('cabin_seat_1')), findsOneWidget);
      expect(find.byKey(const Key('cabin_seat_2')), findsOneWidget);
      expect(find.byKey(const Key('cabin_seat_3')), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
    });

    testWidgets('renders occupied seats with passenger names and indicators', (tester) async {
      final seats = [
        const CabinSeat(seatIndex: 0, label: 'Front', passengerName: 'Aakash S.', passengerId: 'pax-1'),
        const CabinSeat(seatIndex: 1, label: 'Rear L', passengerName: 'Pooja P.', passengerId: 'pax-2'),
        const CabinSeat(seatIndex: 2, label: 'Rear C', passengerName: 'Pooja P.', passengerId: 'pax-2'),
        const CabinSeat(seatIndex: 3, label: 'Rear R'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: CabinOccupancyGauge(
              currentOccupancy: 3,
              maxCapacity: 4,
              seats: seats,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3/4 Seats'), findsOneWidget);
      expect(find.text('Aakash S.'), findsOneWidget);
      expect(find.text('Pooja P.'), findsAtLeastNWidgets(1));
    });

    testWidgets('displays Full capacity warning when 4/4 seats filled', (tester) async {
      final seats = [
        const CabinSeat(seatIndex: 0, label: 'Front', passengerName: 'Aakash S.', passengerId: 'pax-1'),
        const CabinSeat(seatIndex: 1, label: 'Rear L', passengerName: 'Pooja P.', passengerId: 'pax-2'),
        const CabinSeat(seatIndex: 2, label: 'Rear C', passengerName: 'Rohan M.', passengerId: 'pax-3'),
        const CabinSeat(seatIndex: 3, label: 'Rear R', passengerName: 'Sneha K.', passengerId: 'pax-4'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: CabinOccupancyGauge(
              currentOccupancy: 4,
              maxCapacity: 4,
              seats: seats,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('4/4 Seats'), findsOneWidget);
      expect(find.text('Cabin Full'), findsOneWidget);
    });
  });
}
