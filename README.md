# unicode_typing_grader

English | [한국어](README.ko.md) | [日本語](README.ja.md)

Unicode-aware typing assessment for Dart. Compare what a learner typed with a
reference by user-perceived characters, then calculate deterministic edits,
accuracy, and gross characters per minute (CPM).

The engine is language-neutral. Its conformance suite includes Korean Hangul,
Japanese kana, Latin combining marks, and emoji joined with zero-width joiners.

Originally extracted from **Hangurinyang**, a Korean-learning product by Moroo.

## Features

- NFC normalization before comparison
- Extended grapheme cluster comparison instead of UTF-16 code units
- Deterministic insertion, deletion, and substitution paths
- Exact, trim, and collapse whitespace policies
- Exact or ignored terminal punctuation policies
- Integer-backed accuracy and CPM metrics
- Monotonic active-typing timer
- Versioned, language-neutral JSON conformance fixtures
- Pure Dart with no Flutter dependency

## Installation

The first development release has not been published to pub.dev yet. Depend on
the Git repository while the public API is being validated:

```yaml
dependencies:
  unicode_typing_grader:
    git:
      url: https://github.com/wondde/unicode_typing_grader.git
      ref: main
```

Pin a release tag or commit in production instead of tracking `main`.

## Usage

```dart
import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  final result = gradeTyping(
    reference: '안녕하세요',
    input: '안녕하새요',
    policy: TypingGradingPolicy.exact,
    activeElapsed: const Duration(seconds: 30),
  );

  print(result.accuracyPercent); // 80.0
  print(result.charactersPerMinute); // 10.0
  print(result.comparison.substitutionCount); // 1
}
```

The same comparison treats canonically equivalent Japanese kana as equal:

```dart
final comparison = compareNormalizedGraphemes(
  reference: 'が',
  input: 'か\u3099',
);

print(comparison.editDistance); // 0
```

## Comparison policies

`TypingGradingPolicy` is explicit and serializable so a client and server can
apply the same rules.

| Policy | Values | Behavior |
| --- | --- | --- |
| Whitespace | `exact` | Preserve every whitespace character |
| Whitespace | `trim` | Remove leading and trailing v1 Unicode whitespace |
| Whitespace | `collapse` | Trim and replace each whitespace run with one ASCII space |
| Punctuation | `exact` | Preserve punctuation |
| Punctuation | `ignoreTerminal` | Remove one `.`, `!`, `?`, `。`, `！`, or `？` at the end |

All v1 policies normalize text to NFC before applying these rules.

## Metric definitions

Accuracy uses the longer grapheme sequence as its denominator:

```text
accuracy = max(0, max(reference, input) - editDistance)
           / max(reference, input)
```

`accuracyPermille` stores this ratio as an integer from `0` to `1000`.
`charactersPerMinuteThousandths` stores gross input CPM multiplied by `1000`.
The scaled integers make persisted and cross-language results reproducible.

## Conformance contract

[`conformance/v1/fixtures.json`](conformance/v1/fixtures.json) defines observable
v1 behavior, including ambiguous edit-path tie breaking. Independent
implementations can run the same cases to verify that they agree with the Dart
package. See [the conformance guide](conformance/README.md).

The initial contract is tested with `characters` 1.4.1, based on Unicode 16.0
grapheme segmentation, and `unorm_dart` 0.3.2, based on Unicode 17.0
normalization data. A dependency update that changes fixture output requires an
explicit contract review instead of a silent behavior change.

## Performance boundary

The edit-path algorithm uses `O(reference graphemes × input graphemes)` time and
memory. It is intended for typing prompts and short passages. Applications must
limit untrusted input before using it to grade long documents.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and additional Unicode edge
cases are welcome, especially examples from scripts not yet represented in the
conformance suite.

## License

BSD 3-Clause. See [LICENSE](LICENSE).
