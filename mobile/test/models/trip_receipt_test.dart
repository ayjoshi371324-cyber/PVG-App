import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';

void main() {
  group('EnvironmentalImpact', () {
    test('calculates CO2 and vehicle km reduction accurately', () {
      const impact = EnvironmentalImpact(
        vehicleKmSaved: 8.5,
        co2SavedKg: 1.02,
      );

      expect(impact.vehicleKmSaved, equals(8.5));
      expect(impact.co2SavedKg, equals(1.02));
      expect(impact.formattedKm, equals('8.5 km saved'));
      expect(impact.formattedCo2, equals('1.02 kg CO₂ avoided'));
    });

    test('serializes and deserializes via JSON', () {
      const original = EnvironmentalImpact(
        vehicleKmSaved: 10.0,
        co2SavedKg: 1.2,
      );

      final json = original.toJson();
      final reconstituted = EnvironmentalImpact.fromJson(json);

      expect(reconstituted.vehicleKmSaved, equals(10.0));
      expect(reconstituted.co2SavedKg, equals(1.2));
    });
  });

  group('CoalitionMemberAudit', () {
    test('verifies marginal contributions and individual savings', () {
      const audit = CoalitionMemberAudit(
        passengerName: 'You',
        isUser: true,
        soloFare: 280.0,
        marginalContribution: 110.0,
        shapleyFairShare: 171.0,
      );

      expect(audit.savings, closeTo(109.0, 0.001));
      expect(audit.savingsPercentage, closeTo(38.9, 0.1));
    });
  });

  group('TripReceipt', () {
    final sampleReceipt = TripReceipt(
      receiptId: 'rcpt-001',
      tripId: 'trip-001',
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
        CoalitionMemberAudit(
          passengerName: 'Priya',
          soloFare: 210.0,
          marginalContribution: 90.0,
          shapleyFairShare: 135.0,
        ),
        CoalitionMemberAudit(
          passengerName: 'Vikram',
          soloFare: 180.0,
          marginalContribution: 80.0,
          shapleyFairShare: 120.0,
        ),
      ],
    );

    test('computes savings and discounts correctly', () {
      expect(sampleReceipt.savings, equals(109.0));
      expect(sampleReceipt.savingsPercentage, closeTo(38.9, 0.1));
      expect(sampleReceipt.isDetourGuaranteed, isTrue);
    });

    test('serializes and deserializes completely via JSON', () {
      final json = sampleReceipt.toJson();
      final reconstituted = TripReceipt.fromJson(json);

      expect(reconstituted.receiptId, equals('rcpt-001'));
      expect(reconstituted.vehicleModel, equals('Tata Tigor EV'));
      expect(reconstituted.driverName, equals('Suresh K.'));
      expect(reconstituted.finalPayableFare, equals(171.0));
      expect(reconstituted.soloReferenceFare, equals(280.0));
      expect(reconstituted.savings, equals(109.0));
      expect(reconstituted.coalitionAudits.length, equals(3));
      expect(reconstituted.environmentalImpact.vehicleKmSaved, equals(8.4));
      expect(reconstituted.effectiveFarePaise, equals(17100));
      expect(reconstituted.effectiveDriverPayoutPaise, equals(14535));
      expect(reconstituted.paymentStatus, equals(PaymentStatus.completed));
      expect(reconstituted.environmentalImpact.formattedFuelSaved, contains('fuel saved'));
    });
  });
}
