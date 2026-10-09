import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

enum WaypointType {
  pickup,
  dropoff,
}

enum WaypointStatus {
  pending,
  current,
  completed,
}

/// A discrete stop milestone along the shared pooled ride route.
class TripWaypoint extends Equatable {
  const TripWaypoint({
    required this.id,
    required this.location,
    required this.passengerName,
    this.isUser = false,
    required this.type,
    this.status = WaypointStatus.pending,
    required this.estimatedMinutes,
    this.bookingId = '',
    this.bookingIndex = 1,
    this.passengerAlias = 'You',
    this.partySize = 1,
    this.stopSequence = 1,
    this.markerCode = 'P1',
    this.bookingColor = BookingColors.booking1,
  });

  final String id;
  final PuneLocation location;
  final String passengerName;
  final bool isUser;
  final WaypointType type;
  final WaypointStatus status;
  final int estimatedMinutes;
  final String bookingId;
  final int bookingIndex;
  final String passengerAlias;
  final int partySize;
  final int stopSequence;
  final String markerCode;
  final Color bookingColor;

  String get label =>
      '${type == WaypointType.pickup ? "Pickup" : "Drop off"} $passengerName at ${location.name}';

  TripWaypoint copyWith({
    String? id,
    PuneLocation? location,
    String? passengerName,
    bool? isUser,
    WaypointType? type,
    WaypointStatus? status,
    int? estimatedMinutes,
    String? bookingId,
    int? bookingIndex,
    String? passengerAlias,
    int? partySize,
    int? stopSequence,
    String? markerCode,
    Color? bookingColor,
  }) {
    return TripWaypoint(
      id: id ?? this.id,
      location: location ?? this.location,
      passengerName: passengerName ?? this.passengerName,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      bookingId: bookingId ?? this.bookingId,
      bookingIndex: bookingIndex ?? this.bookingIndex,
      passengerAlias: passengerAlias ?? this.passengerAlias,
      partySize: partySize ?? this.partySize,
      stopSequence: stopSequence ?? this.stopSequence,
      markerCode: markerCode ?? this.markerCode,
      bookingColor: bookingColor ?? this.bookingColor,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'location': location.toJson(),
        'passengerName': passengerName,
        'isUser': isUser,
        'type': type.name,
        'status': status.name,
        'estimatedMinutes': estimatedMinutes,
        'bookingId': bookingId,
        'bookingIndex': bookingIndex,
        'passengerAlias': passengerAlias,
        'partySize': partySize,
        'stopSequence': stopSequence,
        'markerCode': markerCode,
      };

  factory TripWaypoint.fromJson(Map<String, dynamic> json) {
    final bIndex = (json['bookingIndex'] as num?)?.toInt() ?? 1;
    return TripWaypoint(
      id: json['id'] as String,
      location:
          PuneLocation.fromJson(json['location'] as Map<String, dynamic>),
      passengerName: json['passengerName'] as String,
      isUser: json['isUser'] as bool? ?? false,
      type: WaypointType.values.byName(json['type'] as String),
      status: WaypointStatus.values.byName(json['status'] as String),
      estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
      bookingId: json['bookingId'] as String? ?? '',
      bookingIndex: bIndex,
      passengerAlias: json['passengerAlias'] as String? ?? json['passengerName'] as String,
      partySize: (json['partySize'] as num?)?.toInt() ?? 1,
      stopSequence: (json['stopSequence'] as num?)?.toInt() ?? 1,
      markerCode: json['markerCode'] as String? ?? (json['type'] == 'pickup' ? 'P$bIndex' : 'D$bIndex'),
      bookingColor: BookingColors.getColor(bIndex),
    );
  }

  @override
  List<Object?> get props => [
        id,
        location,
        passengerName,
        isUser,
        type,
        status,
        estimatedMinutes,
        bookingId,
        bookingIndex,
        passengerAlias,
        partySize,
        stopSequence,
        markerCode,
        bookingColor,
      ];
}

/// A dynamic mid-trip pooling join proposal requiring passenger consent.
class MidTripJoinRequest extends Equatable {
  MidTripJoinRequest({
    required this.requestId,
    required this.passengerName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.previousDetourPercentage,
    required this.newDetourPercentage,
    required this.additionalSavings,
    required this.newSharedFare,
    this.etaDeltaMinutes = 3,
    this.updatedEtaMinutes = 26,
    this.secondsRemaining = 30,
  }) {
    if (newDetourPercentage > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: newDetourPercentage,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }
  }

