import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  final result = gradeTyping(
    reference: 'こんにちは。',
    input: 'こんにちは',
    policy: const TypingGradingPolicy(
      whitespace: TypingWhitespacePolicy.exact,
      punctuation: TypingPunctuationPolicy.ignoreTerminal,
    ),
    activeElapsed: const Duration(seconds: 20),
  );

  print('Accuracy: ${result.accuracyPercent}%');
  print('CPM: ${result.charactersPerMinute}');
  print('Edits: ${result.comparison.editDistance}');
}
