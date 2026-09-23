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

## 2026-09-23 — 환경 재현성: 전용 venv + Docker MySQL (Phase 0)

- Phase: 0
- 변경 파일: `requirements.txt`(신규), `schema.sql`(신규), `docker-compose.yml`(신규), `routers/gemini_router.py`(디버그 print 제거), `config.py`·`db.py`·`database.py`(이전 작업에서 이미 .env 전환, 이번에 새 venv에서 재검증)
- 내용:
  - 하드코딩된 비밀값을 `.env`로 옮기는 작업(직전 커밋)을 검증하는 과정에서, 로컬 conda 환경(`fastapi_env`, 다른 프로젝트와 공유 중)에 `sqlalchemy`, `mysql-connector-python` 등 핵심 패키지가 전혀 없어 백엔드가 이 컴퓨터에서 한 번도 정상 기동하지 못했던 상태였음을 확인.
  - 기존 `venv/`는 Windows용(`Lib`/`Scripts` 구조)이라 macOS에서 사용 불가 — 삭제 후 Homebrew Python 3.11로 macOS용 `venv/`를 새로 생성, 실제 import 가능한 패키지 전체를 설치하고 `pip freeze > requirements.txt`로 고정.
  - MySQL을 로컬에 직접 설치하지 않고 `docker-compose.yml`로 컨테이너화. 최초 기동 시 자동 실행되는 `schema.sql`도 함께 작성 (`users`/`trade_history`/`user_portfolio`/`Stocks`/`DailyPrice`). `users.balance`에 `DEFAULT 1000000.00`을 넣어 PROJECT_REVIEW.md 2.6(신규가입 balance NULL로 첫 매수 시 500 에러) 문제를 스키마 차원에서 같이 해결.
  - 검증 중 `routers/gemini_router.py`의 디버그용 `print("✅ GEMINI_API_KEY:", GEMINI_API_KEY)`가 `main.py` import 시점에 **실제 Gemini API 키 값을 출력**하는 것을 발견 → 해당 print문 제거. (이 키는 대화 로그에 한 번 노출되었으므로 재발급 권장)
  - `venv/` 전체와 `__pycache__/*.pyc`가 `.gitignore` 규칙에도 불구하고 이미 git에 커밋되어 추적되고 있던 것을 발견 (별도 승인 필요 항목으로 보고).
- 확인: `docker compose up`으로 MySQL 컨테이너 기동 → healthy 확인 → `database.get_connection()`으로 실제 접속 및 5개 테이블 생성 확인 → `uvicorn main:app` 기동 → `/signup`→`/login`→`/user/balance/1` curl로 엔드투엔드 테스트, 신규가입 유저 balance가 기본값 1000000으로 정상 반영됨을 확인.

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
