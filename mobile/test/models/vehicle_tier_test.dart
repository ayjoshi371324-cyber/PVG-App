import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';

void main() {
  group('VehicleTier Specifications', () {
    test('Auto tier has 3 seats and 0.8x multiplier', () {
      const tier = VehicleTier.auto;
      expect(tier.capacity, equals(3));
      expect(tier.rateMultiplier, equals(0.8));
      expect(tier.displayName, equals('Auto'));
      expect(tier.id, equals('auto'));
    });

    test('Car tier has 4 seats and 1.0x multiplier', () {
      const tier = VehicleTier.car;
      expect(tier.capacity, equals(4));
      expect(tier.rateMultiplier, equals(1.0));
      expect(tier.displayName, equals('Car'));
      expect(tier.id, equals('car'));
    });

    test('Car XL tier has 6 seats and 1.4x multiplier', () {
      const tier = VehicleTier.carXl;
      expect(tier.capacity, equals(6));
      expect(tier.rateMultiplier, equals(1.4));
      expect(tier.displayName, equals('Car XL'));
      expect(tier.id, equals('car_xl'));
    });

    test('canAccommodatePartySize accurately validates party size limits', () {
      expect(VehicleTier.auto.canAccommodatePartySize(1), isTrue);
      expect(VehicleTier.auto.canAccommodatePartySize(3), isTrue);
      expect(VehicleTier.auto.canAccommodatePartySize(4), isFalse);

      expect(VehicleTier.car.canAccommodatePartySize(4), isTrue);
      expect(VehicleTier.car.canAccommodatePartySize(5), isFalse);

      expect(VehicleTier.carXl.canAccommodatePartySize(6), isTrue);
      expect(VehicleTier.carXl.canAccommodatePartySize(7), isFalse);
    });

    test('disabledReason provides explanatory helper text when party size exceeds capacity', () {
      expect(VehicleTier.auto.disabledReason(4), contains('Max 3 seats'));
      expect(VehicleTier.auto.disabledReason(4), contains('party size: 4'));
      expect(VehicleTier.auto.disabledReason(3), isNull);

      expect(VehicleTier.car.disabledReason(5), contains('Max 4 seats'));
      expect(VehicleTier.car.disabledReason(4), isNull);
    });

    test('calculateEstimatedFare applies exact tier rate multiplier to base trip cost', () {
      // 10 km trip: (20 base + 10 * 10 km) = ₹120 standard
      const distanceKm = 10.0;
      expect(VehicleTier.auto.calculateEstimatedFare(distanceKm), equals(96.0));
      expect(VehicleTier.car.calculateEstimatedFare(distanceKm), equals(120.0));
      expect(VehicleTier.carXl.calculateEstimatedFare(distanceKm), equals(168.0));
    });

    test('fromString parses tier identifiers safely', () {
      expect(VehicleTier.fromId('auto'), equals(VehicleTier.auto));
      expect(VehicleTier.fromId('car'), equals(VehicleTier.car));
      expect(VehicleTier.fromId('car_xl'), equals(VehicleTier.carXl));
      expect(VehicleTier.fromId('UNKNOWN'), equals(VehicleTier.car));
    });
  });
}
