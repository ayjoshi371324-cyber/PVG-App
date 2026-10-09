import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pune_location.dart';
import 'package:ridepool_app/services/place_search_service.dart';
import 'package:ridepool_app/widgets/place_search_field.dart';

void main() {
  group('PlaceSearchField Widget', () {
    late PlaceSearchService searchService;

    setUp(() {
      searchService = LocalPlaceSearchService();
    });

    testWidgets('renders search field with current selected location', (tester) async {
      PuneLocation? selected = PuneLandmarks.kothrud;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PlaceSearchField(
              label: 'Pickup',
              selectedLocation: selected,
              isPickup: true,
              searchService: searchService,
              onLocationSelected: (loc) => selected = loc,
            ),
          ),
        ),
      );

      expect(find.text('Kothrud Stand'), findsOneWidget);
      expect(find.byKey(const Key('place_search_input_pickup')), findsOneWidget);
    });

    testWidgets('debounces search by 400ms and displays matching Pune landmarks', (tester) async {
      PuneLocation? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaceSearchField(
                label: 'Destination',
                selectedLocation: selected,
                isPickup: false,
                searchService: searchService,
                onLocationSelected: (loc) => selected = loc,
              ),
            ),
          ),
        ),
      );

      final inputFinder = find.byKey(const Key('place_search_input_dropoff'));
      await tester.tap(inputFinder);
      await tester.pump();

      // Enter search text "hinja" (< 3 chars would not search, 5 chars triggers)
      await tester.enterText(inputFinder, 'hinja');
      await tester.pump();

      // Before 400ms: debounce timer is still pending
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Hinjawadi Phase 1'), findsNothing);

      // Advance past 400ms debounce
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      // Verify matching Pune landmark appears in suggestions
      expect(find.text('Hinjawadi Phase 1'), findsOneWidget);

      // Tap suggestion to select it
      await tester.tap(find.text('Hinjawadi Phase 1'));
      await tester.pumpAndSettle();

      // Verifies selected point resolves to validated coordinates
      expect(selected, isNotNull);
      expect(selected!.name, equals('Hinjawadi Phase 1'));
      expect(selected!.latitude, equals(PuneLandmarks.hinjawadiPhase1.latitude));
      expect(selected!.longitude, equals(PuneLandmarks.hinjawadiPhase1.longitude));
    });

    testWidgets('provides tap-to-confirm map pin selector action', (tester) async {
      bool chooseOnMapTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaceSearchField(
                label: 'Pickup',
                selectedLocation: null,
                isPickup: true,
                searchService: searchService,
                onLocationSelected: (_) {},
                onChooseOnMapTap: () {
                  chooseOnMapTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      final inputFinder = find.byKey(const Key('place_search_input_pickup'));
      await tester.tap(inputFinder);
      await tester.pumpAndSettle();

      // Verify "Choose on map" option is visible
      expect(find.byKey(const Key('choose_on_map_button')), findsOneWidget);
      expect(find.text('Choose location on map'), findsOneWidget);

      await tester.tap(find.byKey(const Key('choose_on_map_button')));
      await tester.pumpAndSettle();

      expect(chooseOnMapTapped, isTrue);
    });

    testWidgets('shows recent locations when focused and empty query', (tester) async {
      searchService.recordRecentSearch(PuneLandmarks.swargate);

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlaceSearchField(
                label: 'Pickup',
                selectedLocation: null,
                isPickup: true,
                searchService: searchService,
                onLocationSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final inputFinder = find.byKey(const Key('place_search_input_pickup'));
      await tester.tap(inputFinder);
      await tester.pumpAndSettle();

      // Verify Recent section renders with Swargate
      expect(find.text('Recent & Presets'), findsOneWidget);
      expect(find.text('Swargate'), findsOneWidget);
    });
  });
}
