import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/otp_keypad_widget.dart';
import 'package:ridepool_app/widgets/pickup_otp_card.dart';

void main() {
  group('OtpKeypadWidget Tests', () {
    testWidgets('renders 4 digit slots and numeric buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: OtpKeypadWidget(
              enteredOtp: '48',
              isVerified: false,
              isLocked: false,
              onDigitPressed: (_) {},
              onDeletePressed: () {},
              onBypassPressed: () {},
            ),
          ),
        ),
      );

      // Check entered digits in slots
      expect(find.text('4'), findsAtLeastNWidgets(1));
      expect(find.text('8'), findsAtLeastNWidgets(1));

      // Keypad numbers 0-9
      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsAtLeastNWidgets(1));
      }

      // Check bypass button
      expect(find.textContaining('Bypass OTP'), findsOneWidget);
    });

    testWidgets('triggers callbacks on digit tap and delete tap', (tester) async {
      String pressed = '';
      bool deleted = false;
      bool bypassed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: OtpKeypadWidget(
              enteredOtp: '',
              isVerified: false,
              isLocked: false,
              onDigitPressed: (d) => pressed = d,
              onDeletePressed: () => deleted = true,
              onBypassPressed: () => bypassed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('7'));
      expect(pressed, equals('7'));

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      expect(deleted, isTrue);

      await tester.tap(find.textContaining('Bypass OTP'));
      expect(bypassed, isTrue);
    });

    testWidgets('renders verified badge when isVerified is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: OtpKeypadWidget(
              enteredOtp: '4821',
              isVerified: true,
              isLocked: false,
              onDigitPressed: (_) {},
              onDeletePressed: () {},
              onBypassPressed: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('OTP Verified'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders lockout banner and manual override when isLocked is true', (tester) async {
      bool overridden = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: OtpKeypadWidget(
              enteredOtp: '0000',
              isVerified: false,
              isLocked: true,
              errorMessage: 'Stop locked due to 5 consecutive failed attempts.',
              onDigitPressed: (_) {},
              onDeletePressed: () {},
              onBypassPressed: () {},
              onManualOverride: () => overridden = true,
            ),
          ),
        ),
      );

      expect(find.textContaining('Stop locked'), findsOneWidget);
      expect(find.text('Manual Override'), findsOneWidget);

      await tester.tap(find.text('Manual Override'));
      expect(overridden, isTrue);
    });
  });

  group('PickupOtpCard Tests', () {
    testWidgets('renders 4-digit code and security instructions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: PickupOtpCard(
              otpCode: '4821',
              passengerName: 'Aakash',
            ),
          ),
        ),
      );

      expect(find.text('Pickup OTP'), findsOneWidget);
      expect(find.text('4 8 2 1'), findsOneWidget);
      expect(
        find.textContaining('Share this 4-digit code with your driver only after they arrive'),
        findsOneWidget,
      );
    });
  });
}
