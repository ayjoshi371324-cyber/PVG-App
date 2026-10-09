import 'package:equatable/equatable.dart';
import 'package:ridepool_app/core/engine/mid_trip_insertion_engine.dart';
import 'package:ridepool_app/core/engine/seat_ledger.dart';
import 'package:ridepool_app/data/models/active_trip.dart';

/// Status of a multi-party consent session for mid-trip join.
enum ConsentSessionStatus {
  pending,
  approved,
  rejected,
  timedOut,
}

/// Multi-Party Dynamic Consent Coordinator.
///
/// Coordinates two-way/multi-way consent between the in-flight driver and all
/// impacted riders with a strict 30s countdown.
/// Manages temporary seat holds in the [SeatLedger].
/// If rejected or timed out, cleanly rolls back without altering active trips.
class MultiPartyConsentCoordinator extends Equatable {
  const MultiPartyConsentCoordinator({
    required this.proposal,
    required this.ledger,
    required this.requiredParticipantIds,
    required this.votes,
    required this.remainingSeconds,
    required this.status,
  });

  final MidTripJoinProposal proposal;
  final SeatLedger ledger;
  final Set<String> requiredParticipantIds;
  final Map<String, bool> votes;
  final int remainingSeconds;
  final ConsentSessionStatus status;

  /// Initiates a multi-party consent session with a 30s countdown and candidate seat hold.
  factory MultiPartyConsentCoordinator.initiate({
    required MidTripJoinProposal proposal,
    required SeatLedger seatLedger,
    required Set<String> requiredParticipantIds,
    int countdownSeconds = 30,
  }) {
    // Hold candidate's seats in ledger for the duration of the countdown
    final heldLedger = seatLedger.holdSeats(
      bookingId: proposal.candidateId,
      partySize: proposal.candidatePartySize,
      expiresAt: DateTime.now().add(Duration(seconds: countdownSeconds)),
    );

    return MultiPartyConsentCoordinator(
      proposal: proposal,
      ledger: heldLedger,
      requiredParticipantIds: requiredParticipantIds,
      votes: const {},
      remainingSeconds: countdownSeconds,
      status: ConsentSessionStatus.pending,
    );
  }

  Set<String> get pendingParticipants {
    return requiredParticipantIds.difference(votes.keys.toSet());
  }

  bool get isUnanimousApproved {
    if (requiredParticipantIds.isEmpty) return false;
    for (final id in requiredParticipantIds) {
      if (votes[id] != true) return false;
    }
    return true;
  }

  /// Ticks the 30-second countdown timer. Times out if reached 0.
  MultiPartyConsentCoordinator tick() {
    if (status != ConsentSessionStatus.pending) return this;

    final nextRemaining = remainingSeconds - 1;
    if (nextRemaining <= 0) {
      return MultiPartyConsentCoordinator(
        proposal: proposal,
        ledger: ledger,
        requiredParticipantIds: requiredParticipantIds,
        votes: votes,
        remainingSeconds: 0,
        status: ConsentSessionStatus.timedOut,
      );
    }

    return MultiPartyConsentCoordinator(
      proposal: proposal,
      ledger: ledger,
      requiredParticipantIds: requiredParticipantIds,
      votes: votes,
      remainingSeconds: nextRemaining,
      status: ConsentSessionStatus.pending,
    );
  }

  /// Records a participant's vote (approve or reject).
  MultiPartyConsentCoordinator submitVote({
    required String participantId,
    required bool approve,
  }) {
    if (status != ConsentSessionStatus.pending) return this;

    final updatedVotes = Map<String, bool>.from(votes)..[participantId] = approve;

    if (!approve) {
      return MultiPartyConsentCoordinator(
        proposal: proposal,
        ledger: ledger,
        requiredParticipantIds: requiredParticipantIds,
        votes: updatedVotes,
        remainingSeconds: remainingSeconds,
        status: ConsentSessionStatus.rejected,
      );
    }

    // Check if all required participants have approved
    bool allApproved = true;
    for (final id in requiredParticipantIds) {
      if (updatedVotes[id] != true) {
        allApproved = false;
        break;
      }
    }

    return MultiPartyConsentCoordinator(
      proposal: proposal,
      ledger: ledger,
      requiredParticipantIds: requiredParticipantIds,
      votes: updatedVotes,
      remainingSeconds: remainingSeconds,
      status: allApproved ? ConsentSessionStatus.approved : ConsentSessionStatus.pending,
    );
  }

  /// Cleanly rolls back ledger by releasing held seats.
  SeatLedger rollbackLedger() {
    return ledger.releaseHeldSeats(
      bookingId: proposal.candidateId,
      partySize: proposal.candidatePartySize,
    );
  }

  /// Confirms held seats in ledger upon unanimous approval.
  SeatLedger commitLedger() {
    return ledger.confirmSeats(
      bookingId: proposal.candidateId,
      partySize: proposal.candidatePartySize,
    );
  }

  /// Applies the approved proposal to the active trip.
  ActiveTrip commitTrip(ActiveTrip currentTrip) {
    if (status != ConsentSessionStatus.approved) return currentTrip;
    final joinReq = proposal.toJoinRequest();
    return currentTrip.applyMidTripJoin(joinReq);
  }

  @override
  List<Object?> get props => [
        proposal,
        ledger,
        requiredParticipantIds,
        votes,
        remainingSeconds,
        status,
      ];
}
