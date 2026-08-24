# unicode_typing_grader

[English](README.md) | [한국어](README.ko.md) | 日本語

Dart向けのUnicode対応タイピング評価ライブラリです。お手本と入力された文章を
ユーザーが認識する文字単位で比較し、決定的な編集内容、正確度、1分あたりの
入力文字数（CPM）を計算します。

エンジンは特定の言語に依存しません。公式の適合性テストには、韓国語の
ハングル、日本語の仮名、ラテン文字の結合文字、ゼロ幅接合子を含む絵文字が
含まれています。

Morooの韓国語学習プロダクト **Hangurinyang（한그리냥）** で開発された
エンジンを、独立したオープンソースパッケージとして分離しました。

## 主な機能

- 比較前のNFC正規化
- UTF-16コードユニットではなく拡張書記素クラスタ単位での比較
- 常に同じ結果を返す挿入・削除・置換の編集経路
- 空白の完全一致、前後削除、連続空白の圧縮ポリシー
- 文末記号を比較する、または無視するポリシー
- 整数で保存できる正確度とCPM
- 単調増加する時間源を使ったアクティブ入力タイマー
- バージョン管理された言語中立のJSON適合性fixture
- Flutterに依存しないPure Dartパッケージ

## インストール

最初の開発版はまだpub.devに公開されていません。公開APIを検証している間は、
Gitリポジトリを依存関係として指定してください。

```yaml
dependencies:
  unicode_typing_grader:
    git:
      url: https://github.com/wondde/unicode_typing_grader.git
      ref: main
```

本番環境では`main`ではなく、リリースタグまたはコミットを固定してください。

## 使い方

```dart
import 'package:unicode_typing_grader/unicode_typing_grader.dart';

void main() {
  final result = gradeTyping(
    reference: 'こんにちは。',
    input: 'こんにちは',
    policy: const TypingGradingPolicy(
      whitespace: TypingWhitespacePolicy.exact,
      punctuation: TypingPunctuationPolicy.ignoreTerminal,
    ),
    activeElapsed: const Duration(seconds: 20),
  );

  print(result.accuracyPercent); // 100.0
  print(result.charactersPerMinute); // 15.0
  print(result.comparison.editDistance); // 0
}
```

正規化すると同じになる仮名も、同一の文字として扱います。

```dart
final comparison = compareNormalizedGraphemes(
  reference: 'が',
  input: 'か\u3099',
);

print(comparison.editDistance); // 0
```

## 比較ポリシー

`TypingGradingPolicy`はシリアライズできます。そのため、クライアントと
サーバーで同じ評価ルールを共有できます。

| 種類 | 値 | 動作 |
| --- | --- | --- |
| 空白 | `exact` | すべての空白をそのまま比較します。 |
| 空白 | `trim` | 前後のv1 Unicode空白を削除します。 |
| 空白 | `collapse` | 前後を削除し、連続する空白を1個のASCIIスペースに変換します。 |
| 句読点 | `exact` | 句読点をそのまま比較します。 |
| 句読点 | `ignoreTerminal` | 末尾の`.`, `!`, `?`, `。`, `！`, `？`のいずれか1文字を削除します。 |

すべてのv1ポリシーは、これらの規則を適用する前に文章をNFC正規化します。

## 指標の定義

正確度の分母には、お手本と入力のうち長い方の書記素数を使います。

```text
accuracy = max(0, max(reference, input) - editDistance)
           / max(reference, input)
```

`accuracyPermille`は正確度を`0`から`1000`までの整数で保持します。
`charactersPerMinuteThousandths`は入力CPMを`1000`倍した整数です。整数表現に
よって、永続化した値や異なるプログラミング言語の間でも同じ結果を再現しやすく
なります。

## 適合性コントラクト

[`conformance/v1/fixtures.json`](conformance/v1/fixtures.json)は、曖昧な編集経路の
優先順位を含むv1の動作を定義します。他の言語による実装も同じfixtureを実行し、
Dartパッケージと一致することを確認できます。詳細は
[適合性ガイド](conformance/README.md)を参照してください。

最初のコントラクトは、Unicode 16.0の書記素分割に基づく`characters` 1.4.1と、
Unicode 17.0の正規化データに基づく`unorm_dart` 0.3.2で検証しています。依存関係
の更新によってfixtureの結果が変わる場合は、暗黙に動作を変えず、コントラクトを
明示的に再検討します。

## パフォーマンス上の境界

編集経路の計算には`O(お手本の書記素数 × 入力の書記素数)`の時間とメモリが
必要です。タイピング課題や短い文章を対象としているため、信頼できない長文を
評価する前にアプリケーション側で長さを制限してください。

## コントリビューションとライセンス

コントリビューション方法は[CONTRIBUTING.md](CONTRIBUTING.md)を参照してください。
まだ適合性テストに含まれていない文字体系のUnicode事例を特に歓迎します。

このプロジェクトは[BSD 3-Clauseライセンス](LICENSE)で提供されます。
