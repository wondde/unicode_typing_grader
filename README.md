# unicode_typing_grader

English | [한국어](https://github.com/wondde/unicode_typing_grader/blob/main/README.ko.md) | [日本語](https://github.com/wondde/unicode_typing_grader/blob/main/README.ja.md)

[![CI](https://github.com/wondde/unicode_typing_grader/actions/workflows/ci.yml/badge.svg)](https://github.com/wondde/unicode_typing_grader/actions/workflows/ci.yml)

Unicode-aware typing assessment for Dart. Compare what a learner typed with a
reference by user-perceived characters, then calculate deterministic edits,
accuracy, and gross characters per minute (CPM).

The engine is language-neutral. Its conformance suite includes Korean Hangul,
Japanese kana, Latin combining marks, and emoji joined with zero-width joiners.

![An English language-learning typing prompt being graded for accuracy, speed, and one grapheme-level deletion](doc/assets/typing-grader-demo-en.gif)

## When would I use this?

Use this package when your product shows someone a reference and needs to
evaluate what they typed. For example:

- a language-learning app that explains exactly which character differed;
- a transcription exercise that measures accuracy and active typing speed;
- a typing assessment that must treat Hangul, kana, combining marks, and emoji
  as people see them rather than as UTF-16 code units.

It is a grading engine, not a spell checker or autocomplete service. Your app
owns the prompt, text field, timer lifecycle, and feedback UI; this package
turns the final reference, input, policy, and active duration into reproducible
results.

The animation above comes from the
[browser example](https://github.com/wondde/unicode_typing_grader/tree/main/example/web),
which calls the same `gradeTyping` API documented below.

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

Add the package from pub.dev:

```yaml
dependencies:
  unicode_typing_grader: ^0.1.0
```

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
`charactersPerMinuteThousandths` stores gross CPM multiplied by `1000`. CPM
counts input graphemes after policy preparation and does not subtract errors;
record raw keystrokes separately if your product needs them. The scaled
integers make persisted and cross-language results reproducible.

Policy preparation always runs in this order: NFC normalization, whitespace,
then terminal punctuation. A zero active duration produces zero CPM; a negative
duration is rejected.

## Conformance contract

[`conformance/v1/fixtures.json`](https://github.com/wondde/unicode_typing_grader/blob/main/conformance/v1/fixtures.json)
defines observable v1 behavior, including ambiguous edit-path tie breaking.
Independent implementations can run the same cases to verify that they agree
with the Dart package. See
[the conformance guide](https://github.com/wondde/unicode_typing_grader/blob/main/conformance/README.md).

The initial contract is tested with `characters` 1.4.1, based on Unicode 16.0
grapheme segmentation, and `unorm_dart` 0.3.2, based on Unicode 17.0
normalization data. A dependency update that changes fixture output requires an
explicit contract review instead of a silent behavior change.

## Performance boundary

The edit-path algorithm uses `O(reference graphemes × input graphemes)` time and
memory. It is intended for typing prompts and short passages. Applications must
limit untrusted input before using it to grade long documents.

## Contributing

See
[CONTRIBUTING.md](https://github.com/wondde/unicode_typing_grader/blob/main/CONTRIBUTING.md).
Bug reports and additional Unicode edge cases are welcome, especially examples
from scripts not yet represented in the conformance suite.

## License

BSD 3-Clause. See
[LICENSE](https://github.com/wondde/unicode_typing_grader/blob/main/LICENSE).
