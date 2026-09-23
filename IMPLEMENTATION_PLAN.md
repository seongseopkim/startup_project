# ANT HOUSE 개선 실행 계획

작성일: 2026-09-18
전제: [PROJECT_REVIEW.md](./PROJECT_REVIEW.md)에서 찾은 문제들을 기반으로, 아래 3가지 목표를 달성하기 위한 단계별 계획.

## 목표

1. **다른 사람이 실행해도 깨지지 않는 앱** — 컴퓨터/계정이 달라도 클론 후 바로 뜨는 상태
2. **발표에서 보여줄 "보안/인증/값 신뢰" 개선 스토리** — Before(취약) → After(패치) 구조로 직접 시연 가능해야 함
3. **구글/카카오 소셜 로그인 연동** — 스토어 배포 없이, 로컬/테스트 기기에서 동작
4. **콘텐츠 보강** — 종목 뉴스 피드, 자산 요약 홈 대시보드 등을 추가해서 "모의 매매만 되는 앱"에서 "실제 서비스처럼 보이는 앱"으로 완성도를 높임

네 목표는 서로 겹칩니다. 특히 목표 2와 3은 목표 1(환경 재현성)이 먼저 되어 있어야 시연 중 사고가 안 납니다. 그래서 순서를 **환경 → 인증/신뢰 → 소셜 로그인 → 콘텐츠 보강 → 잔여 정리**로 잡았습니다. 이 문서는 졸업작품 제출을 전제로 하므로, "발표 때만 보여주는 임시 조치"가 아니라 실제로 계속 동작해야 하는 기준으로 각 단계를 작성합니다.

---

## Phase 0. 환경 재현성 먼저 끝내기 (발표 전 사고 방지용, 가장 먼저)

발표 당일 "다른 컴퓨터에서 시연했는데 안 됨" 이 나오면 안 되니 제일 먼저 처리합니다.

- [ ] 루트에 `requirements.txt` 커밋 (`pip freeze` 기준 정리, 안 쓰는 패키지는 제외)
- [ ] `schema.sql` 커밋 — `users`, `trade_history`, `user_portfolio`, `Stocks`, `DailyPrice` 테이블 생성문. `balance`에 `DEFAULT 1000000` 같은 초기 자본금 기본값 포함 (PROJECT_REVIEW.md 2.6 항목).
- [ ] 루트 `.env.example`, `flutter_app/assets/.env.example` 커밋 — 필요한 키 이름만 적어두고 값은 빈칸
- [ ] README에 "클론 후 셋업 순서" 5줄 정리 (venv 생성 → pip install -r requirements.txt → schema.sql 실행 → .env 채우기 → flutter pub get)
- [ ] (여유 있으면) `docker-compose.yml`로 FastAPI + MySQL 한 번에 띄우기 — 발표 때 "명령어 한 줄로 뜬다"를 직접 보여줄 수 있어서 시연 효과가 큼

이 단계는 코드 로직을 안 건드리므로 리스크가 낮습니다. 가장 먼저, 가장 빠르게 끝내는 걸 권장합니다.

---

## Phase 1. 인증을 "진짜로" 동작시키기

지금 문제: 로그인하면 JWT를 주긴 하는데, 그 뒤로 아무도 검사를 안 함 (PROJECT_REVIEW.md 1.2). 발표에서 "이걸 고쳤다"고 말하려면 최소한 아래 구조가 필요합니다.

### 백엔드
- [ ] `deps.py` 같은 공용 파일에 `get_current_user(token: str = Depends(oauth2_scheme))` 의존성 하나 작성. 내부에서 `jwt.decode`로 토큰을 검증하고, 유효하지 않으면 401.
- [ ] `SECRET_KEY`를 `utils/jwt_utils.py`의 하드코딩 값에서 `.env`로 이동 (`os.getenv("JWT_SECRET_KEY")`)
- [ ] `/order/buy`, `/order/sell`, `/user/balance/{user_id}`, `/trade_history/{user_id}` 전부 시그니처를 바꿔서 **`user_id`를 요청 바디/경로에서 받지 않고 토큰에서 꺼낸 값을 씀**. (`BuyRequest`/`SellRequest`에서 `user_id` 필드 자체를 제거)
- [ ] 매수/매도 시 클라이언트가 보낸 `trade_price`를 믿지 않고, 서버가 그 시점에 시세 API를 다시 호출해서 가격을 확정 (PROJECT_REVIEW.md 1.3). `quantity`는 `Field(gt=0)`로 서버에서도 검증 (1.4).

