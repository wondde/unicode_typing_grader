import 'package:test/test.dart';
import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  group('TypingGradingPolicy', () {
    test('strictly parses and serializes the v1 contract', () {
      final policy = TypingGradingPolicy.fromJson(const {
        'version': 'unicode-typing-grader.v1',
        'normalization': 'nfc',
        'whitespace': 'collapse',
        'punctuation': 'ignore_terminal',
      });

      expect(policy.whitespace, TypingWhitespacePolicy.collapse);
      expect(policy.punctuation, TypingPunctuationPolicy.ignoreTerminal);
      expect(policy.toJson(), {
        'version': 'unicode-typing-grader.v1',
        'normalization': 'nfc',
        'whitespace': 'collapse',
        'punctuation': 'ignore_terminal',
      });
    });

    test('rejects unknown versions, values, and fields', () {
      Map<String, Object?> policy({
        String version = 'unicode-typing-grader.v1',
        String whitespace = 'exact',
      }) => {
        'version': version,
        'normalization': 'nfc',
        'whitespace': whitespace,
        'punctuation': 'exact',
      };

      expect(
        () => TypingGradingPolicy.fromJson(policy(version: 'v2')),
        throwsFormatException,
      );
      expect(
        () => TypingGradingPolicy.fromJson(policy(whitespace: 'ignore')),
        throwsFormatException,
      );
      expect(
        () => TypingGradingPolicy.fromJson({...policy(), 'case': 'ignore'}),
        throwsFormatException,
      );
    });

    test('trim removes only leading and trailing v1 Unicode whitespace', () {
      const policy = TypingGradingPolicy(
        whitespace: TypingWhitespacePolicy.trim,
        punctuation: TypingPunctuationPolicy.exact,
      );

      expect(policy.prepareForComparison('\u3000안녕\u00A0 친구\n'), '안녕\u00A0 친구');
    });

    test('collapse changes every whitespace run to one ASCII space', () {
      const policy = TypingGradingPolicy(
        whitespace: TypingWhitespacePolicy.collapse,
        punctuation: TypingPunctuationPolicy.exact,
      );

      expect(policy.prepareForComparison('  안녕\t\u3000친구  '), '안녕 친구');
    });

    test('ignoreTerminal removes one allowed sentence-ending grapheme', () {
      const policy = TypingGradingPolicy(
        whitespace: TypingWhitespacePolicy.exact,
        punctuation: TypingPunctuationPolicy.ignoreTerminal,
      );

      expect(policy.prepareForComparison('안녕하세요！'), '안녕하세요');
      expect(policy.prepareForComparison('こんにちは。'), 'こんにちは');
      expect(policy.prepareForComparison('정말?!'), '정말?');
      expect(policy.prepareForComparison('잠시만…'), '잠시만…');
      expect(policy.prepareForComparison('안녕하세요. '), '안녕하세요. ');
    });
  });

  group('gradeTyping', () {
    test('applies content policy before comparison and metrics', () {
      const policy = TypingGradingPolicy(
        whitespace: TypingWhitespacePolicy.collapse,
        punctuation: TypingPunctuationPolicy.ignoreTerminal,
      );

      final metrics = gradeTyping(
        reference: '안녕 친구.',
        input: '  안녕\t친구！ ',
        policy: policy,
        activeElapsed: const Duration(seconds: 30),
      );

      expect(metrics.comparison.normalizedReference, '안녕 친구');
      expect(metrics.comparison.normalizedInput, '안녕 친구');
      expect(metrics.accuracyPermille, 1000);
      expect(metrics.charactersPerMinute, 10);
    });
  });
}
