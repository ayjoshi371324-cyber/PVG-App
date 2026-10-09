import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/passenger/passenger_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';
import 'package:ridepool_app/widgets/batch_waiting_card.dart';
import 'package:ridepool_app/widgets/party_size_selector.dart';

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

    testWidgets('shows party size selector and enters batch waiting on find shared pool tap', (tester) async {
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
      expect(find.byKey(const Key('cancel_batch_request_button')), findsOneWidget);

      // Tap Cancel Request
      await tester.tap(find.byKey(const Key('cancel_batch_request_button')));
      await tester.pumpAndSettle();

      // Verify reverted to planning sheet
      expect(find.byType(BatchWaitingCard), findsNothing);
      expect(find.byType(PartySizeSelector), findsOneWidget);
    });
  });
}
