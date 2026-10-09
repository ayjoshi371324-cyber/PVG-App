import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';

void main() {
  group('ShapleyFareBreakdown', () {
    test('calculates net savings and percentage accurately', () {
      final breakdown = ShapleyFareBreakdown(
        soloFare: 280.0,
        sharedFare: 196.0,
        coalitionSize: 3,
      );

      expect(breakdown.savings, closeTo(84.0, 0.001));
      expect(breakdown.savingsPercentage, closeTo(30.0, 0.001));
      expect(breakdown.isCheaperThanSolo, isTrue);
    });

    test('throws ArgumentError if shared fare exceeds solo fare', () {
      expect(
        () => ShapleyFareBreakdown(
          soloFare: 200.0,
          sharedFare: 250.0,
          coalitionSize: 2,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('serializes and deserializes correctly via JSON', () {
      final original = ShapleyFareBreakdown(
        soloFare: 300.0,
        sharedFare: 210.0,
        coalitionSize: 2,
        explanation: 'Shapley marginal contribution split',
      );

      final json = original.toJson();
      final reconstituted = ShapleyFareBreakdown.fromJson(json);

      expect(reconstituted.soloFare, equals(300.0));
      expect(reconstituted.sharedFare, equals(210.0));
      expect(reconstituted.savings, equals(90.0));
      expect(reconstituted.savingsPercentage, equals(30.0));
      expect(reconstituted.coalitionSize, equals(2));
    });
  });

  group('PooledRideOffer', () {
    final sampleFare = ShapleyFareBreakdown(
      soloFare: 280.0,
      sharedFare: 196.0,
      coalitionSize: 3,
    );

    test('accepts detour percentages less than or equal to 15.0%', () {
      final offer = PooledRideOffer(
        offerId: 'offer-pune-001',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        detourPercentage: 11.5,
        fareBreakdown: sampleFare,
      );

      expect(offer.detourPercentage, equals(11.5));
      expect(offer.isDetourGuaranteed, isTrue);
    });

    test('strictly rejects detour percentages exceeding 15.0% by throwing DetourGuaranteeViolationException', () {
      expect(
        () => PooledRideOffer(
          offerId: 'offer-pune-violator',
          vehicleModel: 'Tata Tigor EV',
          licensePlate: 'MH-12-RN-4821',
          driverName: 'Suresh K.',
          driverRating: 4.9,
          pickup: PuneLandmarks.kothrud,
          dropoff: PuneLandmarks.hinjawadiPhase1,
          pickupEtaMinutes: 4,
          dropoffEtaMinutes: 35,
          coPassengersCount: 2,
          detourPercentage: 15.1,
          fareBreakdown: sampleFare,
        ),
        throwsA(isA<DetourGuaranteeViolationException>()),
      );
    });

    test('serializes and deserializes correctly via JSON', () {
      final original = PooledRideOffer(
        offerId: 'offer-pune-002',
        vehicleModel: 'Maruti WagonR Green',
        licensePlate: 'MH-14-GH-9912',
        driverName: 'Amit P.',
        driverRating: 4.85,
        pickup: PuneLandmarks.swargate,
        dropoff: PuneLandmarks.vimanNagar,
        pickupEtaMinutes: 5,
        dropoffEtaMinutes: 28,
        coPassengersCount: 1,
        detourPercentage: 8.4,
        fareBreakdown: sampleFare,
      );

      final json = original.toJson();
      final reconstituted = PooledRideOffer.fromJson(json);

      expect(reconstituted.offerId, equals('offer-pune-002'));
      expect(reconstituted.vehicleModel, equals('Maruti WagonR Green'));
      expect(reconstituted.licensePlate, equals('MH-14-GH-9912'));
      expect(reconstituted.driverName, equals('Amit P.'));
      expect(reconstituted.driverRating, equals(4.85));
      expect(reconstituted.detourPercentage, equals(8.4));
      expect(reconstituted.pickup.name, equals(PuneLandmarks.swargate.name));
      expect(reconstituted.dropoff.name, equals(PuneLandmarks.vimanNagar.name));
      expect(reconstituted.fareBreakdown.savings, equals(sampleFare.savings));
    });
  });
}