### 프론트
- [ ] `auth_service.dart`에 `http.Client` 래퍼(또는 인터셉터) 하나를 만들어서, 저장된 토큰을 모든 요청 헤더에 자동으로 `Authorization: Bearer ...`로 붙이기. 지금처럼 서비스 파일마다 각자 `http.post`/`http.get`을 부르는 구조를 하나의 공용 클라이언트로 모으면 이 작업이 한 번에 해결됨.
- [ ] `app.dart`의 `home`을 `LoginScreen`에서 `SplashScreen`으로 바꾸고, 토큰이 있으면 서버에 "내 정보" 요청을 한 번 보내서 `UserProvider.userId`를 복원 (지금은 토큰만 있고 userId 복원 로직이 없음 — PROJECT_REVIEW.md 4.5).

### 발표 포인트로 쓰기 좋은 시연
- **Before**: Postman/curl로 `POST /order/buy`에 임의의 `user_id`와 `trade_price: 0.01`을 넣어서 "다른 사람 계좌를 조작할 수 있었다"를 직접 보여줌.
- **After**: 같은 요청을 토큰 없이 보내면 401, 남의 토큰으로 남의 user_id를 조작해도 서버가 토큰 안의 user_id만 신뢰해서 무시됨, 가격도 서버가 재계산해서 임의 가격이 반영 안 됨.
- 이 Before/After 자체가 "내가 뭘 고민했는지" 설명하는 가장 직관적인 자료가 됩니다.

---

## Phase 2. 소셜 로그인 (구글 / 카카오) 연동

스토어에 안 올리는 전제이므로, **앱 자체는 로컬/디버그 빌드로 테스트 기기에 직접 설치**하는 걸 기준으로 잡습니다. 스토어 심사 없이도 아래 방식으로 정상 동작합니다.

### 왜 이 구조가 맞는지
소셜 로그인은 두 단계로 나눠야 합니다.
1. **클라이언트 ↔ 구글/카카오**: 사용자가 구글/카카오 로그인 창을 보고 로그인 → 클라이언트가 `id_token`(구글) 또는 `access_token`(카카오)을 받음
2. **클라이언트 ↔ 우리 백엔드**: 그 토큰을 우리 서버로 보내서, 서버가 구글/카카오에 "이 토큰 진짜냐"를 재확인한 뒤, 우리 서비스 전용 JWT를 새로 발급

**절대로 클라이언트가 "구글에서 로그인 성공했다"는 말만 믿고 바로 우리 서비스에 로그인시키면 안 됩니다.** (클라이언트는 조작 가능하므로) — 이게 발표에서 "값 신뢰" 파트와 바로 연결되는 지점입니다. Phase 1에서 "클라이언트가 보낸 값을 믿지 않는다"는 원칙을 소셜 로그인에도 그대로 적용하는 것.

### 구글 로그인
- [ ] Google Cloud Console에서 OAuth 클라이언트 생성 (Android: 패키지명 + 디버그 키 SHA-1 등록, iOS: Bundle ID 등록). **스토어 등록과 무관하게 가능** — OAuth 클라이언트 등록과 앱스토어 배포는 완전히 별개 절차임.
- [ ] Flutter: `google_sign_in` 패키지 추가 → 로그인 성공 시 `idToken` 획득
- [ ] 백엔드: `/auth/google` 엔드포인트 추가 → 받은 `idToken`을 Google의 토큰 검증 엔드포인트(`https://oauth2.googleapis.com/tokeninfo?id_token=...`) 또는 `google-auth` 라이브러리로 검증 → `email`이 `users` 테이블에 있으면 로그인, 없으면 자동 회원가입 → 우리 JWT 발급

### 카카오 로그인
- [ ] Kakao Developers에서 앱 생성, 네이티브 앱 키 발급, 플랫폼에 Android 패키지명+키해시 / iOS Bundle ID 등록 (역시 스토어 배포 불필요)
- [ ] Flutter: `kakao_flutter_sdk_user` 패키지 추가 → 로그인 성공 시 `accessToken` 획득
- [ ] 백엔드: `/auth/kakao` 엔드포인트 추가 → 받은 `accessToken`을 카카오 사용자 정보 API(`https://kapi.kakao.com/v2/user/me`)로 검증/조회 → 이메일/닉네임으로 로그인 또는 자동 회원가입 → 우리 JWT 발급

### 공통으로 필요한 변경
- [ ] `users` 테이블에 `provider`(local/google/kakao), `provider_id` 컬럼 추가 — 같은 이메일이라도 가입 경로를 구분
- [ ] 기존 `password` 컬럼은 소셜 로그인 유저에겐 NULL 허용
- [ ] 로그인 화면에 "구글로 계속하기" / "카카오로 계속하기" 버튼 추가, 기존 아이디/비밀번호 로그인과 병행

