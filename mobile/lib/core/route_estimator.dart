import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

class PuneLandmarks {
  PuneLandmarks._();

  static const PuneLocation kothrud = PuneLocation(
    name: 'Kothrud Stand',
    latitude: 18.5074,
    longitude: 73.8077,
    landmarkNote: 'West Pune Transit Depot',
  );

  static const PuneLocation hinjawadiPhase1 = PuneLocation(
    name: 'Hinjawadi Phase 1',
    latitude: 18.5913,
    longitude: 73.7389,
    landmarkNote: 'Infotech Hub & Phase 1 Circle',
  );

  static const PuneLocation shivajiNagar = PuneLocation(
    name: 'Shivaji Nagar',
    latitude: 18.5314,
    longitude: 73.8446,
    landmarkNote: 'Metro & Railway Junction',
  );

  static const PuneLocation swargate = PuneLocation(
    name: 'Swargate',
    latitude: 18.5018,
    longitude: 73.8636,
    landmarkNote: 'South Pune Bus Terminus',
  );

  static const PuneLocation koregaonPark = PuneLocation(
    name: 'Koregaon Park',
    latitude: 18.5362,
    longitude: 73.8940,
    landmarkNote: 'North Main Road Corridor',
  );

  static const PuneLocation vimanNagar = PuneLocation(
    name: 'Viman Nagar',
    latitude: 18.5679,
    longitude: 73.9143,
    landmarkNote: 'Airport Road Sub-Hub',
  );

  static const PuneLocation hadapsar = PuneLocation(
    name: 'Hadapsar Magarpatta',
    latitude: 18.5089,
    longitude: 73.9259,
    landmarkNote: 'Cybercity IT District',
  );

  static const List<PuneLocation> all = [
    kothrud,
    hinjawadiPhase1,
    shivajiNagar,
    swargate,
    koregaonPark,
    vimanNagar,
    hadapsar,
  ];
}

class SoloRouteEstimate extends Equatable {
  const SoloRouteEstimate({
    required this.pickup,
    required this.dropoff,
    required this.distanceKm,
    required this.durationMinutes,
    required this.referenceFare,
    required this.polylinePoints,
  });

  final PuneLocation pickup;
  final PuneLocation dropoff;
  final double distanceKm;
  final int durationMinutes;
  final double referenceFare;
  final List<LatLng> polylinePoints;

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationMinutes min';
  String get formattedFare => '₹${referenceFare.round()}';

  @override
  List<Object?> get props => [
        pickup,
        dropoff,
        distanceKm,
        durationMinutes,
        referenceFare,
        polylinePoints,
      ];
}

class RouteEstimatorService {
  const RouteEstimatorService();

  // Constants matching Test_cases.md
  static const double baseFare = 20.0;
  static const double ratePerKm = 10.0;
  static const double roadCurvatureFactor = 1.25; // Urban road network factor
  static const double averageUrbanSpeedKmh = 24.0; // Pune city traffic avg

  double calculateDistanceKm(PuneLocation start, PuneLocation end) {
    const double earthRadiusKm = 6371.0;

    final dLat = _toRadians(end.latitude - start.latitude);
    final dLon = _toRadians(end.longitude - start.longitude);

    final lat1 = _toRadians(start.latitude);
    final lat2 = _toRadians(end.latitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final straightLineKm = earthRadiusKm * c;
    final roadDistanceKm = straightLineKm * roadCurvatureFactor;

    // Return rounded to one decimal place, at least 0.5 km
    return max(0.5, double.parse(roadDistanceKm.toStringAsFixed(1)));
  }

  double calculateSoloFare(double distanceKm) {
    if (distanceKm <= 0) return baseFare;
    final calculated = baseFare + (distanceKm * ratePerKm);
    return double.parse(calculated.toStringAsFixed(1));
  }

  int calculateDurationMinutes(double distanceKm) {
    if (distanceKm <= 0) return 0;
    final travelMinutes = (distanceKm / averageUrbanSpeedKmh) * 60;
    const trafficStopBufferMinutes = 3;
    return max(5, (travelMinutes + trafficStopBufferMinutes).round());
  }

  SoloRouteEstimate estimateRoute({
    required PuneLocation pickup,
    required PuneLocation dropoff,
  }) {
    final distanceKm = calculateDistanceKm(pickup, dropoff);
    final durationMins = calculateDurationMinutes(distanceKm);
    final fare = calculateSoloFare(distanceKm);
    final polyline = _generateRoutePolyline(pickup, dropoff);

    return SoloRouteEstimate(
      pickup: pickup,
      dropoff: dropoff,
      distanceKm: distanceKm,
      durationMinutes: durationMins,
      referenceFare: fare,
      polylinePoints: polyline,
    );
  }

  List<LatLng> _generateRoutePolyline(PuneLocation start, PuneLocation end) {
    final startLatLng = start.toLatLng();
    final endLatLng = end.toLatLng();

    final points = <LatLng>[startLatLng];

    // Generate 4 natural interpolation waypoints with slight road deviation
    const segments = 5;
    final latDiff = (end.latitude - start.latitude) / segments;
    final lonDiff = (end.longitude - start.longitude) / segments;

    for (int i = 1; i < segments; i++) {
      // Small lateral deviation perpendicular to vector to emulate Pune road bends
      final progress = i / segments;
      final bendFactor = sin(progress * pi) * 0.005;

      final interLat = start.latitude + (latDiff * i) + (bendFactor * 0.7);
      final interLon = start.longitude + (lonDiff * i) - (bendFactor * 0.7);

      points.add(LatLng(interLat, interLon));
    }

    points.add(endLatLng);
    return points;
  }

  double _toRadians(double degree) => degree * (pi / 180.0);
}
