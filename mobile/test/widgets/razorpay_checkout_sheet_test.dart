import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/route_estimator.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/data/models/trip_receipt.dart';
import 'package:ridepool_app/widgets/razorpay_checkout_sheet.dart';

void main() {
  group('RazorpayCheckoutSheet Tests', () {
    final testReceipt = TripReceipt(
      receiptId: 'rcpt-test-pay',
      tripId: 'trip-test-pay',
      vehicleModel: 'Tata Tigor EV',
      licensePlate: 'MH-12-RN-4821',
      driverName: 'Suresh K.',
      pickup: PuneLandmarks.kothrud,
      dropoff: PuneLandmarks.hinjawadiPhase1,
      completedAt: DateTime(2026, 10, 10, 10, 30),
      soloReferenceFare: 280.0,
      finalPayableFare: 171.0,
      farePaise: 17100,
      driverPayoutPaise: 14535,
      paymentStatus: PaymentStatus.unpaid,
      finalDetourPercentage: 11.5,
      environmentalImpact: const EnvironmentalImpact(
        vehicleKmSaved: 8.4,
        co2SavedKg: 1.0,
        fuelSavedLitres: 0.56,
      ),
      coalitionAudits: const [
        CoalitionMemberAudit(
          passengerName: 'You',
          isUser: true,
          soloFare: 280.0,
          marginalContribution: 110.0,
          shapleyFairShare: 171.0,
        ),
      ],
    );

    testWidgets('renders Razorpay test mode header, amount in paise, and payment methods', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: RazorpayCheckoutSheet(
              receipt: testReceipt,
              onPaymentComplete: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Razorpay Test Mode'), findsOneWidget);
      expect(find.text('₹171.00'), findsOneWidget);
      expect(find.textContaining('17100 paise'), findsOneWidget);

      // Method tabs
      expect(find.byKey(const Key('tab_upi')), findsOneWidget);
      expect(find.byKey(const Key('tab_card')), findsOneWidget);
      expect(find.byKey(const Key('tab_netbanking')), findsOneWidget);
      expect(find.byKey(const Key('tab_payment_link')), findsOneWidget);
    });

    testWidgets('switches payment methods to Card and enters test payment', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: RazorpayCheckoutSheet(
              receipt: testReceipt,
              onPaymentComplete: (_) {},
            ),
          ),
        ),
      );

      // Tap Card tab
      await tester.tap(find.byKey(const Key('tab_card')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Test Card (Visa / RuPay)'), findsOneWidget);
    });

    testWidgets('processes payment successfully and returns updated receipt with transaction ID', (tester) async {
      TripReceipt? completedReceipt;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: RazorpayCheckoutSheet(
              receipt: testReceipt,
              onPaymentComplete: (r) => completedReceipt = r,
            ),
          ),
        ),
      );

      // Tap Pay button
      final payButtonFinder = find.byKey(const Key('razorpay_pay_button'));
      expect(payButtonFinder, findsOneWidget);
      await tester.tap(payButtonFinder);
      await tester.pumpAndSettle();

      expect(completedReceipt, isNotNull);
      expect(completedReceipt!.paymentStatus, equals(PaymentStatus.completed));
      expect(completedReceipt!.paymentTransactionId, startsWith('pay_test_'));
      expect(completedReceipt!.paymentMethod, isNotNull);
    });

    testWidgets('simulated web/desktop fallback completes payment with payment link transaction', (tester) async {
      TripReceipt? completedReceipt;

      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: RazorpayCheckoutSheet(
              receipt: testReceipt,
              isWebOrDesktop: true,
              onPaymentComplete: (r) => completedReceipt = r,
            ),
          ),
        ),
      );

      // Tap Payment Link tab
      await tester.tap(find.byKey(const Key('tab_payment_link')));
      await tester.pumpAndSettle();

      final linkButtonFinder = find.byKey(const Key('simulate_link_checkout_button'));
      expect(linkButtonFinder, findsOneWidget);
      await tester.tap(linkButtonFinder);
      await tester.pumpAndSettle();

      expect(completedReceipt, isNotNull);
      expect(completedReceipt!.paymentStatus, equals(PaymentStatus.completed));
      expect(completedReceipt!.paymentMethod, contains('Payment Link'));
    });
  });
}
