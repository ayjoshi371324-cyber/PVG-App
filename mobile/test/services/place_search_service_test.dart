import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/services/place_search_service.dart';

void main() {
  group('PlaceSearchService', () {
    late PlaceSearchService searchService;

    setUp(() {
      searchService = LocalPlaceSearchService();
    });

    test('search returns empty when query is less than 3 characters', () async {
      final results1 = await searchService.search('');
      final results2 = await searchService.search('hi');
      expect(results1, isEmpty);
      expect(results2, isEmpty);
    });

    test('search matches Pune landmarks by name case-insensitively', () async {
      final results = await searchService.search('hinja');
      expect(results.isNotEmpty, isTrue);
      expect(
        results.any((loc) => loc.name.contains('Hinjawadi')),
        isTrue,
      );
    });

    test('search matches landmark note keywords', () async {
      // 'Airport' or 'Metro'
      final results = await searchService.search('metro');
      expect(results.isNotEmpty, isTrue);
      expect(
        results.any((loc) => loc.name == PuneLandmarks.shivajiNagar.name),
        isTrue,
      );
    });

    test('validates coordinates strictly within Pune metropolitan corridor', () {
      // Valid coordinates: Kothrud
      expect(
        searchService.isValidCoordinates(
          latitude: PuneLandmarks.kothrud.latitude,
          longitude: PuneLandmarks.kothrud.longitude,
        ),
        isTrue,
      );

      // Invalid coordinates: Delhi / London / NaN
      expect(
        searchService.isValidCoordinates(latitude: 28.6139, longitude: 77.2090),
        isFalse,
      );
      expect(
        searchService.isValidCoordinates(latitude: 0.0, longitude: 0.0),
        isFalse,
      );
      expect(
        searchService.isValidCoordinates(latitude: double.nan, longitude: 73.85),
        isFalse,
      );
    });

    test('resolveLocation throws exception when given out-of-bounds coordinates', () {
      expect(
        () => searchService.resolveLocation(
          name: 'Invalid Point',
          latitude: 45.0,
          longitude: 10.0,
        ),
        throwsA(isA<InvalidCoordinatesException>()),
      );
    });

    test('resolveLocation returns validated PuneLocation for valid coordinates', () {
      final loc = searchService.resolveLocation(
        name: 'Custom Pune Pin',
        latitude: 18.5204,
        longitude: 73.8567,
        landmarkNote: 'Manually placed pin',
      );

      expect(loc.name, equals('Custom Pune Pin'));
      expect(loc.latitude, equals(18.5204));
      expect(loc.longitude, equals(73.8567));
    });

    test('records and retrieves recent searches with deduplication and cap', () {
      expect(searchService.getRecentSearches(), isEmpty);

      searchService.recordRecentSearch(PuneLandmarks.kothrud);
      searchService.recordRecentSearch(PuneLandmarks.swargate);

      final recents = searchService.getRecentSearches();
      expect(recents.length, equals(2));
      expect(recents.first, equals(PuneLandmarks.swargate)); // Most recent first

      // Deduplication: re-recording Kothrud moves it to front
      searchService.recordRecentSearch(PuneLandmarks.kothrud);
      final updatedRecents = searchService.getRecentSearches();
      expect(updatedRecents.length, equals(2));
      expect(updatedRecents.first, equals(PuneLandmarks.kothrud));
    });
  });
}
