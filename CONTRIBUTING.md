# Contributing

Thank you for helping make Unicode typing assessment more reliable across
languages and runtimes.

## Development

Use Dart 3.8 or later, then run:

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart pub publish --dry-run
```

## Behavioral changes

Observable grading behavior is a versioned contract. When fixing or adding an
edge case:

1. Add a case to `conformance/v1/fixtures.json`.
2. Add focused Dart tests when the fixture alone does not explain the intent.
3. Keep edit-path tie breaking deterministic across implementations.
4. Propose a new contract version if an existing expected result must change.

Please keep commits and pull-request descriptions in English. Explain the
reason for a non-obvious algorithm or compatibility decision in a concise code
comment; longer explanations belong in documentation.

## Bug reports

Include the reference text, typed input, policy, expected result, actual result,
and the relevant language or Unicode behavior. Minimized reproduction cases are
especially helpful.
