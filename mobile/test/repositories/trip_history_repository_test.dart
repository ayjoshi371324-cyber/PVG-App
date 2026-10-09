import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/repositories/trip_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocalTripHistoryRepository', () {
    late LocalTripHistoryRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = LocalTripHistoryRepository();
    });

    final sampleReceipt = TripReceipt(
      receiptId: 'rcpt-test-101',
      tripId: 'trip-test-101',
      vehicleModel: 'Tata Tigor EV',
      licensePlate: 'MH-12-RN-4821',
      driverName: 'Suresh K.',
      pickup: PuneLandmarks.kothrud,
      dropoff: PuneLandmarks.hinjawadiPhase1,
      completedAt: DateTime.parse('2026-10-10 10:30:00'),
      soloReferenceFare: 280.0,
      finalPayableFare: 171.0,
      finalDetourPercentage: 11.5,
      environmentalImpact: const EnvironmentalImpact(
        vehicleKmSaved: 8.4,
        co2SavedKg: 1.0,
      ),
      coalitionAudits: const [
        CoalitionMemberAudit(
          passengerName: 'You',
          isUser: true,
          soloFare: 280.0,
          marginalContribution: 110.0,
          shapleyFairShare: 171.0,
        ),
      ],
    );

    test('starts with empty history', () async {
      final history = await repository.getTripHistory();
      expect(history, isEmpty);
    });

    test('saves receipt and retrieves it from history', () async {
      await repository.saveReceipt(sampleReceipt);

      final history = await repository.getTripHistory();
      expect(history.length, equals(1));
      expect(history.first.receiptId, equals('rcpt-test-101'));
      expect(history.first.finalPayableFare, equals(171.0));
      expect(history.first.savings, equals(109.0));
    });

    test('stores multiple receipts with newest first', () async {
      final secondReceipt = TripReceipt(
        receiptId: 'rcpt-test-102',
        tripId: 'trip-test-102',
        vehicleModel: 'Maruti WagonR',
        licensePlate: 'MH-14-GH-9912',
        driverName: 'Amit P.',
        pickup: PuneLandmarks.swargate,
        dropoff: PuneLandmarks.vimanNagar,
        completedAt: DateTime.parse('2026-10-10 12:00:00'),
        soloReferenceFare: 240.0,
        finalPayableFare: 155.0,
        finalDetourPercentage: 8.2,
        environmentalImpact: const EnvironmentalImpact(
          vehicleKmSaved: 6.2,
          co2SavedKg: 0.74,
        ),
        coalitionAudits: const [],
      );

      await repository.saveReceipt(sampleReceipt);
      await repository.saveReceipt(secondReceipt);

      final history = await repository.getTripHistory();
      expect(history.length, equals(2));
      expect(history.first.receiptId, equals('rcpt-test-102'));
      expect(history[1].receiptId, equals('rcpt-test-101'));
    });

    test('clears history completely', () async {
      await repository.saveReceipt(sampleReceipt);
      expect((await repository.getTripHistory()).length, equals(1));

      await repository.clearHistory();
      expect(await repository.getTripHistory(), isEmpty);
    });
  });
}
