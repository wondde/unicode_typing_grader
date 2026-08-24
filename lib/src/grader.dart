import 'comparison.dart';
import 'grading_policy.dart';
import 'metrics.dart';

/// Grades committed text after applying one immutable comparison policy.
///
/// Throws [ArgumentError] when [activeElapsed] is negative or policy
/// preparation leaves the reference empty.
TypingMetrics gradeTyping({
  required String reference,
  required String input,
  required TypingGradingPolicy policy,
  required Duration activeElapsed,
}) {
  final comparison = compareNormalizedGraphemes(
    reference: policy.prepareForComparison(reference),
    input: policy.prepareForComparison(input),
  );
  return calculateTypingMetrics(
    comparison: comparison,
    activeElapsed: activeElapsed,
  );
}