  final String requestId;
  final String passengerName;
  final PuneLocation pickupLocation;
  final PuneLocation dropoffLocation;
  final double previousDetourPercentage;
  final double newDetourPercentage;
  final double additionalSavings;
  final double newSharedFare;
  final int etaDeltaMinutes;
  final int updatedEtaMinutes;
  final int secondsRemaining;

  bool get isDetourGuaranteed =>
      newDetourPercentage <= kMaxDetourGuaranteePercentage;

  double get detourDelta => newDetourPercentage - previousDetourPercentage;

  MidTripJoinRequest copyWith({
    String? requestId,
    String? passengerName,
    PuneLocation? pickupLocation,
    PuneLocation? dropoffLocation,
    double? previousDetourPercentage,
    double? newDetourPercentage,
    double? additionalSavings,
    double? newSharedFare,
    int? etaDeltaMinutes,
    int? updatedEtaMinutes,
    int? secondsRemaining,
  }) {
    return MidTripJoinRequest(
      requestId: requestId ?? this.requestId,
      passengerName: passengerName ?? this.passengerName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      previousDetourPercentage:
          previousDetourPercentage ?? this.previousDetourPercentage,
      newDetourPercentage: newDetourPercentage ?? this.newDetourPercentage,
      additionalSavings: additionalSavings ?? this.additionalSavings,
      newSharedFare: newSharedFare ?? this.newSharedFare,
      etaDeltaMinutes: etaDeltaMinutes ?? this.etaDeltaMinutes,
      updatedEtaMinutes: updatedEtaMinutes ?? this.updatedEtaMinutes,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'passengerName': passengerName,
        'pickupLocation': pickupLocation.toJson(),
        'dropoffLocation': dropoffLocation.toJson(),
        'previousDetourPercentage': previousDetourPercentage,
        'newDetourPercentage': newDetourPercentage,
        'additionalSavings': additionalSavings,
        'newSharedFare': newSharedFare,
        'etaDeltaMinutes': etaDeltaMinutes,
        'updatedEtaMinutes': updatedEtaMinutes,
        'secondsRemaining': secondsRemaining,
      };

  factory MidTripJoinRequest.fromJson(Map<String, dynamic> json) {
    final newDetour = (json['newDetourPercentage'] as num).toDouble();
    if (newDetour > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: newDetour,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }

    return MidTripJoinRequest(
      requestId: json['requestId'] as String,
      passengerName: json['passengerName'] as String,
      pickupLocation: PuneLocation.fromJson(
          json['pickupLocation'] as Map<String, dynamic>),
      dropoffLocation: PuneLocation.fromJson(
          json['dropoffLocation'] as Map<String, dynamic>),
      previousDetourPercentage:
          (json['previousDetourPercentage'] as num).toDouble(),
      newDetourPercentage: newDetour,
      additionalSavings: (json['additionalSavings'] as num).toDouble(),
      newSharedFare: (json['newSharedFare'] as num).toDouble(),
      etaDeltaMinutes: (json['etaDeltaMinutes'] as num?)?.toInt() ?? 3,
      updatedEtaMinutes: (json['updatedEtaMinutes'] as num?)?.toInt() ?? 26,
      secondsRemaining: (json['secondsRemaining'] as num?)?.toInt() ?? 30,
    );
  }

  @override
  List<Object?> get props => [
        requestId,
        passengerName,
        pickupLocation,
        dropoffLocation,
        previousDetourPercentage,
        newDetourPercentage,
        additionalSavings,
        newSharedFare,
        etaDeltaMinutes,
        updatedEtaMinutes,
        secondsRemaining,
      ];
}

/// Active dispatched ride tracking state including milestones and vehicle position.
class ActiveTrip extends Equatable {
  const ActiveTrip({
    required this.tripId,
    required this.offer,
    required this.waypoints,
    this.currentWaypointIndex = 0,
    required this.vehiclePosition,
    required this.currentDetourPercentage,
    this.pendingJoinRequest,
    this.pickupOtp = '4821',
  });

