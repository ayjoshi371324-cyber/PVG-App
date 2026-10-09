import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/batch_waiting_card.dart';

void main() {
  group('BatchWaitingCard Widget', () {
    testWidgets('renders countdown timer, informational batch text and cancel button', (tester) async {
      var cancelled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: BatchWaitingCard(
              secondsRemaining: 12,
              totalSeconds: 15,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      // Countdown display
      expect(find.text('12s'), findsOneWidget);

      // Informational batch text
      expect(find.text('Dynamic Batch Intake Active'), findsOneWidget);
      expect(
        find.textContaining('Grouping compatible commuters within a 15-second window'),
        findsOneWidget,
      );

      // Cancel button
      expect(find.byKey(const Key('cancel_batch_request_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancel_batch_request_button')));
      await tester.pump();

      expect(cancelled, isTrue);
    });
  });
}
