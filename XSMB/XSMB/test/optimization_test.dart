import 'package:flutter_test/flutter_test.dart';
import 'package:xsmb/core/models/models.dart';
import 'package:xsmb/core/services/quick_stats_service.dart';

void main() {
  group('Optimization & Caching Tests', () {
    late LotteryResult sample1;
    late LotteryResult sample2;

    setUp(() {
      sample1 = LotteryResult(
        drawDate: '2026-10-05',
        db: '12345',
        g1: '67890',
        g2: ['11122', '33344'],
        g3: ['55566', '77788', '99900', '12121', '34343', '56565'],
        g4: ['1234', '5678', '9012', '3456'],
        g5: ['1111', '2222', '3333', '4444', '5555', '6666'],
        g6: ['111', '222', '333'],
        g7: ['11', '22', '33', '44'],
        createdAt: '2026-10-05T18:30:00Z',
      );

      sample2 = LotteryResult(
        drawDate: '2026-10-05',
        db: '12345',
        g1: '67890',
        g2: ['11122', '33344'],
        g3: ['55566', '77788', '99900', '12121', '34343', '56565'],
        g4: ['1234', '5678', '9012', '3456'],
        g5: ['1111', '2222', '3333', '4444', '5555', '6666'],
        g6: ['111', '222', '333'],
        g7: ['11', '22', '33', '44'],
        createdAt: '2026-10-05T18:30:00Z',
      );
    });

    test('allNumbers and allLast2Digits are cached and correct', () {
      expect(sample1.allNumbers.length, equals(27));
      // Same object reference on repeated calls (cached)
      expect(identical(sample1.allNumbers, sample1.allNumbers), isTrue);

      expect(sample1.allLast2Digits.contains('45'), isTrue); // DB tail
      expect(sample1.allLast2Digits.contains('90'), isTrue); // G1 tail
      expect(sample1.allLast2Digits.contains('22'), isTrue); // G2 tail
      expect(sample1.allLast2Digits.contains('99'), isFalse);
      expect(identical(sample1.allLast2Digits, sample1.allLast2Digits), isTrue);
    });

    test('headStats and tailStats are cached and return correct groups', () {
      final headStats = sample1.headStats;
      expect(identical(headStats, sample1.headStats), isTrue);
      expect(headStats.containsKey(4), isTrue);

      final tailStats = sample1.tailStats;
      expect(identical(tailStats, sample1.tailStats), isTrue);
      expect(tailStats.containsKey(5), isTrue);
    });

    test('LotteryResult equality and hashCode work correctly', () {
      expect(sample1 == sample2, isTrue);
      expect(sample1.hashCode, equals(sample2.hashCode));
    });

    test('QuickStatsService computeFromLocal runs fast with cached sets', () {
      final service = QuickStatsService();
      final stats = service.computeFromLocal(
        targetDate: DateTime(2026, 10, 5),
        allHistory: [sample1, sample2],
      );

      expect(stats.targetDate, equals('05/10/2026'));
      expect(stats.lotoFrequencyList, isNotNull);
    });
  });
}