  final String tripId;
  final PooledRideOffer offer;
  final List<TripWaypoint> waypoints;
  final int currentWaypointIndex;
  final LatLng vehiclePosition;
  final double currentDetourPercentage;
  final MidTripJoinRequest? pendingJoinRequest;
  final String pickupOtp;

  bool get isCompleted => currentWaypointIndex >= waypoints.length;

  bool get isUserPickupPending {
    final userPickupIndex =
        waypoints.indexWhere((w) => w.isUser && w.type == WaypointType.pickup);
    if (userPickupIndex == -1) return false;
    return currentWaypointIndex <= userPickupIndex;
  }

  double get progress => waypoints.isEmpty
      ? 0.0
      : (currentWaypointIndex / waypoints.length).clamp(0.0, 1.0);

  TripWaypoint? get currentWaypoint =>
      (currentWaypointIndex >= 0 && currentWaypointIndex < waypoints.length)
          ? waypoints[currentWaypointIndex]
          : null;

  factory ActiveTrip.fromOffer({
    required PooledRideOffer offer,
    LatLng? vehiclePosition,
    String? pickupOtp,
  }) {
    // Scaffold multi-stop pooled manifest matching Pune corridor
    final waypoints = <TripWaypoint>[
      TripWaypoint(
        id: 'wp-usr-pickup',
        location: offer.pickup,
        passengerName: 'You',
        passengerAlias: 'Rider A (You)',
        partySize: offer.partySize,
        isUser: true,
        type: WaypointType.pickup,
        status: WaypointStatus.current,
        estimatedMinutes: offer.pickupEtaMinutes,
        bookingId: 'book-1',
        bookingIndex: 1,
        stopSequence: 1,
        markerCode: 'P1',
        bookingColor: BookingColors.booking1,
      ),
      if (offer.coPassengersCount > 0)
        TripWaypoint(
          id: 'wp-co-01',
          location: PuneLandmarks.swargate,
          passengerName: offer.coPassengerLabels.isNotEmpty
              ? offer.coPassengerLabels.first.split(' ').first
              : 'Priya',
          passengerAlias: 'Rider B',
          partySize: 1,
          type: WaypointType.pickup,
          status: WaypointStatus.pending,
          estimatedMinutes: offer.pickupEtaMinutes + 6,
          bookingId: 'book-2',
          bookingIndex: 2,
          stopSequence: 2,
          markerCode: 'P2',
          bookingColor: BookingColors.booking2,
        ),
      TripWaypoint(
        id: 'wp-usr-dropoff',
        location: offer.dropoff,
        passengerName: 'You',
        passengerAlias: 'Rider A (You)',
        partySize: offer.partySize,
        isUser: true,
        type: WaypointType.dropoff,
        status: WaypointStatus.pending,
        estimatedMinutes: offer.dropoffEtaMinutes,
        bookingId: 'book-1',
        bookingIndex: 1,
        stopSequence: offer.coPassengersCount > 0 ? 3 : 2,
        markerCode: 'D1',
        bookingColor: BookingColors.booking1,
      ),
      if (offer.coPassengersCount > 0)
        TripWaypoint(
          id: 'wp-co-01-dropoff',
          location: PuneLandmarks.hinjawadiPhase1,
          passengerName: offer.coPassengerLabels.isNotEmpty
              ? offer.coPassengerLabels.first.split(' ').first
              : 'Priya',
          passengerAlias: 'Rider B',
          partySize: 1,
          type: WaypointType.dropoff,
          status: WaypointStatus.pending,
          estimatedMinutes: offer.dropoffEtaMinutes + 5,
          bookingId: 'book-2',
          bookingIndex: 2,
          stopSequence: 4,
          markerCode: 'D2',
          bookingColor: BookingColors.booking2,
        ),
    ];

    final initialPos = vehiclePosition ??
        LatLng(
          offer.pickup.latitude - 0.008,
          offer.pickup.longitude - 0.006,
        );

    return ActiveTrip(
      tripId: 'trip-${offer.offerId}',
      offer: offer,
      waypoints: waypoints,
      currentWaypointIndex: 0,
      vehiclePosition: initialPos,
      currentDetourPercentage: offer.detourPercentage,
      pickupOtp: pickupOtp ?? '4821',
    );
  }

