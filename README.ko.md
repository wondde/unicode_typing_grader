# unicode_typing_grader

[English](README.md) | 한국어 | [日本語](README.ja.md)

Dart를 위한 Unicode 기반 타이핑 채점기입니다. 기준 문장과 사용자가 입력한
문장을 눈에 보이는 글자 단위로 비교하고, 결정적인 편집 내역과 정확도, 분당
입력 글자 수(CPM)를 계산합니다.

엔진은 특정 언어에 종속되지 않습니다. 공식 검증 사례에는 한글, 일본어 가나,
라틴 결합 문자, 제로 폭 결합자로 이어진 이모지가 포함되어 있습니다.

![한국어 학습 문장을 입력한 뒤 정확도, 속도, grapheme 단위 오타 하나를 채점하는 예제](doc/assets/typing-grader-demo-ko.gif)

## 언제 사용할 수 있나요?

서비스가 사용자에게 기준 문장을 보여주고, 사용자가 입력한 결과를 평가해야 할 때
사용할 수 있습니다. 예를 들면 다음과 같습니다.

- 어떤 글자가 달랐는지 알려주는 외국어 학습 앱
- 정확도와 실제 입력 중이던 시간의 속도를 측정하는 필사 연습
- 한글, 일본어 가나, 결합 문자, 이모지를 UTF-16 단위가 아니라 사람이 보는 글자
  단위로 처리해야 하는 타자 평가

맞춤법 검사기나 자동 완성 서비스는 아닙니다. 문제 문장, 입력창, 타이머의 시작과
중지, 결과 UI는 애플리케이션이 담당합니다. 이 패키지는 최종 기준 문장, 입력,
정책, 활성 입력 시간을 받아 어디서 실행해도 재현할 수 있는 채점 결과를 만듭니다.

위 애니메이션은 실제 `gradeTyping` API를 호출하는
[브라우저 예제](example/web)에서 만들었습니다.

## 주요 기능

- 비교 전 NFC 정규화
- UTF-16 코드 유닛이 아닌 확장 grapheme cluster 단위 비교
- 항상 같은 결과를 내는 삽입·삭제·치환 경로
- 공백 유지, 양끝 제거, 연속 공백 축약 정책
- 문장 끝 문장부호 유지 또는 무시 정책
- 정수로 저장할 수 있는 정확도와 CPM
- 단조 시간원을 사용하는 활성 입력 타이머
- 버전이 지정된 언어 중립적 JSON 검증 fixture
- Flutter에 의존하지 않는 순수 Dart 패키지

## 설치

첫 개발 버전은 아직 pub.dev에 게시하지 않았습니다. 공개 API를 검증하는 동안
Git 저장소를 의존성으로 사용합니다.

```yaml
dependencies:
  unicode_typing_grader:
    git:
      url: https://github.com/wondde/unicode_typing_grader.git
      ref: main
```

프로덕션에서는 `main` 대신 릴리스 태그나 커밋을 고정하는 것을 권장합니다.

## 사용법

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

정규화했을 때 같은 일본어 가나도 동일한 글자로 판단합니다.

```dart
final comparison = compareNormalizedGraphemes(
  reference: 'が',
  input: 'か\u3099',
);

print(comparison.editDistance); // 0
```

## 비교 정책

`TypingGradingPolicy`는 직렬화할 수 있습니다. 따라서 클라이언트와 서버가 같은
규칙으로 채점할 수 있습니다.

| 구분 | 값 | 동작 |
| --- | --- | --- |
| 공백 | `exact` | 모든 공백을 그대로 비교합니다. |
| 공백 | `trim` | 양끝의 v1 Unicode 공백을 제거합니다. |
| 공백 | `collapse` | 양끝 공백을 제거하고 연속 공백을 ASCII 공백 하나로 바꿉니다. |
| 문장부호 | `exact` | 문장부호를 그대로 비교합니다. |
| 문장부호 | `ignoreTerminal` | 끝의 `.`, `!`, `?`, `。`, `！`, `？` 중 하나를 제거합니다. |

모든 v1 정책은 위 규칙을 적용하기 전에 문장을 NFC로 정규화합니다.

## 지표 정의

정확도는 기준 문장과 입력 문장 중 더 긴 grapheme 수를 분모로 사용합니다.

```text
accuracy = max(0, max(reference, input) - editDistance)
           / max(reference, input)
```

`accuracyPermille`은 정확도 비율을 `0`부터 `1000`까지의 정수로 저장합니다.
`charactersPerMinuteThousandths`는 입력 CPM에 `1000`을 곱한 정수입니다. 정수
표현을 사용하므로 저장소와 서로 다른 프로그래밍 언어에서 같은 결과를
재현하기 쉽습니다.

## 검증 계약

[`conformance/v1/fixtures.json`](conformance/v1/fixtures.json)은 애매한 편집 경로의
우선순위를 포함한 v1 동작을 정의합니다. 다른 언어로 구현한 채점기도 이
fixture를 실행하여 Dart 패키지와 결과가 같은지 확인할 수 있습니다. 자세한
내용은 [검증 가이드](conformance/README.md)를 참고하세요.

첫 계약은 Unicode 16.0 grapheme 분할에 기반한 `characters` 1.4.1과 Unicode
17.0 정규화 데이터에 기반한 `unorm_dart` 0.3.2로 검증했습니다. 의존성
업데이트로 fixture 결과가 달라진다면 조용히 동작을 바꾸지 않고 계약을 다시
검토해야 합니다.

## 성능 경계

편집 경로 계산에는 `O(기준 grapheme 수 × 입력 grapheme 수)`의 시간과 메모리가
필요합니다. 타이핑 문제와 짧은 문장을 위한 알고리즘이므로, 신뢰할 수 없는 긴
입력을 채점하기 전에 애플리케이션에서 길이를 제한해야 합니다.

## 기여 및 라이선스

기여 방법은 [CONTRIBUTING.md](CONTRIBUTING.md)를 참고하세요. 아직 검증 사례에
없는 문자 체계의 Unicode 예제를 특히 환영합니다.

이 프로젝트는 [BSD 3-Clause 라이선스](LICENSE)로 배포됩니다.