### 발표 포인트로 쓰기 좋은 부분
"소셜 로그인 자체"는 사실 SDK가 다 해주는 부분이라 발표에서 강조할 내용은 크지 않습니다. 대신 **"클라이언트가 준 토큰을 서버가 발급처에 재검증한다"**는 부분을 강조하면, Phase 1의 "클라이언트 값을 신뢰하지 않는다"는 원칙과 자연스럽게 이어지는 하나의 스토리가 됩니다.

---

## Phase 3. 남은 확실한 버그 정리 (발표와 무관하게 꼭 필요)

PROJECT_REVIEW.md에 있는 것 중 위 단계에서 자연히 안 고쳐지는 것들:

- [ ] `services/candle_service.py` INSERT 문 컬럼 목록 채우기 (2.1)
- [ ] `services/login.py` null 체크 순서 수정 + 디버그 print 제거 (2.2)
- [ ] `routers/trade_history.py` — BUY/SELL 구분 없이 수량을 더하는 로직 수정, 가능하면 `UserPortfolio` 테이블을 직접 읽는 구조로 교체 (2.3)
- [ ] `routers/gemini_router.py`의 `/ask-gemini` 응답 파싱 경로 수정 (지금 안 쓰이지만 나중에 쓸 수 있으니 수정) (2.4)
- [ ] `alpha_chart_screen.dart`의 `\${snapshot.error}` → `${snapshot.error}` (2.5)
- [ ] `db.py`/`database.py` 이중화 정리 → 하나로 통일, `get_db` 의존성 공용화 (4.1)
- [ ] 죽은 코드 삭제: `chart/`, `mock_investment_model.dart`, `stock_service.dart`, `services/finn.py`, `signup.dart`의 미사용 전역 컨트롤러 (4.2)
- [ ] API 주소 하드코딩 → `lib/config/api_config.dart`로 통일 (4.3)

이 단계는 발표 스토리와 직접 관련은 없지만, 시연 중 예상치 못한 크래시를 막기 위해 Phase 1~2와 병행해서 틈틈이 처리하는 걸 권장합니다.

---

## Phase 4. 콘텐츠 보강 — 종목 뉴스 피드 & 자산 요약 홈 대시보드

지금 앱은 "종목 검색 → 차트 → 모의 매수/매도"와 "투자 기록 조회"만 있어서 실제 서비스 느낌이 약합니다. 아래 두 기능을 추가합니다. 둘 다 기존 스택(Finnhub 키, `UserPortfolio` 테이블, `syncfusion_flutter_charts`)을 그대로 재사용할 수 있습니다.

### 4-A. 종목 뉴스 피드

**백엔드**
- [ ] `routers/stocks.py`에 `GET /stocks/{symbol}/news` 추가 (또는 `routers/news_router.py` 신설). Finnhub `company-news` 엔드포인트(`https://finnhub.io/api/v1/company-news?symbol={symbol}&from=...&to=...&token=...`)를 호출하는 프록시.
  - `from`/`to`는 서버에서 "오늘 기준 최근 14일"로 자동 계산 (클라이언트가 날짜를 보내게 하지 않음 — Phase 1의 "클라이언트 값을 함부로 신뢰하지 않는다" 원칙을 여기도 적용).
  - Finnhub 응답에서 `headline`, `source`, `url`, `datetime`, `image`, `summary`만 추려서 최신순 상위 10~15개만 반환 (원본 그대로 넘기면 불필요하게 큼).
  - `requests.get(..., timeout=5)` 로 타임아웃 지정 (PROJECT_REVIEW.md 5번 항목, 지금 백엔드 전체에 타임아웃이 없는 문제를 이 신규 코드부터는 피함).
  - `API_KEY`는 Phase 0에서 `.env`로 옮긴 것을 그대로 사용.
- [ ] Finnhub 무료 플랜 rate limit(분당 호출 수) 확인 — 화면 진입마다 호출되면 금방 소진되므로, 같은 심볼은 서버 메모리에 몇 분간 캐시(간단히 `dict` + timestamp)하는 것 권장.

**프론트**
- [ ] `flutter_app/lib/services/news_service.dart` 신설 — `fetchStockNews(symbol)` 함수, 백엔드 프록시만 호출 (Finnhub를 클라이언트가 직접 부르지 않음 → PROJECT_REVIEW.md 4.4에서 지적한 "클라이언트에 키 노출" 패턴을 신규 기능에서는 처음부터 피하는 것).
- [ ] `alpha_chart_screen.dart`의 차트 화면 하단(또는 별도 섹션)에 뉴스 카드 리스트 추가 — 헤드라인, 출처+날짜, 탭하면 원문 링크로 이동.
- [ ] 원문 링크 이동을 위해 `url_launcher` 패키지를 `pubspec.yaml`에 추가.
- [ ] 뉴스가 없거나 API 실패 시 "관련 뉴스가 없습니다" 같은 빈 상태 UI 처리.