  ActiveTrip advanceWaypoint() {
    if (isCompleted) return this;

    final updatedWaypoints = List<TripWaypoint>.from(waypoints);
    // Mark current completed
    if (currentWaypointIndex < updatedWaypoints.length) {
      updatedWaypoints[currentWaypointIndex] =
          updatedWaypoints[currentWaypointIndex]
              .copyWith(status: WaypointStatus.completed);
    }

    final nextIndex = currentWaypointIndex + 1;
    // Mark next current
    if (nextIndex < updatedWaypoints.length) {
      updatedWaypoints[nextIndex] = updatedWaypoints[nextIndex]
          .copyWith(status: WaypointStatus.current);
    }

    final nextPos = (nextIndex < updatedWaypoints.length)
        ? updatedWaypoints[nextIndex].location.toLatLng()
        : vehiclePosition;

    return copyWith(
      waypoints: updatedWaypoints,
      currentWaypointIndex: nextIndex,
      vehiclePosition: nextPos,
    );
  }

  ActiveTrip applyMidTripJoin(MidTripJoinRequest request) {
    if (request.newDetourPercentage > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: request.newDetourPercentage,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }

    final updated = List<TripWaypoint>.from(waypoints);
    // Insert new pickup before user's final dropoff
    final userDropoffIndex =
        updated.indexWhere((w) => w.isUser && w.type == WaypointType.dropoff);

    final insertIndex =
        userDropoffIndex != -1 ? userDropoffIndex : updated.length;

    final joinBookingIndex = 3;
    final joinColor = BookingColors.getColor(joinBookingIndex);

    updated.insert(
      insertIndex,
      TripWaypoint(
        id: 'wp-join-${request.requestId}',
        location: request.pickupLocation,
        passengerName: request.passengerName,
        passengerAlias: 'Rider C',
        partySize: 1,
        type: WaypointType.pickup,
        status: WaypointStatus.pending,
        estimatedMinutes: 5,
        bookingId: 'book-$joinBookingIndex',
        bookingIndex: joinBookingIndex,
        stopSequence: insertIndex + 1,
        markerCode: 'P$joinBookingIndex',
        bookingColor: joinColor,
      ),
    );

    // Also add dropoff for joiner after user's dropoff if needed
    updated.add(
      TripWaypoint(
        id: 'wp-join-drop-${request.requestId}',
        location: request.dropoffLocation,
        passengerName: request.passengerName,
        passengerAlias: 'Rider C',
        partySize: 1,
        type: WaypointType.dropoff,
        status: WaypointStatus.pending,
        estimatedMinutes: 20,
        bookingId: 'book-$joinBookingIndex',
        bookingIndex: joinBookingIndex,
        stopSequence: updated.length + 1,
        markerCode: 'D$joinBookingIndex',
        bookingColor: joinColor,
      ),
    );

    // Re-index stopSequence
    for (int i = 0; i < updated.length; i++) {
      updated[i] = updated[i].copyWith(stopSequence: i + 1);
    }

    return copyWith(
      waypoints: updated,
      currentDetourPercentage: request.newDetourPercentage,
      clearPendingJoinRequest: true,
    );
  }

  ActiveTrip copyWith({
    String? tripId,
    PooledRideOffer? offer,
    List<TripWaypoint>? waypoints,
    int? currentWaypointIndex,
    LatLng? vehiclePosition,
    double? currentDetourPercentage,
    MidTripJoinRequest? pendingJoinRequest,
    bool clearPendingJoinRequest = false,
    String? pickupOtp,
  }) {
    return ActiveTrip(
      tripId: tripId ?? this.tripId,
      offer: offer ?? this.offer,
      waypoints: waypoints ?? this.waypoints,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      vehiclePosition: vehiclePosition ?? this.vehiclePosition,
      currentDetourPercentage:
          currentDetourPercentage ?? this.currentDetourPercentage,
      pendingJoinRequest: clearPendingJoinRequest
          ? null
          : (pendingJoinRequest ?? this.pendingJoinRequest),
      pickupOtp: pickupOtp ?? this.pickupOtp,
    );
  }

  @override
  List<Object?> get props => [
        tripId,
        offer,
        waypoints,
        currentWaypointIndex,
        vehiclePosition,
        currentDetourPercentage,
        pendingJoinRequest,
        pickupOtp,
      ];
}
