import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

/// Strict maximum detour guarantee percentage allowed across all RidePool shared rides.
const double kMaxDetourGuaranteePercentage = 15.0;

/// Thrown when a pooled ride configuration or candidate violates the <= 15.0% detour guarantee.
class DetourGuaranteeViolationException implements Exception {
  const DetourGuaranteeViolationException({
    required this.detourPercentage,
    this.maxAllowedDetour = kMaxDetourGuaranteePercentage,
  });

  final double detourPercentage;
  final double maxAllowedDetour;

  @override
  String toString() =>
      'DetourGuaranteeViolationException: Detour of ${detourPercentage.toStringAsFixed(1)}% '
      'exceeds guaranteed maximum ceiling of ${maxAllowedDetour.toStringAsFixed(1)}%.';
}

/// Transparent fare sharing breakdown based on the cooperative game theory Shapley value.
class ShapleyFareBreakdown extends Equatable {
  ShapleyFareBreakdown({
    required this.soloFare,
    required this.sharedFare,
    required this.coalitionSize,
    this.explanation = 'Exact Shapley value allocation based on shared travel segments.',
  }) {
    if (soloFare < 0 || sharedFare < 0) {
      throw ArgumentError('Fares cannot be negative.');
    }
    if (sharedFare > soloFare) {
      throw ArgumentError(
        'Shared Shapley fare (₹${sharedFare.toStringAsFixed(2)}) cannot exceed baseline solo fare (₹${soloFare.toStringAsFixed(2)}).',
      );
    }
  }

  final double soloFare;
  final double sharedFare;
  final int coalitionSize;
  final String explanation;

  /// Absolute monetary savings in ₹ compared to a solo trip.
  double get savings => soloFare - sharedFare;

  /// Net savings percentage relative to solo baseline fare.
  double get savingsPercentage =>
      soloFare > 0 ? (savings / soloFare) * 100.0 : 0.0;

  /// Whether the passenger achieves positive savings from pooling.
  bool get isCheaperThanSolo => savings > 0.0;

  Map<String, dynamic> toJson() => {
        'soloFare': soloFare,
        'sharedFare': sharedFare,
        'coalitionSize': coalitionSize,
        'explanation': explanation,
      };

  factory ShapleyFareBreakdown.fromJson(Map<String, dynamic> json) =>
      ShapleyFareBreakdown(
        soloFare: (json['soloFare'] as num).toDouble(),
        sharedFare: (json['sharedFare'] as num).toDouble(),
        coalitionSize: (json['coalitionSize'] as num).toInt(),
        explanation: json['explanation'] as String? ??
            'Exact Shapley value allocation based on shared travel segments.',
      );

  @override
  List<Object?> get props => [soloFare, sharedFare, coalitionSize, explanation];
}

/// Represents an optimized pooled ride offer presented to the passenger.
class PooledRideOffer extends Equatable {
  PooledRideOffer({
    required this.offerId,
    required this.vehicleModel,
    required this.licensePlate,
    required this.driverName,
    required this.driverRating,
    required this.pickup,
    required this.dropoff,
    required this.pickupEtaMinutes,
    required this.dropoffEtaMinutes,
    required this.coPassengersCount,
    this.coPassengerLabels = const [],
    required this.detourPercentage,
    required this.fareBreakdown,
    this.offerExpirySeconds = 20,
  }) {
    if (detourPercentage > kMaxDetourGuaranteePercentage) {
      throw DetourGuaranteeViolationException(
        detourPercentage: detourPercentage,
        maxAllowedDetour: kMaxDetourGuaranteePercentage,
      );
    }
  }

  final String offerId;
  final String vehicleModel;
  final String licensePlate;
  final String driverName;
  final double driverRating;
  final PuneLocation pickup;
  final PuneLocation dropoff;
  final int pickupEtaMinutes;
  final int dropoffEtaMinutes;
  final int coPassengersCount;
  final List<String> coPassengerLabels;
  final double detourPercentage;
  final ShapleyFareBreakdown fareBreakdown;
  final int offerExpirySeconds;

  /// Confirms that the detour is within the strict 15.0% guarantee threshold.
  bool get isDetourGuaranteed =>
      detourPercentage <= kMaxDetourGuaranteePercentage;

  Map<String, dynamic> toJson() => {
        'offerId': offerId,
        'vehicleModel': vehicleModel,
        'licensePlate': licensePlate,
        'driverName': driverName,
        'driverRating': driverRating,
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'pickupEtaMinutes': pickupEtaMinutes,
        'dropoffEtaMinutes': dropoffEtaMinutes,
        'coPassengersCount': coPassengersCount,
        'coPassengerLabels': coPassengerLabels,
        'detourPercentage': detourPercentage,
        'fareBreakdown': fareBreakdown.toJson(),
        'offerExpirySeconds': offerExpirySeconds,
      };

  factory PooledRideOffer.fromJson(Map<String, dynamic> json) =>
      PooledRideOffer(
        offerId: json['offerId'] as String,
        vehicleModel: json['vehicleModel'] as String,
        licensePlate: json['licensePlate'] as String,
        driverName: json['driverName'] as String,
        driverRating: (json['driverRating'] as num).toDouble(),
        pickup: PuneLocation.fromJson(json['pickup'] as Map<String, dynamic>),
        dropoff:
            PuneLocation.fromJson(json['dropoff'] as Map<String, dynamic>),
        pickupEtaMinutes: (json['pickupEtaMinutes'] as num).toInt(),
        dropoffEtaMinutes: (json['dropoffEtaMinutes'] as num).toInt(),
        coPassengersCount: (json['coPassengersCount'] as num).toInt(),
        coPassengerLabels: (json['coPassengerLabels'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        detourPercentage: (json['detourPercentage'] as num).toDouble(),
        fareBreakdown: ShapleyFareBreakdown.fromJson(
            json['fareBreakdown'] as Map<String, dynamic>),
        offerExpirySeconds: (json['offerExpirySeconds'] as num?)?.toInt() ?? 20,
      );

  @override
  List<Object?> get props => [
        offerId,
        vehicleModel,
        licensePlate,
        driverName,
        driverRating,
        pickup,
        dropoff,
        pickupEtaMinutes,
        dropoffEtaMinutes,
        coPassengersCount,
        coPassengerLabels,
        detourPercentage,
        fareBreakdown,
        offerExpirySeconds,
      ];
}
