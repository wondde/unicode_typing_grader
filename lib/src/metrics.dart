import 'dart:math' as math;

import 'comparison.dart';

/// Reproducible typing measurements and their raw calculation inputs.
final class TypingMetrics {
  const TypingMetrics._({
    required this.comparison,
    required this.activeElapsed,
    required this.accuracyPermille,
    required this.charactersPerMinuteThousandths,
  });

  /// The comparison used to calculate these metrics.
  final TypingComparison comparison;

  /// Time during which the user was actively typing.
  final Duration activeElapsed;

  /// Accuracy as a ratio scaled to 0..1000 for integer persistence.
  final int accuracyPermille;

  /// Gross prepared-input CPM multiplied by 1000 for integer persistence.
  final int charactersPerMinuteThousandths;

  /// Accuracy represented as a percentage from 0 to 100.
  double get accuracyPercent => accuracyPermille / 10;

  /// Gross prepared-input graphemes per active minute.
  ///
  /// Policy preparation can trim or collapse whitespace and remove supported
  /// terminal punctuation before this value is calculated. Errors do not
  /// reduce the grapheme count.
  double get charactersPerMinute => charactersPerMinuteThousandths / 1000;
}

/// Calculates accuracy and gross CPM from a prepared grapheme comparison.
///
/// Zero active time produces zero CPM. Throws [ArgumentError] when
/// [activeElapsed] is negative or the prepared reference is empty.
TypingMetrics calculateTypingMetrics({
  required TypingComparison comparison,
  required Duration activeElapsed,
}) {
  if (activeElapsed.isNegative) {
    throw ArgumentError.value(
      activeElapsed,
      'activeElapsed',
      'The active duration must not be negative.',
    );
  }
  if (comparison.referenceCount == 0) {
    throw ArgumentError.value(
      comparison.normalizedReference,
      'comparison.normalizedReference',
      'The normalized reference must not be empty.',
    );
  }

  final accuracyDenominator = math.max(
    comparison.referenceCount,
    comparison.inputCount,
  );
  final accuracyPermille = comparison.editDistance >= accuracyDenominator
      ? 0
      : (accuracyDenominator - comparison.editDistance) *
            1000 ~/
            accuracyDenominator;
  final elapsedMicros = activeElapsed.inMicroseconds;
  final charactersPerMinuteThousandths = elapsedMicros == 0
      ? 0
      : comparison.inputCount *
            Duration.microsecondsPerMinute *
            1000 ~/
            elapsedMicros;

  return TypingMetrics._(
    comparison: comparison,
    activeElapsed: activeElapsed,
    accuracyPermille: accuracyPermille,
    charactersPerMinuteThousandths: charactersPerMinuteThousandths,
  );
}

/// Measures active typing time from a monotonic duration source.
final class ActiveTypingTimer {
  /// Creates a timer with an optional monotonic source for deterministic tests.
  ActiveTypingTimer({Duration Function()? readMonotonic})
    : _readMonotonic = readMonotonic ?? _defaultMonotonicNow;

  static final Stopwatch _defaultClock = Stopwatch()..start();

  final Duration Function() _readMonotonic;
  Duration _accumulated = Duration.zero;
  Duration? _segmentStartedAt;
  Duration? _lastObservedAt;

  /// Whether an active timing segment is running.
  bool get isRunning => _segmentStartedAt != null;

  /// The accumulated active duration, including the current segment.
  Duration get elapsed {
    final segmentStartedAt = _segmentStartedAt;
    if (segmentStartedAt == null) {
      return _accumulated;
    }
    return _accumulated + _elapsedSince(segmentStartedAt);
  }

  /// Starts a new active segment or resumes after a pause.
  void startOrResume() {
    _segmentStartedAt ??= _observeMonotonic();
  }

  /// Ends the current active segment while retaining its elapsed duration.
  void pause() {
    final segmentStartedAt = _segmentStartedAt;
    if (segmentStartedAt == null) {
      return;
    }
    _accumulated += _elapsedSince(segmentStartedAt);
    _segmentStartedAt = null;
  }

  /// Clears active and retained time for a new typing item.
  void reset() {
    _accumulated = Duration.zero;
    _segmentStartedAt = null;
  }

  Duration _elapsedSince(Duration startedAt) {
    return _observeMonotonic() - startedAt;
  }

  Duration _observeMonotonic() {
    final now = _readMonotonic();
    final lastObservedAt = _lastObservedAt;
    if (lastObservedAt != null && now < lastObservedAt) {
      // A decreasing clock would add negative active time and corrupt every
      // downstream metric, so injected clocks must remain monotonic.
      throw StateError('The monotonic duration source moved backwards.');
    }
    _lastObservedAt = now;
    return now;
  }

  static Duration _defaultMonotonicNow() => _defaultClock.elapsed;
}
