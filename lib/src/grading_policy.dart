import 'package:characters/characters.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

/// Controls how whitespace is prepared before text comparison.
enum TypingWhitespacePolicy {
  /// Preserve all whitespace exactly.
  exact,

  /// Remove leading and trailing Unicode whitespace.
  trim,

  /// Trim and collapse each Unicode whitespace run to one ASCII space.
  collapse,
}

/// Controls how sentence-ending punctuation is prepared before comparison.
enum TypingPunctuationPolicy {
  /// Preserve sentence-ending punctuation exactly.
  exact,

  /// Remove one supported terminal punctuation grapheme.
  ignoreTerminal,
}

/// A serializable policy for the `unicode-typing-grader.v1` contract.
final class TypingGradingPolicy {
  /// Creates a grading policy from explicit whitespace and punctuation rules.
  const TypingGradingPolicy({
    required this.whitespace,
    required this.punctuation,
  });

  /// Parses a strict v1 policy map.
  ///
  /// Unknown or missing fields are rejected so independent graders cannot
  /// silently interpret the same persisted policy differently.
  factory TypingGradingPolicy.fromJson(Map<String, Object?> json) {
    const fields = {'version', 'normalization', 'whitespace', 'punctuation'};
    if (json.keys.toSet().difference(fields).isNotEmpty ||
        fields.difference(json.keys.toSet()).isNotEmpty ||
        json['version'] != schemaVersion ||
        json['normalization'] != normalization) {
      throw const FormatException('Typing grading policy shape is invalid.');
    }
    return TypingGradingPolicy(
      whitespace: switch (json['whitespace']) {
        'exact' => TypingWhitespacePolicy.exact,
        'trim' => TypingWhitespacePolicy.trim,
        'collapse' => TypingWhitespacePolicy.collapse,
        _ => throw const FormatException(
          'Typing grading whitespace policy is invalid.',
        ),
      },
      punctuation: switch (json['punctuation']) {
        'exact' => TypingPunctuationPolicy.exact,
        'ignore_terminal' => TypingPunctuationPolicy.ignoreTerminal,
        _ => throw const FormatException(
          'Typing grading punctuation policy is invalid.',
        ),
      },
    );
  }

  /// The identifier shared by serialized v1 policies and conformance data.
  static const schemaVersion = 'unicode-typing-grader.v1';

  /// The Unicode normalization form used by v1.
  static const normalization = 'nfc';

  /// A policy that preserves whitespace and punctuation exactly.
  static const exact = TypingGradingPolicy(
    whitespace: TypingWhitespacePolicy.exact,
    punctuation: TypingPunctuationPolicy.exact,
  );

  /// The whitespace preparation rule.
  final TypingWhitespacePolicy whitespace;

  /// The terminal punctuation preparation rule.
  final TypingPunctuationPolicy punctuation;

  /// Serializes this policy to the strict v1 contract shape.
  Map<String, Object> toJson() => {
    'version': schemaVersion,
    'normalization': normalization,
    'whitespace': whitespace.name,
    'punctuation': switch (punctuation) {
      TypingPunctuationPolicy.exact => 'exact',
      TypingPunctuationPolicy.ignoreTerminal => 'ignore_terminal',
    },
  };

  /// Applies v1 normalization in a deterministic order.
  String prepareForComparison(String text) {
    var prepared = unicode.nfc(text);
    prepared = switch (whitespace) {
      TypingWhitespacePolicy.exact => prepared,
      TypingWhitespacePolicy.trim => _trimWhitespace(prepared),
      TypingWhitespacePolicy.collapse => _collapseWhitespace(prepared),
    };
    if (punctuation == TypingPunctuationPolicy.ignoreTerminal) {
      prepared = _removeTerminalPunctuation(prepared);
    }
    return prepared;
  }
}

// Unicode White_Space is enumerated instead of delegated to a runtime regex.
// This snapshot prevents different runtimes from silently disagreeing after a
// Unicode database update.
bool _isV1Whitespace(int codePoint) =>
    (codePoint >= 0x0009 && codePoint <= 0x000D) ||
    codePoint == 0x0020 ||
    codePoint == 0x0085 ||
    codePoint == 0x00A0 ||
    codePoint == 0x1680 ||
    (codePoint >= 0x2000 && codePoint <= 0x200A) ||
    codePoint == 0x2028 ||
    codePoint == 0x2029 ||
    codePoint == 0x202F ||
    codePoint == 0x205F ||
    codePoint == 0x3000;

String _trimWhitespace(String text) {
  final codePoints = text.runes.toList(growable: false);
  var start = 0;
  var end = codePoints.length;
  while (start < end && _isV1Whitespace(codePoints[start])) {
    start++;
  }
  while (end > start && _isV1Whitespace(codePoints[end - 1])) {
    end--;
  }
  return String.fromCharCodes(codePoints.sublist(start, end));
}

String _collapseWhitespace(String text) {
  final trimmed = _trimWhitespace(text);
  final collapsed = <int>[];
  var insideWhitespace = false;
  for (final codePoint in trimmed.runes) {
    if (_isV1Whitespace(codePoint)) {
      if (!insideWhitespace) {
        collapsed.add(0x0020);
        insideWhitespace = true;
      }
      continue;
    }
    collapsed.add(codePoint);
    insideWhitespace = false;
  }
  return String.fromCharCodes(collapsed);
}

const _terminalPunctuation = {'.', '!', '?', '。', '！', '？'};

String _removeTerminalPunctuation(String text) {
  final graphemes = text.characters;
  if (graphemes.isEmpty || !_terminalPunctuation.contains(graphemes.last)) {
    return text;
  }
  return graphemes.skipLast(1).toString();
}
