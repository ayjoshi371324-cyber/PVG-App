import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/blocs/ops/ops_cubit.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/views/ops/ops_home_view.dart';
import 'package:ridepool_app/widgets/comparative_benchmark_card.dart';
import 'package:ridepool_app/widgets/detour_guarantee_inspector.dart';

void main() {
  group('OpsHomeView Integration Tests', () {
    late OpsCubit opsCubit;

    setUp(() {
      opsCubit = OpsCubit();
    });

    tearDown(() {
      opsCubit.close();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        theme: UberTheme.lightTheme,
        home: BlocProvider<OpsCubit>.value(
          value: opsCubit,
          child: const OpsHomeView(),
        ),
      );
    }

    testWidgets('renders fleet overview map, queue status, and analytics cards', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Top badges
      expect(find.textContaining('Fleet Active'), findsOneWidget);
      expect(find.text('Dynamic Intake Queue'), findsOneWidget);
      expect(find.textContaining('3 pending requests'), findsOneWidget);

      // Buttons
      expect(find.byKey(const Key('ops_trigger_batch_button')), findsOneWidget);
      expect(find.byKey(const Key('ops_inject_demand_button')), findsOneWidget);

      // Comparative benchmark & detour inspector
      expect(find.byType(ComparativeBenchmarkCard), findsOneWidget);
      expect(find.byType(DetourGuaranteeInspector), findsOneWidget);
      expect(find.text('100.0% Compliant'), findsOneWidget);
    });

    testWidgets('injects synthetic demand and triggers batch optimization', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(opsCubit.state.pendingDemand.length, equals(3));

      // Tap Inject +3
      await tester.tap(find.byKey(const Key('ops_inject_demand_button')));
      await tester.pumpAndSettle();

      expect(opsCubit.state.pendingDemand.length, equals(6));
      expect(find.textContaining('6 pending requests'), findsOneWidget);

      // Tap Trigger Batch Now
      await tester.tap(find.byKey(const Key('ops_trigger_batch_button')));
      await tester.pumpAndSettle();

      expect(opsCubit.state.pendingDemand.isEmpty, isTrue);
      expect(opsCubit.state.totalCompletedBatches, equals(2));
      expect(find.textContaining('0 pending requests'), findsOneWidget);
    });
  });
}
