import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/mid_trip_insertion_engine.dart';
import 'package:ridepool_app/core/engine/multi_party_consent_coordinator.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/active_trip.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

void main() {
  group('MultiPartyConsentCoordinator - TDD Seam 2', () {
    late ActiveTrip initialTrip;
    late SeatLedger initialLedger;
    late MidTripJoinProposal sampleProposal;

    setUp(() {
      initialLedger = SeatLedger.empty(capacity: 4)
          .holdSeats(bookingId: 'book-1', partySize: 1)
          .confirmSeats(bookingId: 'book-1', partySize: 1);

      final offer = PooledRideOffer(
        offerId: 'offer-init-1',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 3,
        dropoffEtaMinutes: 24,
        coPassengersCount: 0,
        detourPercentage: 0.0,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 200.0,
          sharedFare: 200.0,
          coalitionSize: 1,
        ),
      );

      initialTrip = ActiveTrip.fromOffer(offer: offer);

      const bavdhan = PuneLocation(
        name: 'Bavdhan Flyover',
        latitude: 18.5126,
        longitude: 73.7712,
      );

      sampleProposal = MidTripJoinProposal(
        proposalId: 'prop-test-42',
        candidateId: 'book-candidate-1',
        candidateName: 'Vikram S.',
        candidatePickup: bavdhan,
        candidateDropoff: PuneLandmarks.hinjawadiPhase1,
        candidatePartySize: 1,
        candidateFare: 110.0,
        candidateSoloFare: 160.0,
        newDetourPercentage: 6.2,
        previousDetourPercentage: 0.0,
        additionalSavings: 45.0,
        newTotalDistanceKm: 14.8,
        orderedStops: const [],
        existingRiderDeltas: const {
          'book-1': ExistingRiderDelta(
            bookingId: 'book-1',
            passengerName: 'You',
            previousFare: 200.0,
            updatedFare: 155.0,
            fareSavingsDelta: 45.0,
            previousEtaMinutes: 24,
            updatedEtaMinutes: 27,
            etaDeltaMinutes: 3,
            previousDetourPercentage: 0.0,
            updatedDetourPercentage: 6.2,
            detourDeltaPercentage: 6.2,
          ),
        },
      );
    });

    test('initializes with 30s countdown, holds candidate seats in ledger, and sets required participants', () {
      final coordinator = MultiPartyConsentCoordinator.initiate(
        proposal: sampleProposal,
        seatLedger: initialLedger,
        requiredParticipantIds: {'driver', 'book-1'},
      );

      expect(coordinator.remainingSeconds, equals(30));
      expect(coordinator.status, equals(ConsentSessionStatus.pending));
      expect(coordinator.ledger.held, equals(1)); // Candidate's 1 seat is held
      expect(coordinator.ledger.available, equals(2)); // 4 capacity - 1 reserved - 1 held = 2
      expect(coordinator.pendingParticipants, containsAll(['driver', 'book-1']));
    });

    test('cleanly rolls back without altering active trip when any participant rejects', () {
      var coordinator = MultiPartyConsentCoordinator.initiate(
        proposal: sampleProposal,
        seatLedger: initialLedger,
        requiredParticipantIds: {'driver', 'book-1'},
      );

      // Driver approves
      coordinator = coordinator.submitVote(participantId: 'driver', approve: true);
      expect(coordinator.status, equals(ConsentSessionStatus.pending));

      // Existing rider rejects
      coordinator = coordinator.submitVote(participantId: 'book-1', approve: false);
      expect(coordinator.status, equals(ConsentSessionStatus.rejected));

      // Rollback releases held seats
      final rolledBackLedger = coordinator.rollbackLedger();
      expect(rolledBackLedger.held, equals(0));
      expect(rolledBackLedger.reserved, equals(1));
      expect(rolledBackLedger.available, equals(3));
    });

    test('cleanly rolls back on 30s countdown timeout', () {
      var coordinator = MultiPartyConsentCoordinator.initiate(
        proposal: sampleProposal,
        seatLedger: initialLedger,
        requiredParticipantIds: {'driver', 'book-1'},
      );

      // Tick down to 0
      for (int i = 0; i < 30; i++) {
        coordinator = coordinator.tick();
      }

      expect(coordinator.remainingSeconds, equals(0));
      expect(coordinator.status, equals(ConsentSessionStatus.timedOut));

      final rolledBackLedger = coordinator.rollbackLedger();
      expect(rolledBackLedger.held, equals(0));
      expect(rolledBackLedger.available, equals(3));
    });

    test('unanimous approval commits proposal: confirms seats in ledger and updates active trip', () {
      var coordinator = MultiPartyConsentCoordinator.initiate(
        proposal: sampleProposal,
        seatLedger: initialLedger,
        requiredParticipantIds: {'driver', 'book-1'},
      );

      // Both driver and rider approve
      coordinator = coordinator.submitVote(participantId: 'driver', approve: true);
      coordinator = coordinator.submitVote(participantId: 'book-1', approve: true);

      expect(coordinator.status, equals(ConsentSessionStatus.approved));

      // Commit confirms seats in ledger
      final committedLedger = coordinator.commitLedger();
      expect(committedLedger.held, equals(0));
      expect(committedLedger.reserved, equals(2)); // Both book-1 and candidate confirmed

      // Commit updates the active trip
      final updatedTrip = coordinator.commitTrip(initialTrip);
      expect(updatedTrip.currentDetourPercentage, equals(6.2));
      expect(
        updatedTrip.waypoints.any((w) => w.passengerName == 'Vikram S.'),
        isTrue,
      );
    });
  });
}
