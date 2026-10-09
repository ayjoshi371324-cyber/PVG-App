import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/data/models/ops_fleet_models.dart';
import 'package:ridepool_app/widgets/comparative_benchmark_card.dart';

void main() {
  group('ComparativeBenchmarkCard Widget Tests', () {
    const benchmark = BenchmarkMetrics(
      vktAlgorithmic: 142.6,
      vktGreedy: 231.0,
      detourAlgorithmic: 8.4,
      detourGreedy: 24.6,
      fareSavingsPercentAlgorithmic: 32.5,
      fareSavingsPercentGreedy: 7.5,
    );

    testWidgets('renders algorithmic pooling vs greedy baseline side-by-side metrics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ComparativeBenchmarkCard(
                benchmark: benchmark,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pooling vs. Greedy Baseline'), findsOneWidget);
      expect(find.text('Algorithmic Pooling'), findsOneWidget);
      expect(find.text('Greedy Baseline'), findsOneWidget);

      // Metric values
      expect(find.textContaining('142.6 km'), findsOneWidget);
      expect(find.textContaining('231.0 km'), findsOneWidget);
      expect(find.textContaining('8.4%'), findsOneWidget);
      expect(find.textContaining('24.6%'), findsOneWidget);
      expect(find.textContaining('32.5%'), findsOneWidget);
      expect(find.textContaining('7.5%'), findsOneWidget);

      // Savings badge
      expect(find.textContaining('38.3% VKT Saved'), findsOneWidget);
    });
  });
}
