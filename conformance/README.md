# Conformance fixtures

`v1/fixtures.json` is an executable description of the
`unicode-typing-grader.v1` behavior. It allows implementations in Dart, Go, or
other languages to produce the same normalized text, edit path, and metrics.

Each case contains:

| Field | Meaning |
| --- | --- |
| `reference`, `input` | Text before policy preparation |
| `activeElapsedMicros` | Integer active duration in microseconds |
| `policy` | Versioned normalization, whitespace, and punctuation rules |
| `expected.normalized*` | Text after NFC normalization and policy preparation |
| `expected.*GraphemeCount` | Extended grapheme cluster counts |
| `expected.editDistance` | Minimum grapheme-level edit count |
| `expected.insertions`, `deletions`, `substitutions` | Components of the deterministic edit path |
| `expected.edits` | Grapheme indices and boundaries for path-sensitive cases |
| `expected.accuracyPermille` | Accuracy ratio multiplied by 1000 |
| `expected.charactersPerMinuteThousandths` | Gross prepared-input CPM multiplied by 1000 |

The top-level `editBacktrackDirection`, `editMatchHandling`, and
`editTieBreakOrder` fields are also part of the contract. Add edge cases with a
stable, descriptive `id`. Do not change an existing expected result unless the
contract version changes.

CPM counts the input graphemes left after policy preparation and does not
subtract errors. Applications that need raw keystrokes or pre-policy text
length should record that measurement separately.
