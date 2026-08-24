import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  final fixture =
      jsonDecode(File('conformance/v1/fixtures.json').readAsStringSync())
          as Map<String, Object?>;

  test('fixture declares the grader and edit tie-break contracts', () {
    expect(fixture['contractVersion'], TypingGradingPolicy.schemaVersion);
    expect(fixture['editBacktrackDirection'], 'end_to_start');
    expect(fixture['editMatchHandling'], 'consume_diagonal_before_edits');
    expect(fixture['editTieBreakOrder'], [
      'substitution',
      'deletion',
      'insertion',
    ]);
  });

  final cases = fixture['cases']! as List<Object?>;
  for (final rawCase in cases) {
    final testCase = rawCase! as Map<String, Object?>;
    test('conformance fixture: ${testCase['id']}', () {
      final rawPolicy = testCase['policy']! as Map<String, Object?>;
      final expected = testCase['expected']! as Map<String, Object?>;
      final metrics = gradeTyping(
        reference: testCase['reference']! as String,
        input: testCase['input']! as String,
        policy: TypingGradingPolicy.fromJson(rawPolicy),
        activeElapsed: Duration(
          microseconds: testCase['activeElapsedMicros']! as int,
        ),
      );
      final comparison = metrics.comparison;

      final actual = <String, Object?>{
        'normalizedReference': comparison.normalizedReference,
        'normalizedInput': comparison.normalizedInput,
        'referenceGraphemeCount': comparison.referenceCount,
        'inputGraphemeCount': comparison.inputCount,
        'editDistance': comparison.editDistance,
        'insertions': comparison.insertionCount,
        'deletions': comparison.deletionCount,
        'substitutions': comparison.substitutionCount,
        'accuracyPermille': metrics.accuracyPermille,
        'charactersPerMinuteThousandths':
            metrics.charactersPerMinuteThousandths,
      };
      if (expected.containsKey('edits')) {
        actual['edits'] = comparison.edits
            .map(
              (edit) => <String, Object?>{
                'kind': edit.kind.name,
                'referenceIndex': edit.referenceIndex,
                'inputIndex': edit.inputIndex,
                if (edit.referenceGrapheme != null)
                  'referenceGrapheme': edit.referenceGrapheme,
                if (edit.inputGrapheme != null)
                  'inputGrapheme': edit.inputGrapheme,
              },
            )
            .toList(growable: false);
      }

      expect(actual, expected);
    });
  }
}
