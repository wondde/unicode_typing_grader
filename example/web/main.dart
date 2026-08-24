import 'dart:async';
import 'dart:js_interop';

import 'package:unicode_typing_grader/unicode_typing_grader.dart';
import 'package:web/web.dart' as web;

final _referenceText =
    web.document.querySelector('#reference-text')! as web.HTMLElement;
final _scenarioTitle =
    web.document.querySelector('#scenario-title')! as web.HTMLElement;
final _typingInput =
    web.document.querySelector('#typing-input')! as web.HTMLTextAreaElement;
final _elapsedTime =
    web.document.querySelector('#elapsed-time')! as web.HTMLElement;
final _gradeButton =
    web.document.querySelector('#grade-button')! as web.HTMLButtonElement;
final _koreanButton =
    web.document.querySelector('#korean-sample')! as web.HTMLButtonElement;
final _japaneseButton =
    web.document.querySelector('#japanese-sample')! as web.HTMLButtonElement;
final _emptyState =
    web.document.querySelector('#empty-state')! as web.HTMLElement;
final _gradedState =
    web.document.querySelector('#graded-state')! as web.HTMLElement;
final _accuracyValue =
    web.document.querySelector('#accuracy-value')! as web.HTMLElement;
final _cpmValue = web.document.querySelector('#cpm-value')! as web.HTMLElement;
final _editCount =
    web.document.querySelector('#edit-count')! as web.HTMLElement;
final _editMessage =
    web.document.querySelector('#edit-message')! as web.HTMLElement;
final _expectedValue =
    web.document.querySelector('#expected-value')! as web.HTMLElement;
final _receivedValue =
    web.document.querySelector('#received-value')! as web.HTMLElement;
final _resultSummary =
    web.document.querySelector('#result-summary')! as web.HTMLElement;

const _policy = TypingGradingPolicy(
  whitespace: TypingWhitespacePolicy.collapse,
  punctuation: TypingPunctuationPolicy.ignoreTerminal,
);

var _activeSample = _Sample.korean;

void main() {
  _gradeButton.addEventListener('click', ((web.Event _) => _grade()).toJS);
  _koreanButton.addEventListener(
    'click',
    ((web.Event _) => _selectSample(_Sample.korean)).toJS,
  );
  _japaneseButton.addEventListener(
    'click',
    ((web.Event _) => _selectSample(_Sample.japanese)).toJS,
  );

  if (web.window.location.search.contains('autoplay=1')) {
    unawaited(_runAutomaticDemo());
  }
}

void _grade() {
  final sample = _activeSample;
  final input = _typingInput.value;
  if (input.trim().isEmpty) {
    _typingInput.focus();
    return;
  }

  final result = gradeTyping(
    reference: sample.reference,
    input: input,
    policy: _policy,
    activeElapsed: sample.elapsed,
  );
  final comparison = result.comparison;

  _accuracyValue.textContent = '${result.accuracyPercent.toStringAsFixed(1)}%';
  _cpmValue.textContent = result.charactersPerMinute.toStringAsFixed(1);
  _editCount.textContent = '${comparison.editDistance}';
  _editMessage.textContent = _describeFirstEdit(comparison);
  _expectedValue.textContent = comparison.normalizedReference;
  _receivedValue.textContent = comparison.normalizedInput;
  _resultSummary.textContent = comparison.editDistance == 0
      ? 'Perfect match'
      : '${comparison.editDistance} detail to review';

  _emptyState.hidden = true.toJS;
  _gradedState.hidden = false.toJS;
}

String _describeFirstEdit(TypingComparison comparison) {
  if (comparison.edits.isEmpty) {
    return 'No differences found';
  }
  final edit = comparison.edits.first;
  return switch (edit.kind) {
    TypingEditKind.insertion => 'Extra “${edit.inputGrapheme}” in the input',
    TypingEditKind.deletion =>
      'Missing “${edit.referenceGrapheme}” from the reference',
    TypingEditKind.substitution =>
      'Expected “${edit.referenceGrapheme}” · received “${edit.inputGrapheme}”',
  };
}

void _selectSample(_Sample sample) {
  _activeSample = sample;
  _scenarioTitle.textContent = sample.title;
  _referenceText.textContent = sample.reference;
  _elapsedTime.textContent = '${sample.elapsed.inSeconds}s';
  _typingInput.value = '';
  _typingInput.placeholder = sample.placeholder;
  _koreanButton.className = sample == _Sample.korean
      ? 'sample-button is-active'
      : 'sample-button';
  _japaneseButton.className = sample == _Sample.japanese
      ? 'sample-button is-active'
      : 'sample-button';
  _emptyState.hidden = false.toJS;
  _gradedState.hidden = true.toJS;
  _typingInput.focus();
}

Future<void> _runAutomaticDemo() async {
  await Future<void>.delayed(const Duration(milliseconds: 650));
  _typingInput.focus();
  for (final codePoint in _activeSample.attempt.runes) {
    _typingInput.value += String.fromCharCode(codePoint);
    await Future<void>.delayed(const Duration(milliseconds: 105));
  }
  await Future<void>.delayed(const Duration(milliseconds: 450));
  _gradeButton.click();
}

enum _Sample {
  korean(
    title: 'A learner practices Korean',
    reference: '오늘은 날씨가 좋아요.',
    attempt: '오늘은 날씨가 조아요',
    placeholder: '한국어 문장을 입력하세요…',
    elapsed: Duration(seconds: 24),
  ),
  japanese(
    title: 'A learner practices Japanese',
    reference: '今日は天気がいいです。',
    attempt: '今日は天気がいです',
    placeholder: '日本語の文章を入力してください…',
    elapsed: Duration(seconds: 28),
  );

  const _Sample({
    required this.title,
    required this.reference,
    required this.attempt,
    required this.placeholder,
    required this.elapsed,
  });

  final String title;
  final String reference;
  final String attempt;
  final String placeholder;
  final Duration elapsed;
}