### 4-B. 자산 요약 홈 대시보드

지금 `UserPortfolio`(보유 종목 현황) 테이블은 있지만, 이걸 조회하는 API가 없어서(매수/매도 서비스 내부에서만 씀) 새로 하나 만들어야 합니다. 이 작업은 PROJECT_REVIEW.md 2.3에서 지적한 "포트폴리오는 `UserPortfolio`를 정답으로 취급하자"는 방향과 맞아서, Phase 3의 `trade_history.py` 정리와 같이 진행하면 중복 작업이 줄어듭니다.

**백엔드**
- [ ] `services/finnhub_service.py` 또는 신규 `services/price_service.py`에 `get_current_price(symbol)`을 공용 함수로 분리 (지금 `routers/trade_history.py`에만 있는 걸 재사용 — 중복 제거).
- [ ] `GET /user/portfolio` 신설 (Phase 1 적용 후에는 토큰에서 `user_id`를 꺼내고, 그 전이라면 임시로 path/query의 `user_id` 사용) — `UserPortfolio` 테이블을 읽어서 `[{symbol, quantity, average_price, current_price, total_value}]` 형태로 반환.
- [ ] `GET /user/summary` 신설 — 현금 잔고(`User.balance`) + 위 포트폴리오 평가금액 합산 → `{cash, holdings_value, total_assets, total_return_pct}` 반환. `total_return_pct`는 "총 투입 대비 현재 총자산" 기준으로 계산(간단한 버전으로 시작, 일별 스냅샷 기반의 "오늘 변동률"은 이후 과제로 남김).

**프론트**
- [ ] `flutter_app/lib/features/home/home_dashboard_screen.dart` 신설.
- [ ] `MainScreen`의 `_pages`/`BottomNavBar`에 "홈" 탭을 맨 앞에 추가 (기존 주식 검색/투자기록/용어사전 탭 유지, 탭 4개로 확장).
- [ ] 화면 구성: 총자산 큰 숫자 카드 → 현금/평가금액 구성 표시 → 보유 종목 요약 리스트(상위 몇 개, "전체보기"로 `CheckScreen` 이동) → 수익률 배지.
- [ ] `/user/summary`, `/user/portfolio` 두 API를 호출해서 구성.

### 순서상 주의점
- 4-B(자산 대시보드)는 Phase 3의 포트폴리오/트레이드 히스토리 정리, Phase 1의 인증(진짜 `user_id` 확보)과 맞물려 있어서, **Phase 1 이후에 진행하는 게 자연스럽습니다.** (먼저 만들어도 동작은 하지만, 나중에 `user_id` 전달 방식을 인증 토큰 기반으로 다시 고쳐야 함)
- 4-A(뉴스 피드)는 인증과 무관하므로 **언제든 먼저 시작해도 무방**합니다.

---

## 발표 구성 제안 (참고용)

1. **문제 제기**: "모의투자 앱을 만들면서, 처음엔 기능 구현에 집중했더니 이런 보안 구멍들이 있었다" — PROJECT_REVIEW.md의 1.2/1.3/1.4를 캡처+curl 명령으로 재현
2. **원인 분석**: 클라이언트가 보낸 값을 서버가 그대로 신뢰한 것이 공통 원인이라는 걸 짚기 (user_id, trade_price, quantity 전부 같은 패턴)
3. **해결**: 토큰 기반 인증 + 서버 측 가격/수량 재검증 구조로 전환 (Before/After 데모)
4. **확장**: 같은 원칙을 소셜 로그인에도 적용 (구글/카카오 토큰을 서버가 재검증) — "신뢰 경계를 서버로 옮긴다"는 하나의 일관된 원칙으로 마무리
5. **회고**: 환경 재현성(Phase 0), 죽은 코드 정리 등 배운 점 짧게 언급

---

## 진행 순서 요약

| Phase | 내용 | 발표와의 관계 |
|---|---|---|
| 0 | requirements.txt, schema.sql, .env.example | 시연 사고 방지 (필수 선행) |
| 1 | JWT 실제 검증, 서버 측 가격/수량 검증 | 발표의 핵심 Before/After |
| 2 | 구글/카카오 로그인 + 서버 재검증 | 발표의 확장 사례 |
| 3 | 나머지 버그/죽은 코드 정리 | 병행 진행, 안정성 확보 |
| 4 | 종목 뉴스 피드, 자산 요약 홈 대시보드 | 완성도/콘텐츠 보강 (4-A는 언제든, 4-B는 Phase 1 이후 권장) |

> 추가로 채택할 기능(리더보드, 통계 대시보드, 실시간 시세, 주문 유형 다양화, 테스트/CI 등)은 논의 후 이 표와 Phase 4 아래에 계속 추가합니다.
