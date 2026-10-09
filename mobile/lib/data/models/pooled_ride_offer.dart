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
    double? totalTripCost,
    this.partySize = 1,
    double? perPersonFare,
    this.fixedFeeShare = 0.0,
    this.marginalContribution = 0.0,
    this.marginalContributions = const {},
    this.coalitionTable = const {},
    this.passengerShares = const {},
    this.soloFares = const {},
    this.partySizes = const {},
    this.rawShare,
    this.roundingAdjustment,
  })  : totalTripCost = totalTripCost ??
            (passengerShares.isNotEmpty
                ? passengerShares.values.fold(0.0, (s, v) => s + v)
                : sharedFare),
        perPersonFare = perPersonFare ??
            (partySize > 1 ? sharedFare / partySize : sharedFare) {
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
  final double totalTripCost;
  final int partySize;
  final double perPersonFare;
  final double fixedFeeShare;
  final double marginalContribution;
  final Map<String, double> marginalContributions;
  final Map<String, double> coalitionTable;
  final Map<String, double> passengerShares;
  final Map<String, double> soloFares;
  final Map<String, int> partySizes;
  final double? rawShare;
  final double? roundingAdjustment;

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
        'totalTripCost': totalTripCost,
        'partySize': partySize,
        'perPersonFare': perPersonFare,
        'fixedFeeShare': fixedFeeShare,
        'marginalContribution': marginalContribution,
        'marginalContributions': marginalContributions,
        'coalitionTable': coalitionTable,
        'passengerShares': passengerShares,
        'soloFares': soloFares,
        'partySizes': partySizes,
        'rawShare': rawShare,
        'roundingAdjustment': roundingAdjustment,
      };

  factory ShapleyFareBreakdown.fromJson(Map<String, dynamic> json) =>
      ShapleyFareBreakdown(
        soloFare: (json['soloFare'] as num).toDouble(),
        sharedFare: (json['sharedFare'] as num).toDouble(),
        coalitionSize: (json['coalitionSize'] as num).toInt(),
        explanation: json['explanation'] as String? ??
            'Exact Shapley value allocation based on shared travel segments.',
        totalTripCost: (json['totalTripCost'] as num?)?.toDouble(),
        partySize: (json['partySize'] as num?)?.toInt() ?? 1,
        perPersonFare: (json['perPersonFare'] as num?)?.toDouble(),
        fixedFeeShare: (json['fixedFeeShare'] as num?)?.toDouble() ?? 0.0,
        marginalContribution:
            (json['marginalContribution'] as num?)?.toDouble() ?? 0.0,
        marginalContributions:
            (json['marginalContributions'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                ) ??
                const {},
        coalitionTable:
            (json['coalitionTable'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                ) ??
                const {},
        passengerShares:
            (json['passengerShares'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toDouble()),
                ) ??
                const {},
        soloFares: (json['soloFares'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            const {},
        partySizes: (json['partySizes'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            const {},
        rawShare: (json['rawShare'] as num?)?.toDouble(),
        roundingAdjustment: (json['roundingAdjustment'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [
        soloFare,
        sharedFare,
        coalitionSize,
        explanation,
        totalTripCost,
        partySize,
        perPersonFare,
        fixedFeeShare,
        marginalContribution,
        marginalContributions,
        coalitionTable,
        passengerShares,
        soloFares,
        partySizes,
        rawShare,
        roundingAdjustment,
      ];
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
    int? partySize,
  }) : partySize = partySize ?? fareBreakdown.partySize {
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
  final int partySize;

  /// Convenient getter for per-person fare inside parties.
  double get perPersonFare => fareBreakdown.perPersonFare;

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
        'partySize': partySize,
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
        partySize: (json['partySize'] as num?)?.toInt(),
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
        partySize,
      ];
}
