import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/main.dart';
import 'package:ridepool_app/views/passenger/passenger_home_view.dart';

void main() {
  testWidgets('RidePoolApp smoke test loads shell with Passenger mode', (tester) async {
    await tester.pumpWidget(const RidePoolApp());
    await tester.pumpAndSettle();

    expect(find.text('RouteMates'), findsOneWidget);
    expect(find.text('Passenger'), findsOneWidget);
    expect(find.text('Driver'), findsOneWidget);
    expect(find.text('Operations'), findsOneWidget);
    expect(find.byType(PassengerHomeView), findsOneWidget);
  });
}
