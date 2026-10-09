import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

/// Environmental savings achieved by sharing the pooled ride.
class EnvironmentalImpact extends Equatable {
  const EnvironmentalImpact({
    required this.vehicleKmSaved,
    required this.co2SavedKg,
  });

  final double vehicleKmSaved;
  final double co2SavedKg;

  String get formattedKm => '${vehicleKmSaved.toStringAsFixed(1)} km saved';
  String get formattedCo2 =>
      '${co2SavedKg.toStringAsFixed(2)} kg CO₂ avoided';

  Map<String, dynamic> toJson() => {
        'vehicleKmSaved': vehicleKmSaved,
        'co2SavedKg': co2SavedKg,
      };

  factory EnvironmentalImpact.fromJson(Map<String, dynamic> json) =>
      EnvironmentalImpact(
        vehicleKmSaved: (json['vehicleKmSaved'] as num).toDouble(),
        co2SavedKg: (json['co2SavedKg'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [vehicleKmSaved, co2SavedKg];
}

/// Detailed audit entry for a passenger in the pooled coalition explaining
/// marginal cost contribution and exact Shapley cost allocation.
class CoalitionMemberAudit extends Equatable {
  const CoalitionMemberAudit({
    required this.passengerName,
    this.isUser = false,
    required this.soloFare,
    required this.marginalContribution,
    required this.shapleyFairShare,
  });

  final String passengerName;
  final bool isUser;
  final double soloFare;
  final double marginalContribution;
  final double shapleyFairShare;

  double get savings => soloFare - shapleyFairShare;

  double get savingsPercentage =>
      soloFare > 0 ? (savings / soloFare) * 100.0 : 0.0;

  Map<String, dynamic> toJson() => {
        'passengerName': passengerName,
        'isUser': isUser,
        'soloFare': soloFare,
        'marginalContribution': marginalContribution,
        'shapleyFairShare': shapleyFairShare,
      };

  factory CoalitionMemberAudit.fromJson(Map<String, dynamic> json) =>
      CoalitionMemberAudit(
        passengerName: json['passengerName'] as String,
        isUser: json['isUser'] as bool? ?? false,
        soloFare: (json['soloFare'] as num).toDouble(),
        marginalContribution:
            (json['marginalContribution'] as num).toDouble(),
        shapleyFairShare: (json['shapleyFairShare'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [
        passengerName,
        isUser,
        soloFare,
        marginalContribution,
        shapleyFairShare,
      ];
}

/// Final explainable fare receipt persisting completed trip data,
/// environmental savings, and Shapley game-theoretic audit breakdown.
class TripReceipt extends Equatable {
  const TripReceipt({
    required this.receiptId,
    required this.tripId,
    required this.vehicleModel,
    required this.licensePlate,
    required this.driverName,
    required this.pickup,
    required this.dropoff,
    required this.completedAt,
    required this.soloReferenceFare,
    required this.finalPayableFare,
    required this.finalDetourPercentage,
    required this.environmentalImpact,
    required this.coalitionAudits,
  });

  final String receiptId;
  final String tripId;
  final String vehicleModel;
  final String licensePlate;
  final String driverName;
  final PuneLocation pickup;
  final PuneLocation dropoff;
  final DateTime completedAt;
  final double soloReferenceFare;
  final double finalPayableFare;
  final double finalDetourPercentage;
  final EnvironmentalImpact environmentalImpact;
  final List<CoalitionMemberAudit> coalitionAudits;

  double get savings => soloReferenceFare - finalPayableFare;

  double get savingsPercentage =>
      soloReferenceFare > 0 ? (savings / soloReferenceFare) * 100.0 : 0.0;

  bool get isDetourGuaranteed =>
      finalDetourPercentage <= kMaxDetourGuaranteePercentage;

  Map<String, dynamic> toJson() => {
        'receiptId': receiptId,
        'tripId': tripId,
        'vehicleModel': vehicleModel,
        'licensePlate': licensePlate,
        'driverName': driverName,
        'pickup': pickup.toJson(),
        'dropoff': dropoff.toJson(),
        'completedAt': completedAt.toIso8601String(),
        'soloReferenceFare': soloReferenceFare,
        'finalPayableFare': finalPayableFare,
        'finalDetourPercentage': finalDetourPercentage,
        'environmentalImpact': environmentalImpact.toJson(),
        'coalitionAudits': coalitionAudits.map((a) => a.toJson()).toList(),
      };

  factory TripReceipt.fromJson(Map<String, dynamic> json) => TripReceipt(
        receiptId: json['receiptId'] as String,
        tripId: json['tripId'] as String,
        vehicleModel: json['vehicleModel'] as String,
        licensePlate: json['licensePlate'] as String,
        driverName: json['driverName'] as String,
        pickup: PuneLocation.fromJson(json['pickup'] as Map<String, dynamic>),
        dropoff:
            PuneLocation.fromJson(json['dropoff'] as Map<String, dynamic>),
        completedAt: DateTime.parse(json['completedAt'] as String),
        soloReferenceFare: (json['soloReferenceFare'] as num).toDouble(),
        finalPayableFare: (json['finalPayableFare'] as num).toDouble(),
        finalDetourPercentage:
            (json['finalDetourPercentage'] as num).toDouble(),
        environmentalImpact: EnvironmentalImpact.fromJson(
            json['environmentalImpact'] as Map<String, dynamic>),
        coalitionAudits: (json['coalitionAudits'] as List<dynamic>)
            .map((e) =>
                CoalitionMemberAudit.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [
        receiptId,
        tripId,
        vehicleModel,
        licensePlate,
        driverName,
        pickup,
        dropoff,
        completedAt,
        soloReferenceFare,
        finalPayableFare,
        finalDetourPercentage,
        environmentalImpact,
        coalitionAudits,
      ];
}
