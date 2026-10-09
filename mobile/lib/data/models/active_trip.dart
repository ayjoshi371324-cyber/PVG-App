import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/core/route_estimator.dart';
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
  });

  final String id;
  final PuneLocation location;
  final String passengerName;
  final bool isUser;
  final WaypointType type;
  final WaypointStatus status;
  final int estimatedMinutes;

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
  }) {
    return TripWaypoint(
      id: id ?? this.id,
      location: location ?? this.location,
      passengerName: passengerName ?? this.passengerName,
      isUser: isUser ?? this.isUser,
      type: type ?? this.type,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
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
      };

  factory TripWaypoint.fromJson(Map<String, dynamic> json) => TripWaypoint(
        id: json['id'] as String,
        location:
            PuneLocation.fromJson(json['location'] as Map<String, dynamic>),
        passengerName: json['passengerName'] as String,
        isUser: json['isUser'] as bool? ?? false,
        type: WaypointType.values.byName(json['type'] as String),
        status: WaypointStatus.values.byName(json['status'] as String),
        estimatedMinutes: (json['estimatedMinutes'] as num).toInt(),
      );

  @override
  List<Object?> get props => [
        id,
        location,
        passengerName,
        isUser,
        type,
        status,
        estimatedMinutes,
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

  bool get isDetourGuaranteed =>
      newDetourPercentage <= kMaxDetourGuaranteePercentage;

  double get detourDelta => newDetourPercentage - previousDetourPercentage;

  Map<String, dynamic> toJson() => {
        'requestId': requestId,
        'passengerName': passengerName,
        'pickupLocation': pickupLocation.toJson(),
        'dropoffLocation': dropoffLocation.toJson(),
        'previousDetourPercentage': previousDetourPercentage,
        'newDetourPercentage': newDetourPercentage,
        'additionalSavings': additionalSavings,
        'newSharedFare': newSharedFare,
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
  });

  final String tripId;
  final PooledRideOffer offer;
  final List<TripWaypoint> waypoints;
  final int currentWaypointIndex;
  final LatLng vehiclePosition;
  final double currentDetourPercentage;
  final MidTripJoinRequest? pendingJoinRequest;

  bool get isCompleted => currentWaypointIndex >= waypoints.length;

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
  }) {
    // Scaffold multi-stop pooled manifest matching Pune corridor
    final waypoints = <TripWaypoint>[
      TripWaypoint(
        id: 'wp-usr-pickup',
        location: offer.pickup,
        passengerName: 'You',
        isUser: true,
        type: WaypointType.pickup,
        status: WaypointStatus.current,
        estimatedMinutes: offer.pickupEtaMinutes,
      ),
      if (offer.coPassengersCount > 0)
        TripWaypoint(
          id: 'wp-co-01',
          location: PuneLandmarks.swargate,
          passengerName: offer.coPassengerLabels.isNotEmpty
              ? offer.coPassengerLabels.first.split(' ').first
              : 'Priya',
          type: WaypointType.pickup,
          status: WaypointStatus.pending,
          estimatedMinutes: offer.pickupEtaMinutes + 6,
        ),
      TripWaypoint(
        id: 'wp-usr-dropoff',
        location: offer.dropoff,
        passengerName: 'You',
        isUser: true,
        type: WaypointType.dropoff,
        status: WaypointStatus.pending,
        estimatedMinutes: offer.dropoffEtaMinutes,
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

    updated.insert(
      insertIndex,
      TripWaypoint(
        id: 'wp-join-${request.requestId}',
        location: request.pickupLocation,
        passengerName: request.passengerName,
        type: WaypointType.pickup,
        status: WaypointStatus.pending,
        estimatedMinutes: 5,
      ),
    );

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
      ];
}
