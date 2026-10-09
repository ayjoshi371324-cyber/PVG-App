import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ridepool_app/core/engine/detour_validator.dart';
import 'package:ridepool_app/core/engine/shapley_calculator.dart';

void main() {
  group('Golden Fixtures Verification', () {
    late Map<String, dynamic> goldenData;

    setUpAll(() {
      // Find golden_fares.json relative to project root or mobile/
      var file = File('../contracts/fixtures/golden_fares.json');
      if (!file.existsSync()) {
        file = File('../../contracts/fixtures/golden_fares.json');
      }
      if (!file.existsSync()) {
        file = File('contracts/fixtures/golden_fares.json');
      }
      expect(file.existsSync(), isTrue, reason: 'golden_fares.json must exist');
      goldenData = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Case 1: A, B, C on one line to same drop (4 + 3 + 5 km)', () {
      final case1 = (goldenData['cases'] as List)
          .firstWhere((c) => c['id'] == 'case_1') as Map<String, dynamic>;

      final coalitionValues = (case1['coalition_values'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k.split(','), (v as num).toDouble()));

      final players = ['A', 'B', 'C'];
      final totalCost = (case1['total_cost'] as num).toDouble();

      final result = ShapleyCalculator.calculate(
        players: players,
        coalitionCost: (subset) {
          if (subset.isEmpty) return 0.0;
          for (final entry in coalitionValues.entries) {
            final keySet = entry.key.toSet();
            if (keySet.length == subset.length && keySet.containsAll(subset)) {
              return entry.value;
            }
          }
          return totalCost;
        },
        totalCost: totalCost,
        soloFares: {'A': 140.0, 'B': 100.0, 'C': 70.0},
      );

      // Verify raw shares
      expect(result.rawShares['A'], closeTo(78.333, 0.001));
      expect(result.rawShares['B'], closeTo(38.333, 0.001));
      expect(result.rawShares['C'], closeTo(23.333, 0.001));

      // Verify rounded shares sum exactly to totalCost (140.00)
      final sumRounded = result.roundedShares.values.fold(0.0, (a, b) => a + b);
      expect(sumRounded, closeTo(140.0, 0.0001));
      expect(result.roundedShares['A'], equals(78.33));
      expect(result.roundedShares['B'], equals(38.34));
      expect(result.roundedShares['C'], equals(23.33));
    });

    test('Case 2: A 8 km, B 9 km, shared 12 km', () {
      final case2 = (goldenData['cases'] as List)
          .firstWhere((c) => c['id'] == 'case_2') as Map<String, dynamic>;

      final players = ['A', 'B'];
      final totalCost = (case2['total_cost'] as num).toDouble();

      final result = ShapleyCalculator.calculate(
        players: players,
        coalitionCost: (subset) {
          if (subset.isEmpty) return 0.0;
          if (subset.length == 1 && subset.contains('A')) return 100.0;
          if (subset.length == 1 && subset.contains('B')) return 110.0;
          return 140.0;
        },
        totalCost: totalCost,
        soloFares: {'A': 100.0, 'B': 110.0},
      );

      expect(result.roundedShares['A'], equals(65.0));
      expect(result.roundedShares['B'], equals(75.0));
      expect(result.roundedShares.values.fold(0.0, (a, b) => a + b), equals(140.0));
    });

    test('Case 3: Party AC (party_size 2) and Rider B (per-booking policy)', () {
      final case3 = (goldenData['cases'] as List)
          .firstWhere((c) => c['id'] == 'case_3') as Map<String, dynamic>;

      final players = ['AC', 'B'];
      final totalCost = (case3['total_cost'] as num).toDouble();

      final result = ShapleyCalculator.calculate(
        players: players,
        coalitionCost: (subset) {
          if (subset.isEmpty) return 0.0;
          if (subset.length == 1 && subset.contains('AC')) return 100.0;
          if (subset.length == 1 && subset.contains('B')) return 100.0;
          return 130.0;
        },
        totalCost: totalCost,
        soloFares: {'AC': 100.0, 'B': 100.0},
        partySizes: {'AC': 2, 'B': 1},
      );

      expect(result.roundedShares['AC'], equals(65.0));
      expect(result.roundedShares['B'], equals(65.0));
      expect(result.perPersonShares['AC'], equals(32.5));
      expect(result.perPersonShares['B'], equals(65.0));
    });

    test('Case 4: A 0-7, B 4-14, C 9-14, shared 14 km (Strict Shapley: 65 / 60 / 35)', () {
      final case4 = (goldenData['cases'] as List)
          .firstWhere((c) => c['id'] == 'case_4') as Map<String, dynamic>;

      final players = ['A', 'B', 'C'];
      final totalCost = (case4['total_cost'] as num).toDouble();

      final result = ShapleyCalculator.calculate(
        players: players,
        coalitionCost: (subset) {
          if (subset.isEmpty) return 0.0;
          final s = subset.toSet();
          if (s.length == 1) {
            if (s.contains('A')) return 90.0;
            if (s.contains('B')) return 120.0;
            if (s.contains('C')) return 70.0;
          }
          if (s.length == 2) {
            if (s.containsAll({'A', 'B'})) return 160.0;
            if (s.containsAll({'A', 'C'})) return 160.0;
            if (s.containsAll({'B', 'C'})) return 120.0;
          }
          return 160.0;
        },
        totalCost: totalCost,
        soloFares: {'A': 90.0, 'B': 120.0, 'C': 70.0},
      );

      expect(result.roundedShares['A'], equals(65.0));
      expect(result.roundedShares['B'], equals(60.0));
      expect(result.roundedShares['C'], equals(35.0));
      expect(result.roundedShares.values.fold(0.0, (a, b) => a + b), equals(160.0));
    });

    test('Case 5: B alone + A,C pooled with solo fare ceiling cap', () {
      final players = ['A', 'B', 'C'];
      final totalCost = 150.0;

      final result = ShapleyCalculator.calculate(
        players: players,
        coalitionCost: (subset) {
          if (subset.isEmpty) return 0.0;
          final s = subset.toSet();
          if (s.length == 1) {
            if (s.contains('A')) return 80.0;
            if (s.contains('B')) return 70.0;
            if (s.contains('C')) return 80.0;
          }
          if (s.length == 2) {
            if (s.containsAll({'A', 'C'})) return 80.0;
            return 150.0;
          }
          return 150.0;
        },
        totalCost: totalCost,
        soloFares: {'A': 80.0, 'B': 70.0, 'C': 80.0},
      );

      // Verify solo ceiling: no player exceeds their solo fare
      expect(result.roundedShares['A']! <= 80.0, isTrue);
      expect(result.roundedShares['B']! <= 70.0, isTrue);
      expect(result.roundedShares['C']! <= 80.0, isTrue);
      expect(result.roundedShares.values.fold(0.0, (a, b) => a + b), equals(150.0));
    });

    test('DetourValidator enforces strict 15% guarantee', () {
      const validator = DetourValidator(maxDetourRatio: 0.15);

      expect(validator.isDetourValid(10.0, 11.2), isTrue); // 12%
      expect(validator.calculateDetourPercent(10.0, 11.2), closeTo(12.0, 0.01));

      expect(validator.isDetourValid(10.0, 11.8), isFalse); // 18%
      expect(validator.calculateDetourPercent(10.0, 11.8), closeTo(18.0, 0.01));
    });
  });
}
