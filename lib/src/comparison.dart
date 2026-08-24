import 'package:characters/characters.dart';
import 'package:unorm_dart/unorm_dart.dart' as unicode;

/// The operation represented by a grapheme-level edit.
enum TypingEditKind {
  /// A grapheme exists only in the typed input.
  insertion,

  /// A grapheme from the reference is missing in the typed input.
  deletion,

  /// A reference grapheme was replaced by an input grapheme.
  substitution,
}

/// Locates one minimum edit needed to turn the reference into the input.
final class TypingEdit {
  const TypingEdit._({
    required this.kind,
    required this.referenceIndex,
    required this.inputIndex,
    this.referenceGrapheme,
    this.inputGrapheme,
  });

  /// The operation performed at this position.
  final TypingEditKind kind;

  /// The grapheme index, or boundary for an insertion, in the reference.
  final int referenceIndex;

  /// The grapheme index, or boundary for a deletion, in the input.
  final int inputIndex;

  /// The affected reference grapheme, when the edit consumes one.
  final String? referenceGrapheme;

  /// The affected input grapheme, when the edit consumes one.
  final String? inputGrapheme;
}

/// An immutable NFC-normalized, grapheme-level comparison snapshot.
final class TypingComparison {
  const TypingComparison._({
    required this.normalizedReference,
    required this.normalizedInput,
    required this.referenceGraphemes,
    required this.inputGraphemes,
    required this.edits,
  });

  /// The NFC-normalized reference text.
  final String normalizedReference;

  /// The NFC-normalized typed input.
  final String normalizedInput;

  /// Extended grapheme clusters in [normalizedReference].
  final List<String> referenceGraphemes;

  /// Extended grapheme clusters in [normalizedInput].
  final List<String> inputGraphemes;

  /// The deterministic minimum edit path from reference to input.
  final List<TypingEdit> edits;

  /// The number of user-perceived characters in the reference.
  int get referenceCount => referenceGraphemes.length;

  /// The number of user-perceived characters in the input.
  int get inputCount => inputGraphemes.length;

  /// The Levenshtein distance between both grapheme sequences.
  int get editDistance => edits.length;

  /// The number of insertion edits.
  int get insertionCount => _count(TypingEditKind.insertion);

  /// The number of deletion edits.
  int get deletionCount => _count(TypingEditKind.deletion);

  /// The number of substitution edits.
  int get substitutionCount => _count(TypingEditKind.substitution);

  int _count(TypingEditKind kind) =>
      edits.where((edit) => edit.kind == kind).length;
}

/// Compares NFC text by extended grapheme cluster instead of UTF-16 code unit.
///
/// The algorithm uses O(reference length × input length) time and memory.
/// Callers should bound untrusted input before grading long documents.
TypingComparison compareNormalizedGraphemes({
  required String reference,
  required String input,
}) {
  final normalizedReference = unicode.nfc(reference);
  final normalizedInput = unicode.nfc(input);
  final referenceGraphemes = normalizedReference.characters.toList(
    growable: false,
  );
  final inputGraphemes = normalizedInput.characters.toList(growable: false);
  final costs = _editCosts(referenceGraphemes, inputGraphemes);
  final edits = _backtrackEdits(referenceGraphemes, inputGraphemes, costs);

  return TypingComparison._(
    normalizedReference: normalizedReference,
    normalizedInput: normalizedInput,
    referenceGraphemes: List.unmodifiable(referenceGraphemes),
    inputGraphemes: List.unmodifiable(inputGraphemes),
    edits: List.unmodifiable(edits),
  );
}

List<List<int>> _editCosts(List<String> reference, List<String> input) {
  final costs = List.generate(
    reference.length + 1,
    (_) => List<int>.filled(input.length + 1, 0),
  );
  for (
    var referenceIndex = 0;
    referenceIndex <= reference.length;
    referenceIndex++
  ) {
    costs[referenceIndex][0] = referenceIndex;
  }
  for (var inputIndex = 0; inputIndex <= input.length; inputIndex++) {
    costs[0][inputIndex] = inputIndex;
  }

  for (
    var referenceIndex = 1;
    referenceIndex <= reference.length;
    referenceIndex++
  ) {
    for (var inputIndex = 1; inputIndex <= input.length; inputIndex++) {
      final substitutionCost =
          reference[referenceIndex - 1] == input[inputIndex - 1] ? 0 : 1;
      costs[referenceIndex][inputIndex] = _minimum(
        costs[referenceIndex - 1][inputIndex] + 1,
        costs[referenceIndex][inputIndex - 1] + 1,
        costs[referenceIndex - 1][inputIndex - 1] + substitutionCost,
      );
    }
  }
  return costs;
}

List<TypingEdit> _backtrackEdits(
  List<String> reference,
  List<String> input,
  List<List<int>> costs,
) {
  var referenceIndex = reference.length;
  var inputIndex = input.length;
  final reversed = <TypingEdit>[];

  while (referenceIndex > 0 || inputIndex > 0) {
    if (referenceIndex > 0 &&
        inputIndex > 0 &&
        reference[referenceIndex - 1] == input[inputIndex - 1] &&
        costs[referenceIndex][inputIndex] ==
            costs[referenceIndex - 1][inputIndex - 1]) {
      referenceIndex--;
      inputIndex--;
      continue;
    }
    // Backtracking runs from both sequence ends toward their starts. After an
    // exact diagonal match, this order keeps ambiguous edit paths reproducible
    // across independent implementations.
    if (referenceIndex > 0 &&
        inputIndex > 0 &&
        costs[referenceIndex][inputIndex] ==
            costs[referenceIndex - 1][inputIndex - 1] + 1) {
      reversed.add(
        TypingEdit._(
          kind: TypingEditKind.substitution,
          referenceIndex: referenceIndex - 1,
          inputIndex: inputIndex - 1,
          referenceGrapheme: reference[referenceIndex - 1],
          inputGrapheme: input[inputIndex - 1],
        ),
      );
      referenceIndex--;
      inputIndex--;
      continue;
    }
    if (referenceIndex > 0 &&
        costs[referenceIndex][inputIndex] ==
            costs[referenceIndex - 1][inputIndex] + 1) {
      reversed.add(
        TypingEdit._(
          kind: TypingEditKind.deletion,
          referenceIndex: referenceIndex - 1,
          inputIndex: inputIndex,
          referenceGrapheme: reference[referenceIndex - 1],
        ),
      );
      referenceIndex--;
      continue;
    }
    reversed.add(
      TypingEdit._(
        kind: TypingEditKind.insertion,
        referenceIndex: referenceIndex,
        inputIndex: inputIndex - 1,
        inputGrapheme: input[inputIndex - 1],
      ),
    );
    inputIndex--;
  }

  return reversed.reversed.toList(growable: false);
}

int _minimum(int first, int second, int third) {
  var result = first < second ? first : second;
  if (third < result) {
    result = third;
  }
  return result;
}
