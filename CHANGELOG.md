# 변경 이력 (CHANGELOG)

이 문서는 [IMPLEMENTATION_PLAN.md](./IMPLEMENTATION_PLAN.md)에 따라 **실제로 적용된 변경사항**을 시간순으로 기록합니다.
계획(할 일)은 IMPLEMENTATION_PLAN.md, 발견된 문제 원본은 [PROJECT_REVIEW.md](./PROJECT_REVIEW.md)를 참고하세요.
이 문서는 "무엇을 왜 고쳤는지"만 남기고, 세부 코드 설명은 커밋/diff를 보면 되므로 짧게 적습니다.

## 기록 형식

```
## YYYY-MM-DD — 작업 제목
- Phase: (IMPLEMENTATION_PLAN.md의 Phase 번호)
- 변경 파일: 경로 목록
- 내용: 뭘 왜 바꿨는지 1~3줄
- 확인: 어떻게 검증했는지 (직접 실행/테스트/시연 등)
```

졸업작품 제출 시 "무엇을 스스로 고민하고 고쳤는지"를 설명하는 자료로도 그대로 쓸 수 있게, 문제 → 원인 → 조치 순서로 적습니다.

---

## 2026-09-18 — 점검 및 계획 수립 (사전 작업)

- Phase: 0 (착수 전)
- 변경 파일: `PROJECT_REVIEW.md`(신규), `IMPLEMENTATION_PLAN.md`(신규), `flutter_app/pubspec.lock`(복구), `flutter_app/ios/Podfile`·`flutter_app/macos/Podfile`(신규, pub get 산물), `flutter_app/ios/Flutter/*.xcconfig`·`flutter_app/macos/Flutter/*.xcconfig`(pub get 산물)
- 내용:
  - 컴퓨터를 옮긴 뒤 Flutter가 패키지를 인식하지 못하던 문제의 원인이 `pubspec.lock` 안 `flutter_dotenv` 항목의 들여쓰기 오류였음을 확인하고 수정, `flutter pub get` 정상화.
  - 백엔드/프론트 전체를 훑어서 보안(인증 미검증, 가격·수량 클라이언트 신뢰), 로직 버그(로그인 null체크 순서, candle INSERT 문법 오류, 신규가입 balance NULL, trade_history 집계 오류 등), 환경 이식성(requirements.txt/스키마/.env 부재) 문제를 정리 → `PROJECT_REVIEW.md`.
  - 위 문제를 해결하는 순서(Phase 0~3: 환경 재현성 → 인증/신뢰 → 소셜 로그인 → 잔여 버그)를 `IMPLEMENTATION_PLAN.md`로 정리.
- 확인: 문서 작성 단계, 코드 로직은 아직 수정 안 함 (pubspec.lock 복구만 실제 동작 변경).

---

<!-- 새 작업은 이 줄 아래에 최신 항목이 위로 오도록 추가하세요 -->
