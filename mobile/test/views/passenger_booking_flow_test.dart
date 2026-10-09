import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/blocs/passenger/passenger_state.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/pooled_ride_offer.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/widgets/batch_waiting_card.dart';
import 'package:ridepool_app/widgets/detour_guarantee_badge.dart';
import 'package:ridepool_app/widgets/party_size_selector.dart';
import 'package:ridepool_app/widgets/pooled_ride_offer_card.dart';
import 'package:ridepool_app/widgets/shapley_fare_breakdown_card.dart';

void main() {
  group('Passenger Booking Flow Integration', () {
    late PassengerCubit passengerCubit;

    setUp(() {
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

    testWidgets(
        'shows party size selector and enters batch waiting on find shared pool tap',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify PartySizeSelector is displayed
      expect(find.byType(PartySizeSelector), findsOneWidget);
      expect(find.text('1 Seat'), findsOneWidget);

      // Tap + to select 2 seats
      await tester.tap(find.byKey(const Key('party_size_increment_button')));
      await tester.pumpAndSettle();
      expect(passengerCubit.state.partySize, equals(2));

      // Tap "Find Shared Pool" button
      expect(find.byKey(const Key('find_shared_pool_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('find_shared_pool_button')));
      await tester.pumpAndSettle();

      // Verify transition to BatchWaitingCard
      expect(find.byType(BatchWaitingCard), findsOneWidget);
      expect(find.text('Dynamic Batch Intake Active'), findsOneWidget);
      expect(
          find.byKey(const Key('cancel_batch_request_button')), findsOneWidget);

      // Tap Cancel Request
      await tester.tap(find.byKey(const Key('cancel_batch_request_button')));
      await tester.pumpAndSettle();

      // Verify reverted to planning sheet
      expect(find.byType(BatchWaitingCard), findsNothing);
      expect(find.byType(PartySizeSelector), findsOneWidget);
    });

    testWidgets(
        'renders PooledRideOfferCard when offer is received and allows accepting',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final offer = PooledRideOffer(
        offerId: 'offer-int-001',
        vehicleModel: 'Tata Tigor EV',
        licensePlate: 'MH-12-RN-4821',
        driverName: 'Suresh K.',
        driverRating: 4.9,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 4,
        dropoffEtaMinutes: 26,
        coPassengersCount: 2,
        coPassengerLabels: const ['Rohan (Swargate)', 'Priya (Kothrud)'],
        detourPercentage: 8.4,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 196.0,
          coalitionSize: 3,
        ),
        offerExpirySeconds: 20,
      );

      // Deliver offer
      passengerCubit.receiveOffer(offer);
      await tester.pumpAndSettle();

      // Verify PooledRideOfferCard is displayed
      expect(find.byType(PooledRideOfferCard), findsOneWidget);
      expect(find.byType(DetourGuaranteeBadge), findsOneWidget);
      expect(find.byType(ShapleyFareBreakdownCard), findsOneWidget);
      expect(find.text('Tata Tigor EV'), findsOneWidget);
      expect(find.text('MH-12-RN-4821'), findsOneWidget);
      expect(find.text('≤ 15% Guaranteed'), findsOneWidget);

      // Accept Offer
      final acceptFinder = find.byKey(const Key('accept_pool_offer_button'));
      expect(acceptFinder, findsOneWidget);
      await tester.tap(acceptFinder);
      await tester.pumpAndSettle();

      // Verify transitioned to trip active state
      expect(passengerCubit.state.status,
          equals(PassengerBookingStatus.tripActive));
      expect(find.text('Ride Confirmed & Dispatched'), findsOneWidget);
      expect(find.textContaining('Driver Suresh K. En Route'), findsOneWidget);
    });

    testWidgets(
        'declining offer reverts back to planning sheet',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final offer = PooledRideOffer(
        offerId: 'offer-int-002',
        vehicleModel: 'Maruti WagonR Green',
        licensePlate: 'MH-14-GH-9912',
        driverName: 'Amit P.',
        driverRating: 4.8,
        pickup: PuneLandmarks.kothrud,
        dropoff: PuneLandmarks.hinjawadiPhase1,
        pickupEtaMinutes: 5,
        dropoffEtaMinutes: 28,
        coPassengersCount: 1,
        detourPercentage: 7.2,
        fareBreakdown: ShapleyFareBreakdown(
          soloFare: 280.0,
          sharedFare: 196.0,
          coalitionSize: 2,
        ),
        offerExpirySeconds: 20,
      );

      passengerCubit.receiveOffer(offer);
      await tester.pumpAndSettle();

      expect(find.byType(PooledRideOfferCard), findsOneWidget);

      // Tap Decline button
      final declineFinder = find.byKey(const Key('decline_pool_offer_button'));
      expect(declineFinder, findsOneWidget);
      await tester.tap(declineFinder);
      await tester.pumpAndSettle();

      // Verify reverted to planning sheet
      expect(passengerCubit.state.status,
          equals(PassengerBookingStatus.planning));
      expect(find.byType(PooledRideOfferCard), findsNothing);
      expect(find.byType(PartySizeSelector), findsOneWidget);
    });
  });
}
