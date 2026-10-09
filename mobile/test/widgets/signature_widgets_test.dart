import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/theme.dart';
import 'package:ridepool_app/widgets/bottom_drawer_sheet.dart';
import 'package:ridepool_app/widgets/metric_badge.dart';
import 'package:ridepool_app/widgets/pill_button.dart';
import 'package:ridepool_app/widgets/role_switcher.dart';
import 'package:ridepool_app/widgets/uber_card.dart';
import 'package:ridepool_app/blocs/role/role_state.dart';

void main() {
  group('PillButton Widget', () {
    testWidgets('renders label and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PillButton(
              label: 'Request Pooled Ride',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Request Pooled Ride'), findsOneWidget);
      await tester.tap(find.byType(PillButton));
      await tester.pump();
      expect(tapped, isTrue);

      // Verify border radius is pill (999)
      final container = tester.widget<Material>(
        find.descendant(
          of: find.byType(PillButton),
          matching: find.byType(Material),
        ).first,
      );
      expect(container.borderRadius, equals(UberRadii.pill));
    });

    testWidgets('renders with icon when specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: PillButton(
              label: 'Share Route',
              icon: Icons.share_rounded,
              variant: PillButtonVariant.secondary,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.text('Share Route'), findsOneWidget);
    });
  });

  group('MetricBadge Widget', () {
    testWidgets('renders label and value with pill shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: MetricBadge(
              label: 'Detour',
              value: '+8.4%',
              variant: MetricBadgeVariant.success,
            ),
          ),
        ),
      );

      expect(find.text('Detour: +8.4%'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(MetricBadge),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(UberRadii.pill));
    });
  });

  group('UberCard Widget', () {
    testWidgets('renders child content with 16px corner radius', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: UberCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(UberCard),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, equals(UberRadii.xl));
    });
  });

  group('BottomDrawerSheet Widget', () {
    testWidgets('renders drag handle pill and body content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: const Scaffold(
            body: BottomDrawerSheet(
              title: 'Active Trip',
              child: Text('Trip Details Here'),
            ),
          ),
        ),
      );

      expect(find.text('Active Trip'), findsOneWidget);
      expect(find.text('Trip Details Here'), findsOneWidget);
      // Grabber pill exists
      expect(find.byKey(const Key('drawer_drag_handle')), findsOneWidget);
    });
  });

  group('RoleSwitcher Widget', () {
    testWidgets('renders all three roles and notifies on tap', (tester) async {
      AppRole? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: UberTheme.lightTheme,
          home: Scaffold(
            body: RoleSwitcher(
              currentRole: AppRole.passenger,
              onRoleChanged: (role) => selected = role,
            ),
          ),
        ),
      );

      expect(find.text('Passenger'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('Operations'), findsOneWidget);

      await tester.tap(find.text('Driver'));
      await tester.pump();
      expect(selected, equals(AppRole.driver));
    });
  });
}
