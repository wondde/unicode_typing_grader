import 'package:test/test.dart';
import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  group('compareNormalizedGraphemes', () {
    test('treats composed and decomposed Hangul as the same text', () {
      final comparison = compareNormalizedGraphemes(
        reference: '가',
        input: '\u1100\u1161',
      );

      expect(comparison.normalizedInput, '가');
      expect(comparison.referenceCount, 1);
      expect(comparison.inputCount, 1);
      expect(comparison.editDistance, 0);
    });

    test('treats composed and decomposed Japanese kana as the same text', () {
      final comparison = compareNormalizedGraphemes(
        reference: 'が',
        input: 'か\u3099',
      );

      expect(comparison.normalizedInput, 'が');
      expect(comparison.referenceCount, 1);
      expect(comparison.inputCount, 1);
      expect(comparison.editDistance, 0);
    });

    test('does not split an emoji joined by zero-width joiners', () {
      final comparison = compareNormalizedGraphemes(
        reference: 'cat 👩🏽‍💻',
        input: 'cat 👩🏽‍💻',
      );

      expect(comparison.referenceGraphemes.last, '👩🏽‍💻');
      expect(comparison.referenceCount, 5);
      expect(comparison.editDistance, 0);
    });

    test('reports deterministic insertion deletion and substitution paths', () {
      final insertion = compareNormalizedGraphemes(
        reference: '가나',
        input: '가나다',
      );
      final deletion = compareNormalizedGraphemes(
        reference: '가나다',
        input: '가나',
      );
      final substitution = compareNormalizedGraphemes(
        reference: '가나다',
        input: '가마라',
      );

      expect(insertion.insertionCount, 1);
      expect(insertion.edits.single.inputGrapheme, '다');
      expect(deletion.deletionCount, 1);
      expect(deletion.edits.single.referenceGrapheme, '다');
      expect(substitution.substitutionCount, 2);
      expect(substitution.edits.map((edit) => edit.referenceIndex), [1, 2]);
    });

    test('counts a combining-mark sequence as one visible character', () {
      final comparison = compareNormalizedGraphemes(
        reference: '각',
        input: '가\u302E',
      );

      expect(comparison.inputCount, 1);
      expect(comparison.substitutionCount, 1);
    });

    test('owns immutable grapheme and edit snapshots', () {
      final comparison = compareNormalizedGraphemes(reference: '가', input: '나');

      expect(
        () => comparison.referenceGraphemes.add('다'),
        throwsUnsupportedError,
      );
      expect(() => comparison.inputGraphemes.clear(), throwsUnsupportedError);
      expect(() => comparison.edits.clear(), throwsUnsupportedError);
    });
  });
}
