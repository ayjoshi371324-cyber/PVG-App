import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/core/engine/batch_matching_engine.dart';
import 'package:ridepool_app/core/engine/fare_allocator.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/data/models/vehicle_tier.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/widgets/batch_outcome_card.dart';
import 'package:ridepool_app/widgets/batch_waiting_card.dart';
import 'package:ridepool_app/widgets/pooled_ride_offer_card.dart';
import 'package:ridepool_app/widgets/vehicle_tier_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ticket 02 - Vehicle Tiers, Location Search & Batch Intake Integration', () {
    late PassengerCubit passengerCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      passengerCubit = PassengerCubit();
    });

    tearDown(() {
      passengerCubit.close();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: UberTheme.lightTheme,
        home: BlocProvider<PassengerCubit>.value(
          value: passengerCubit,
          child: const PassengerHomeView(),
        ),
      );
    }

    testWidgets('vehicle tier selector displays all tiers and allows selecting Car',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify VehicleTierSelector exists
      expect(find.byType(VehicleTierSelector), findsOneWidget);
      expect(find.text('Auto'), findsWidgets);
      expect(find.text('Car'), findsWidgets);
      expect(find.text('Car XL'), findsWidgets);

      // Initially Auto is selected (multiplier 0.8x)
      expect(passengerCubit.state.selectedTier, equals(VehicleTier.auto));
      final initialFare = passengerCubit.state.estimate?.referenceFare;
      expect(initialFare, isNotNull);

      // Select Car tier
      final carTierOption = find.byKey(const Key('vehicle_tier_car'));
      expect(carTierOption, findsOneWidget);
      await tester.tap(carTierOption);
      await tester.pumpAndSettle();

      expect(passengerCubit.state.selectedTier, equals(VehicleTier.car));
      final carFare = passengerCubit.state.estimate?.referenceFare;
      expect(carFare, isNotNull);
      // Car (1.0x) fare should be strictly greater than Auto (0.8x) fare
      expect(carFare!, greaterThan(initialFare!));
    });

    testWidgets(
        'party size > 3 disables Auto tier with capacity helper text',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Increment party size to 4
      final incrementBtn =
          find.byKey(const Key('party_size_increment_button'));
      await tester.tap(incrementBtn); // 2
      await tester.pumpAndSettle();
      await tester.tap(incrementBtn); // 3
      await tester.pumpAndSettle();
      await tester.tap(incrementBtn); // 4
      await tester.pumpAndSettle();

      expect(passengerCubit.state.partySize, equals(4));
      // State automatically upgrades tier to Car when party size exceeds Auto capacity
      expect(passengerCubit.state.selectedTier, equals(VehicleTier.car));

      // Auto is now disabled and shows capacity error text
      expect(find.text('Max 3 seats (party size: 4)'), findsOneWidget);

      // Tapping disabled Auto does NOT select it
      final autoOption = find.byKey(const Key('vehicle_tier_auto'));
      await tester.tap(autoOption);
      await tester.pumpAndSettle();

      expect(passengerCubit.state.selectedTier, equals(VehicleTier.car));
    });

    testWidgets('PlaceSearchField autocompletes Pune landmarks with validated coordinates',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Dropoff PlaceSearchField input
      final dropoffInput = find.byKey(const Key('place_search_input_dropoff'));
      expect(dropoffInput, findsOneWidget);

      // Focus and type "kothrud"
      await tester.tap(dropoffInput);
      await tester.pumpAndSettle();
      await tester.enterText(dropoffInput, 'kothrud');

      // Advance by debounce window (400ms + margin)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Autocomplete list should display Kothrud Stand in a ListTile
      final kothrudSuggestion =
          find.widgetWithText(ListTile, 'Kothrud Stand');
      expect(kothrudSuggestion, findsOneWidget);

      // Tap suggestion
      await tester.tap(kothrudSuggestion);
      await tester.pumpAndSettle();

      // State is updated with exact PuneLandmarks.kothrud coordinates
      expect(passengerCubit.state.dropoff?.latitude,
          equals(PuneLandmarks.kothrud.latitude));
      expect(passengerCubit.state.dropoff?.longitude,
          equals(PuneLandmarks.kothrud.longitude));
    });

    testWidgets('map pin confirmation mode allows setting pending location and confirming',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Focus pickup input to open dropdown
      final pickupInput = find.byKey(const Key('place_search_input_pickup'));
      expect(pickupInput, findsOneWidget);
      await tester.tap(pickupInput);
      await tester.pumpAndSettle();

      // Tap "Choose location on map"
      final chooseOnMapBtn = find.byKey(const Key('choose_on_map_button'));
      expect(chooseOnMapBtn, findsOneWidget);
      await tester.tap(chooseOnMapBtn);
      await tester.pumpAndSettle();

      expect(passengerCubit.state.isPinConfirmationMode, isTrue);
      expect(find.text('Tap Map to Position Pickup'), findsOneWidget);

      // Set pending pin location via cubit (simulating map tap)
      passengerCubit.setPendingPinLocation(PuneLandmarks.vimanNagar);
      await tester.pumpAndSettle();

      expect(find.text('Viman Nagar'), findsWidgets);

      // Confirm pin
      final confirmBtn = find.byKey(const Key('confirm_map_pin_button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(passengerCubit.state.isPinConfirmationMode, isFalse);
      expect(passengerCubit.state.pickup?.name, equals('Viman Nagar'));
    });

    testWidgets('batch waiting resolves to NoValidMatchOutcome and renders BatchOutcomeCard',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Start batch waiting
      await tester.tap(find.byKey(const Key('find_shared_pool_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BatchWaitingCard), findsOneWidget);

      // Simulate engine producing NoValidMatchOutcome
      passengerCubit.setMatchingOutcome(
        const NoValidMatchOutcome(
          reason: NoMatchReason.detourExceeded,
          explanation:
              'No nearby active vehicle satisfied detour ceiling (≤ 15.0%). Observed 19.4% detour.',
          observedDetour: 19.4,
        ),
      );
      await tester.pumpAndSettle();

      // BatchOutcomeCard rendered with "No Valid Shared Match"
      expect(find.byType(BatchOutcomeCard), findsOneWidget);
      expect(find.text('No Valid Shared Match'), findsOneWidget);
      expect(find.textContaining('>15% Detour Guarantee'), findsOneWidget);
      expect(find.text('Observed Detour: 19.4%'), findsOneWidget);
      expect(find.byKey(const Key('try_again_batch_button')), findsOneWidget);
      expect(find.byKey(const Key('book_solo_direct_button')), findsOneWidget);

      // Try next batch resets to batch waiting
      await tester.tap(find.byKey(const Key('try_again_batch_button')));
      await tester.pumpAndSettle();
      expect(find.byType(BatchWaitingCard), findsOneWidget);

      // Cancel request to cleanly stop the batch countdown timer
      await tester.tap(find.byKey(const Key('cancel_batch_request_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('batch waiting resolves to SoloDirectRideOutcome and renders BatchOutcomeCard',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final vehicle = BatchVehicle(
        id: 'veh-car-01',
        model: 'Maruti Dzire',
        licensePlate: 'MH-12-CD-5678',
        driverName: 'Rahul D.',
        driverRating: 4.8,
        tier: VehicleTier.car,
        currentLocation: PuneLandmarks.kothrud,
      );

      final req = BatchRideRequest(
        id: 'req-user-01',
        passengerName: 'You',
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 1,
        tier: VehicleTier.car,
      );

      // Set outcome to SoloDirectRideOutcome
      passengerCubit.setMatchingOutcome(
        SoloDirectRideOutcome(
          vehicle: vehicle,
          request: req,
          distanceKm: 18.0,
          soloFare: 200.0,
          explanation: 'No compatible co-passengers found in 45s window',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BatchOutcomeCard), findsOneWidget);
      expect(find.text('Solo Direct Ride'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.byKey(const Key('confirm_solo_ride_button')), findsOneWidget);
    });

    testWidgets('batch waiting resolves to MatchFoundOutcome and renders PooledRideOfferCard',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final vehicle = BatchVehicle(
        id: 'veh-tigor-01',
        model: 'Tata Tigor EV',
        licensePlate: 'MH-12-QE-7721',
        driverName: 'Amit S.',
        driverRating: 4.85,
        tier: VehicleTier.car,
        currentLocation: PuneLandmarks.kothrud,
      );

      final req1 = BatchRideRequest(
        id: 'req-pune-user',
        passengerName: 'You',
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        partySize: 1,
        tier: VehicleTier.car,
      );

      final offer = PooledRideOffer(
        offerId: 'offer-matched-01',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-QE-7721',
        driverName: 'Amit S.',
        driverRating: 4.85,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 5,
        dropoffEtaMinutes: 28,
        coPassengersCount: 1,
        coPassengerLabels: const ['Vikram (Aundh)'],
        detourPercentage: 7.2,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 168.0,
          sharedFare: 126.0,
          coalitionSize: 2,
        ),
        offerExpirySeconds: 30,
      );

      passengerCubit.setMatchingOutcome(
        MatchFoundOutcome(
          vehicle: vehicle,
          matchedRequests: [req1],
          totalSharedKm: 19.5,
          detourPercentage: 7.2,
          fareAllocation: const FareAllocationResult(
            isFeasible: true,
            totalTripCost: 126.0,
            soloFares: {'req-pune-user': 168.0},
            allocatedFares: {'req-pune-user': 126.0},
            rawShares: {'req-pune-user': 126.0},
            perPersonFares: {'req-pune-user': 126.0},
            savings: {'req-pune-user': 42.0},
            detourPercentages: {'req-pune-user': 7.2},
            coalitionTable: {},
          ),
          offer: offer,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PooledRideOfferCard), findsOneWidget);
      expect(find.text('Tata Tigor EV'), findsOneWidget);
      expect(find.text('+7.2% Detour'), findsOneWidget);
      expect(find.text('₹126'), findsWidgets);

      // Decline offer to cleanly cancel expiry timer
      await tester.tap(find.byKey(const Key('decline_pool_offer_button')));
      await tester.pumpAndSettle();
    });
  });
}
