import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/data/models/pune_location.dart';

/// Thrown when location coordinates fall outside the Pune metropolitan operations corridor.
class InvalidCoordinatesException implements Exception {
  const InvalidCoordinatesException({
    required this.latitude,
    required this.longitude,
    required this.message,
  });

  final double latitude;
  final double longitude;
  final String message;

  @override
  String toString() =>
      'InvalidCoordinatesException: $message ($latitude, $longitude)';
}

/// Abstract contract for typed place search & coordinate validation.
abstract class PlaceSearchService {
  /// Searches for matching locations given a query string.
  /// Requires at least 3 characters; otherwise returns empty list.
  Future<List<PuneLocation>> search(String query);

  /// Validates whether the given coordinates fall within the Pune operational bounds.
  bool isValidCoordinates({
    required double latitude,
    required double longitude,
  });

  /// Resolves validated coordinates to a strongly-typed [PuneLocation].
  /// Throws [InvalidCoordinatesException] if coordinates are outside bounds.
  PuneLocation resolveLocation({
    required String name,
    required double latitude,
    required double longitude,
    String? landmarkNote,
  });

  /// Retrieves recent search history.
  List<PuneLocation> getRecentSearches();

  /// Records a selected location into recent search history.
  void recordRecentSearch(PuneLocation location);

  /// Clears recent searches.
  void clearRecentSearches();
}

/// Stage A offline / in-memory implementation of [PlaceSearchService].
class LocalPlaceSearchService implements PlaceSearchService {
  LocalPlaceSearchService({
    List<PuneLocation>? seedLocations,
    this.maxRecentItems = 5,
  })  : _places = List<PuneLocation>.unmodifiable(
          seedLocations ?? _defaultPuneLocations,
        );

  final List<PuneLocation> _places;
  final int maxRecentItems;
  final List<PuneLocation> _recentSearches = [];

  // Pune metropolitan operational bounding box:
  // Lat: 18.2 to 18.9 N, Lng: 73.5 to 74.2 E
  static const double minLat = 18.2;
  static const double maxLat = 18.9;
  static const double minLng = 73.5;
  static const double maxLng = 74.2;

  static final List<PuneLocation> _defaultPuneLocations = [
    ...PuneLandmarks.all,
    const PuneLocation(
      name: 'Pune Airport (PNQ)',
      latitude: 18.5822,
      longitude: 73.9197,
      landmarkNote: 'Lohegaon Terminal',
    ),
    const PuneLocation(
      name: 'Pune Railway Station',
      latitude: 18.5284,
      longitude: 73.8744,
      landmarkNote: 'Central Pune Rail Terminal',
    ),
    const PuneLocation(
      name: 'Aundh IT Park',
      latitude: 18.5602,
      longitude: 73.8070,
      landmarkNote: 'West Pune Commercial Corridor',
    ),
    const PuneLocation(
      name: 'Baner High Street',
      latitude: 18.5590,
      longitude: 73.7788,
      landmarkNote: 'Baner Road Dining & Transit',
    ),
    const PuneLocation(
      name: 'Bavdhan Flyover',
      latitude: 18.5126,
      longitude: 73.7712,
      landmarkNote: 'NDA Road Bypass',
    ),
    const PuneLocation(
      name: 'Wakad Bridge',
      latitude: 18.5987,
      longitude: 73.7631,
      landmarkNote: 'Mumbai-Pune Bypass Junction',
    ),
    const PuneLocation(
      name: 'Magarpatta Cybercity',
      latitude: 18.5144,
      longitude: 73.9298,
      landmarkNote: 'Hadapsar Tech Hub',
    ),
  ];

  @override
  Future<List<PuneLocation>> search(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < 3) {
      return const [];
    }

    final matches = _places.where((loc) {
      final nameMatch = loc.name.toLowerCase().contains(trimmed);
      final noteMatch =
          loc.landmarkNote?.toLowerCase().contains(trimmed) ?? false;
      return nameMatch || noteMatch;
    }).toList();

    return matches;
  }

  @override
  bool isValidCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude.isInfinite || longitude.isInfinite) return false;

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  @override
  PuneLocation resolveLocation({
    required String name,
    required double latitude,
    required double longitude,
    String? landmarkNote,
  }) {
    if (!isValidCoordinates(latitude: latitude, longitude: longitude)) {
      throw InvalidCoordinatesException(
        latitude: latitude,
        longitude: longitude,
        message: 'Coordinates fall outside Pune metropolitan operations area.',
      );
    }

    return PuneLocation(
      name: name,
      latitude: latitude,
      longitude: longitude,
      landmarkNote: landmarkNote,
    );
  }

  @override
  List<PuneLocation> getRecentSearches() {
    return List.unmodifiable(_recentSearches);
  }

  @override
  void recordRecentSearch(PuneLocation location) {
    _recentSearches.removeWhere((item) => item.name == location.name);
    _recentSearches.insert(0, location);
    if (_recentSearches.length > maxRecentItems) {
      _recentSearches.removeLast();
    }
  }

  @override
  void clearRecentSearches() {
    _recentSearches.clear();
  }
}
