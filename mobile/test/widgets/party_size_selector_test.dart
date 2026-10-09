import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/party_size_selector.dart';

void main() {
  group('PartySizeSelector Widget', () {
    testWidgets('renders current party size and handles increment/decrement', (tester) async {
      var count = 1;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PartySizeSelector(
                  partySize: count,
                  onIncrement: () => setState(() => count++),
                  onDecrement: () => setState(() => count--),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('1 Seat'), findsOneWidget);

      // Tap increment
      await tester.tap(find.byKey(const Key('party_size_increment_button')));
      await tester.pump();
      expect(count, equals(2));
      expect(find.text('2 Seats'), findsOneWidget);

      // Tap decrement
      await tester.tap(find.byKey(const Key('party_size_decrement_button')));
      await tester.pump();
      expect(count, equals(1));
      expect(find.text('1 Seat'), findsOneWidget);
    });

    testWidgets('disables decrement button at min capacity (1)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: PartySizeSelector(
              partySize: 1,
              onIncrement: null,
              onDecrement: null,
            ),
          ),
        ),
      );

      final decrementButton = tester.widget<IconButton>(
        find.byKey(const Key('party_size_decrement_button')),
      );
      expect(decrementButton.onPressed, isNull);
    });

    testWidgets('disables increment button at max capacity (3)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: PartySizeSelector(
              partySize: 3,
              onIncrement: null,
              onDecrement: null,
            ),
          ),
        ),
      );

      final incrementButton = tester.widget<IconButton>(
        find.byKey(const Key('party_size_increment_button')),
      );
      expect(incrementButton.onPressed, isNull);
    });
  });
}
