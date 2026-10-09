import 'package:equatable/equatable.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

enum PaymentStatus {
  unpaid,
  pending,
  completed,
  failed,
}

/// Environmental savings achieved by sharing the pooled ride.
class EnvironmentalImpact extends Equatable {
  const EnvironmentalImpact({
    required this.vehicleKmSaved,
    required this.co2SavedKg,
    this.fuelSavedLitres,
  });

  final double vehicleKmSaved;
  final double co2SavedKg;
  final double? fuelSavedLitres;

  double get effectiveFuelSavedLitres =>
      fuelSavedLitres ?? ((vehicleKmSaved / 15.0 * 100).round() / 100.0);

  String get formattedKm => '${vehicleKmSaved.toStringAsFixed(1)} km saved';
  String get formattedCo2 =>
      '${co2SavedKg.toStringAsFixed(2)} kg CO₂ avoided';
  String get formattedFuelSaved =>
      '${effectiveFuelSavedLitres.toStringAsFixed(2)} L fuel saved';

  Map<String, dynamic> toJson() => {
        'vehicleKmSaved': vehicleKmSaved,
        'co2SavedKg': co2SavedKg,
        'fuelSavedLitres': effectiveFuelSavedLitres,
      };

  factory EnvironmentalImpact.fromJson(Map<String, dynamic> json) =>
      EnvironmentalImpact(
        vehicleKmSaved: (json['vehicleKmSaved'] as num).toDouble(),
        co2SavedKg: (json['co2SavedKg'] as num).toDouble(),
        fuelSavedLitres: (json['fuelSavedLitres'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [vehicleKmSaved, co2SavedKg, fuelSavedLitres];
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
    this.farePaise,
    this.driverPayoutPaise,
    this.paymentStatus = PaymentStatus.completed,
    this.paymentMethod,
    this.paymentTransactionId,
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
  final int? farePaise;
  final int? driverPayoutPaise;
  final PaymentStatus paymentStatus;
  final String? paymentMethod;
  final String? paymentTransactionId;

  int get effectiveFarePaise =>
      farePaise ?? (finalPayableFare * 100).round();

  int get effectiveDriverPayoutPaise =>
      driverPayoutPaise ?? ((finalPayableFare * 0.85) * 100).round();

  double get driverPayoutRupees =>
      (effectiveDriverPayoutPaise / 100.0);

  bool get isPaid => paymentStatus == PaymentStatus.completed;

  double get savings => soloReferenceFare - finalPayableFare;

  double get savingsPercentage =>
      soloReferenceFare > 0 ? (savings / soloReferenceFare) * 100.0 : 0.0;

  bool get isDetourGuaranteed =>
      finalDetourPercentage <= kMaxDetourGuaranteePercentage;

  TripReceipt copyWith({
    String? receiptId,
    String? tripId,
    String? vehicleModel,
    String? licensePlate,
    String? driverName,
    PuneLocation? pickup,
    PuneLocation? dropoff,
    DateTime? completedAt,
    double? soloReferenceFare,
    double? finalPayableFare,
    double? finalDetourPercentage,
    EnvironmentalImpact? environmentalImpact,
    List<CoalitionMemberAudit>? coalitionAudits,
    int? farePaise,
    int? driverPayoutPaise,
    PaymentStatus? paymentStatus,
    String? paymentMethod,
    String? paymentTransactionId,
  }) {
    return TripReceipt(
      receiptId: receiptId ?? this.receiptId,
      tripId: tripId ?? this.tripId,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      licensePlate: licensePlate ?? this.licensePlate,
      driverName: driverName ?? this.driverName,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      completedAt: completedAt ?? this.completedAt,
      soloReferenceFare: soloReferenceFare ?? this.soloReferenceFare,
      finalPayableFare: finalPayableFare ?? this.finalPayableFare,
      finalDetourPercentage:
          finalDetourPercentage ?? this.finalDetourPercentage,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      coalitionAudits: coalitionAudits ?? this.coalitionAudits,
      farePaise: farePaise ?? this.farePaise,
      driverPayoutPaise: driverPayoutPaise ?? this.driverPayoutPaise,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTransactionId:
          paymentTransactionId ?? this.paymentTransactionId,
    );
  }

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
        'farePaise': effectiveFarePaise,
        'driverPayoutPaise': effectiveDriverPayoutPaise,
        'paymentStatus': paymentStatus.name,
        'paymentMethod': paymentMethod,
        'paymentTransactionId': paymentTransactionId,
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
        farePaise: (json['farePaise'] as num?)?.toInt(),
        driverPayoutPaise: (json['driverPayoutPaise'] as num?)?.toInt(),
        paymentStatus: json['paymentStatus'] != null
            ? PaymentStatus.values.byName(json['paymentStatus'] as String)
            : PaymentStatus.completed,
        paymentMethod: json['paymentMethod'] as String?,
        paymentTransactionId: json['paymentTransactionId'] as String?,
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
        farePaise,
        driverPayoutPaise,
        paymentStatus,
        paymentMethod,
        paymentTransactionId,
      ];
}
