import 'package:test/test.dart';
import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  group('calculateTypingMetrics', () {
    test('calculates accuracy and gross input CPM separately', () {
      final comparison = compareNormalizedGraphemes(
        reference: '안녕하세요',
        input: '안녕하새요',
      );

      final metrics = calculateTypingMetrics(
        comparison: comparison,
        activeElapsed: const Duration(seconds: 30),
      );

      expect(metrics.accuracyPermille, 800);
      expect(metrics.accuracyPercent, 80);
      expect(metrics.charactersPerMinuteThousandths, 10000);
      expect(metrics.charactersPerMinute, 10);
    });

    test('uses the longer side as the accuracy denominator', () {
      final metrics = calculateTypingMetrics(
        comparison: compareNormalizedGraphemes(reference: '가', input: '가나다'),
        activeElapsed: const Duration(minutes: 1),
      );

      expect(metrics.accuracyPermille, 333);
      expect(metrics.charactersPerMinute, 3);
    });

    test('returns zero speed when no active time was measured', () {
      final metrics = calculateTypingMetrics(
        comparison: compareNormalizedGraphemes(reference: '가', input: ''),
        activeElapsed: Duration.zero,
      );

      expect(metrics.accuracyPermille, 0);
      expect(metrics.charactersPerMinuteThousandths, 0);
    });

    test('rejects a negative active duration', () {
      expect(
        () => calculateTypingMetrics(
          comparison: compareNormalizedGraphemes(reference: '가', input: '가'),
          activeElapsed: const Duration(microseconds: -1),
        ),
        throwsArgumentError,
      );
    });

    test('keeps short-session precision in fixed-point CPM', () {
      final metrics = calculateTypingMetrics(
        comparison: compareNormalizedGraphemes(reference: '가', input: '가'),
        activeElapsed: const Duration(milliseconds: 1500),
      );

      expect(metrics.charactersPerMinuteThousandths, 40000);
      expect(metrics.charactersPerMinute, 40);
    });

    test('rejects an empty normalized reference', () {
      expect(
        () => calculateTypingMetrics(
          comparison: compareNormalizedGraphemes(reference: '', input: ''),
          activeElapsed: const Duration(seconds: 1),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ActiveTypingTimer', () {
    test('excludes paused time and resumes with retained duration', () {
      var now = Duration.zero;
      final timer = ActiveTypingTimer(readMonotonic: () => now);

      timer.startOrResume();
      now = const Duration(seconds: 3);
      timer.pause();
      now = const Duration(seconds: 10);
      expect(timer.elapsed, const Duration(seconds: 3));

      timer.startOrResume();
      now = const Duration(seconds: 12);
      expect(timer.elapsed, const Duration(seconds: 5));
      timer.pause();
      expect(timer.elapsed, const Duration(seconds: 5));
    });

    test('reset clears both active and retained time', () {
      var now = Duration.zero;
      final timer = ActiveTypingTimer(readMonotonic: () => now)
        ..startOrResume();
      now = const Duration(seconds: 2);

      timer.reset();

      expect(timer.elapsed, Duration.zero);
      expect(timer.isRunning, isFalse);
    });

    test('rejects a duration source that moves backwards', () {
      var now = Duration.zero;
      final timer = ActiveTypingTimer(readMonotonic: () => now)
        ..startOrResume();
      now = const Duration(seconds: 10);
      expect(timer.elapsed, const Duration(seconds: 10));
      now = const Duration(seconds: 5);

      expect(() => timer.elapsed, throwsStateError);
    });

    test('retains monotonic validation across pause and resume', () {
      var now = Duration.zero;
      final timer = ActiveTypingTimer(readMonotonic: () => now)
        ..startOrResume();
      now = const Duration(seconds: 3);
      timer.pause();
      now = const Duration(seconds: 2);

      expect(timer.startOrResume, throwsStateError);
      expect(timer.isRunning, isFalse);
    });
  });
}
