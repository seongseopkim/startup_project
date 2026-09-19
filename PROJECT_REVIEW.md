# ANT HOUSE 프로젝트 점검 보고서

작성일: 2026-09-18
범위: `flutter_app/` (Flutter 클라이언트) + 루트의 FastAPI 백엔드(`main.py`, `routers/`, `services/`, `utils/`, `model.py`, `schemas.py`, `db.py`, `database.py`, `config.py`)

> 이 문서는 **분석/기록용**입니다. 아직 아무 것도 수정하지 않았습니다. 항목마다 파일:라인을 표시했으니, 우선순위를 정해서 하나씩 고쳐나가면 됩니다.

---

## 0. 오늘 이미 고친 것 (참고용, 원인 규명 완료)

- `flutter_app/pubspec.lock`의 `flutter_dotenv` 항목 들여쓰기가 깨져 있어 `flutter pub get`이 파싱 오류로 실패 → `.dart_tool`이 한 번도 생성되지 않아 `flutter/material.dart`, `syncfusion_flutter_charts` 등을 전부 인식하지 못했던 것. 들여쓰기 수정 후 `pub get` 성공시켰음.
- 이건 "새 컴퓨터라서 안 됨"이 아니라 **lock 파일 자체가 손상되어 있던 것**이었음. 아래 4번 항목(환경 이식성)도 같은 계열의 문제라서 꼭 같이 봐야 함.

---

## 1. 🔴 보안 — 지금 당장 심각한 문제

### 1.1 하드코딩된 API 키/토큰이 git 히스토리에 그대로 커밋되어 있음
- `config.py:1` — Finnhub API 키 평문
- `db.py:6`, `database.py:5,18,33` — MySQL `root` 계정 비밀번호가 평문으로 박혀 있음(값은 이 문서에는 적지 않음), 두 곳에 중복
- `services/finn.py:70` — Finnhub 웹소켓 토큰이 URL에 평문으로 박혀 있음
- `flutter_app/lib/services/stock_service.dart` (주석 처리된 죽은 코드) 안에도 또 다른 Finnhub 토큰이 노출되어 있음
- `git log`로 확인 결과 이 파일들은 **최초 커밋부터 추적**되고 있어서, 지금 파일을 고쳐도 git 히스토리에는 키가 영구히 남음.
- **조치 필요**: 노출된 키/비밀번호는 전부 재발급/변경, `.env` + `python-dotenv`로 이동, 이미 커밋된 히스토리는 `git filter-repo` 등으로 정리하거나 최소한 재발급으로 무력화.

### 1.2 로그인 후 발급되는 JWT가 어디에서도 검증되지 않음
- `utils/jwt_utils.py`에서 토큰을 발급(`create_access_token`)하지만, 백엔드 전체에서 `jwt.decode`나 인증 의존성(`Depends`)을 쓰는 코드가 **한 곳도 없음** (grep 결과 0건).
- `flutter_app/lib/services/auth_service.dart:23-30`에서 토큰을 `SharedPreferences`에 저장은 하지만, `getToken()`은 앱 전체에서 **호출되는 곳이 없음** (다른 모든 API 호출에 `Authorization` 헤더가 붙지 않음).
- 결과적으로 `/user/balance/{user_id}`, `/order/buy`, `/order/sell`, `/trade_history/{user_id}` 전부 **user_id만 알면 누구나 남의 계좌를 조회/거래**할 수 있음 (IDOR).
- **조치 필요**: FastAPI `Depends`로 토큰 검증 의존성을 만들고, 모든 라우터에서 `user_id`를 요청 바디가 아니라 토큰에서 꺼내 쓰도록 변경.

### 1.3 매수/매도 가격을 클라이언트가 그대로 결정함 (자금 조작 가능)
- `schemas.py:4-16` — `BuyRequest`/`SellRequest`에 `trade_price`, `trade_date`를 클라이언트가 직접 보냄
- `services/buy_service.py:9`, `services/sell_service.py:11` — 서버는 이 값을 그대로 신뢰해서 잔고를 계산함. 실제 시세와 대조하는 코드가 없음.
- `flutter_app/lib/features/alpha/alpha_chart_screen.dart:204,209-216` / `flutter_app/lib/controllers/sell_stock.dart:14,20-31` — 클라이언트가 `latestPrice`(마지막으로 받아온 차트 종가)를 그대로 `trade_price`로 실어 보냄.
- 즉 API를 직접 호출(Postman 등)하면 `trade_price: 0.01` 같은 값으로 원하는 만큼 주식을 살 수 있음.
- **조치 필요**: 서버가 주문 시점에 실제 시세를 다시 조회해서 가격을 확정하고, `trade_date`도 서버 시간(`datetime.utcnow()`)으로 기록.

### 1.4 수량(quantity)에 대한 양수 검증이 없음
- `schemas.py`의 `quantity: int`에 `gt=0` 같은 제약이 전혀 없음.
- `services/buy_service.py:9-18` — `quantity`가 음수면 `total_cost`가 음수가 되어 `user.balance -= total_cost`가 오히려 **잔고를 늘려줌** (사실상 돈 복제).
- `services/sell_service.py`도 동일한 패턴으로 음수 수량 시 포트폴리오/잔고가 뒤틀림.
- 클라이언트 쪽(`_buyStock`, `sellstock`)에는 `qty <= 0` 체크가 있지만 이건 **서버가 아니라 클라이언트만 막고 있는 것**이라 우회 가능.
- **조치 필요**: Pydantic `Field(gt=0)`로 서버에서 강제, 서비스 로직에서도 재검증.

---

## 2. 🔴 확실한 런타임/로직 버그

### 2.1 `services/candle_service.py:24-36` — INSERT 문 컬럼 목록이 비어있음
```python
cursor.execute("""
    INSERT IGNORE INTO DailyPrice ()
    VALUES (%s, %s, %s, %s, %s, %s, %s)
""", (...))
```
컬럼 목록 `()`이 비어 있는데 값은 7개를 바인딩하려고 함 → SQL 문법 오류로 무조건 실패. **이 함수(`/load_candles/{symbol}`)는 지금 한 번도 정상 동작한 적이 없을 가능성이 높음.** 컬럼명을 채워야 함.

### 2.2 `services/login.py:14-22` — null 체크 순서가 뒤바뀜
```python
user = cursor.fetchone()
print("비교 결과:", bcrypt.checkpw(password.encode(), user["password"].encode()))  # ← 여기서 먼저 실행됨
if not user:
    raise HTTPException(...)
```
존재하지 않는 아이디로 로그인하면 `user`가 `None`이라 `user["password"]`에서 `TypeError`가 나서 500 에러가 됨 (의도한 404가 아님). `if not user` 체크를 **먼저** 해야 함. 또한 디버그용 `print`로 비밀번호 일치 여부를 서버 로그에 남기는 것도 제거 필요.

### 2.3 `routers/trade_history.py:33-45` — 매도(SELL) 거래를 매수처럼 더해버림
```python
portfolio[symbol]["quantity"] += qty
portfolio[symbol]["total_cost"] += price * qty
```
`trade.trade_type`(BUY/SELL)을 전혀 확인하지 않고 수량/금액을 무조건 더함. 사용자가 매도를 한 번이라도 하면 이 엔드포인트가 계산하는 평균 매입가·보유 수량이 실제와 달라짐. 이미 정확한 보유 현황을 담고 있는 `UserPortfolio` 테이블이 있는데, 이 API는 그걸 쓰지 않고 `trade_history`에서 다시(그것도 잘못) 계산하고 있음 — 로직이 중복이면서도 틀림.
→ 이 결과가 `flutter_app/lib/features/check/check_screen.dart`의 수익률(ROI) 계산에 그대로 들어가서, **매도 이력이 있는 계정은 수익률이 항상 틀리게 표시됨.**

### 2.4 `routers/gemini_router.py:33` — `/ask-gemini`만 응답 파싱 경로가 다름
다른 3개 엔드포인트(`trade-feedback`, `gemini/advice`, `gemini/term-explanation`)는 `res_json['candidates'][0]['content']['parts'][0]['text']`로 파싱하는데, `/ask-gemini`만 `res_json['candidates'][0]['parts'][0]['text']`로 `content`가 빠져 있음 → 호출하면 `KeyError`. 다행히 지금 Flutter 쪽에서 이 엔드포인트를 호출하는 곳은 없어서(죽은 엔드포인트) 아직 드러나지 않았을 뿐.

### 2.5 `flutter_app/lib/features/alpha/alpha_chart_screen.dart:110` — 에러 메시지가 문자열로 안 보이고 그대로 출력됨
```dart
return Center(child: Text('에러: \${snapshot.error}'));
```
`\$`로 escape 처리를 해버려서 실제 에러 내용이 보간되지 않고 `에러: ${snapshot.error}`라는 글자 그대로 화면에 찍힘. `\$` → `$`로 수정 필요.

### 2.6 신규 가입 유저의 `balance` 초기값이 없음
- `model.py:20` — `balance = Column(DECIMAL(15, 2))`에 `default`가 없음
- `services/signup.py:17` — INSERT 문에도 `balance` 컬럼을 넣지 않음
- DB 컬럼 자체에 `DEFAULT` 제약이 걸려 있지 않다면(레포에 스키마 DDL이 없어서 확인 불가 — 3번 항목 참고), 신규 유저의 `balance`는 `NULL`이 됨 → 첫 매수 시도에서 `services/buy_service.py:15`의 `user.balance < total_cost` 비교가 `None < Decimal`이 되어 `TypeError`로 500 에러.
- **조치 필요**: 회원가입 시 `balance`에 초기 자본금을 명시적으로 넣거나 DB 컬럼에 `server_default`를 설정.

---

## 3. 🟠 환경/이식성 문제 ("컴퓨터를 바꾸면 깨지는" 근본 원인들)

이번에 겪은 문제(`pub get` 실패)와 같은 계열입니다. 지금 안 보인다고 해서 안전한 게 아니라, **다음에 또 다른 컴퓨터·다른 사람이 클론했을 때 반드시 다시 터질 항목들**입니다.

### 3.1 백엔드에 의존성 목록이 전혀 없음
- 루트에 `requirements.txt` / `pyproject.toml` / `Pipfile`이 하나도 없음. `venv/` 자체가 git에는 안 잡히니(정상), 새 컴퓨터에서는 `fastapi`, `sqlalchemy`, `mysql-connector-python`, `bcrypt`, `python-jose`, `yfinance`, `pandas` 등 수십 개 패키지를 **뭘 설치해야 하는지 알 방법이 없음**.
- **조치 필요**: `pip freeze > requirements.txt` (지금 venv 기준으로) 또는 `pyproject.toml` 작성.

### 3.2 DB 스키마가 코드/버전관리 어디에도 없음
- `users`, `trade_history`, `user_portfolio`, `Stocks`, `DailyPrice`, `finnhub` 테이블을 만드는 `CREATE TABLE`/마이그레이션 파일이 레포에 전혀 없음. 지금 로컬 MySQL에만 존재하는 상태로 추정됨.
- 컴퓨터를 바꾸거나 다른 사람이 세팅하면 DB가 통째로 비어 있어서 모든 API가 실패함.
- **조치 필요**: 최소한 `schema.sql` 하나라도 커밋. 가능하면 Alembic 같은 마이그레이션 도구 도입.

### 3.3 Flutter 클라이언트가 필수로 요구하는 `.env` 에셋 파일이 저장소에 없음
- `flutter_app/pubspec.yaml`의 `flutter.assets`에 `assets/.env`가 선언되어 있는데, `flutter_app/assets/` 디렉터리 자체가 존재하지 않음 (`.gitignore`가 `.env`를 정상적으로 제외하고 있어서 커밋 안 된 것).
- `flutter_app/lib/main.dart:9`에서 `await dotenv.load()`를 앱 시작 시 무조건 호출 → 이 파일이 없으면 **앱이 시작 자체를 못 하고 크래시**함.
- 지금까지는 예전 컴퓨터에 이 파일이 로컬로만 남아 있어서 안 터진 것으로 보임. `flutter_app/lib/services/alpha_service.dart:7`을 보면 필요한 키는 `TWELVEDATA_API_KEY` 하나.
- **조치 필요**: `flutter_app/assets/.env.example` 같은 템플릿 파일을 커밋해두고, README에 "복사해서 `.env`로 이름 바꾸고 키 채우세요" 안내 추가.

### 3.4 백엔드도 `.env`가 필요한데 예시 파일이 없음
- `routers/gemini_router.py:9,13`, `routers/trade_history.py:13`이 `GEMINI_API_KEY`, `TWELVEDATA_API_KEY`를 환경변수로 기대하는데, `.env.example` 같은 안내 파일이 없어서 새 환경에서 어떤 키가 몇 개 필요한지 알 방법이 없음.

### 3.5 DB 접속 정보가 하드코딩 + 이중화되어 있어 환경별로 다르게 설정할 수 없음
- `db.py:6`, `database.py:5,16-19,30-34`에 호스트/계정/비밀번호가 코드에 박혀 있어서, 다른 컴퓨터/다른 DB 비밀번호를 쓰려면 코드를 직접 고쳐야 함. (아래 4.1 중복 문제와도 연결됨)

---

## 4. 🟡 구조적 문제 / 중복

### 4.1 DB 연결 모듈이 두 개로 쪼개져 있고 서로 다른 드라이버를 씀
- `db.py` — `sqlalchemy` + `mysql+mysqlconnector` 드라이버, `trade_history.py`만 이걸 씀
- `database.py` — `sqlalchemy` + `mysql+pymysql` 드라이버(별개의 `SessionLocal`/엔진) **그리고** 순수 `mysql.connector`로 raw 커넥션을 만드는 `get_connection()`까지 같은 파일에 있음. `user_router.py`, `buy_router.py`, `sell_router.py`, `services/*.py`가 이걸 씀.
- 결과적으로 **동일 DB에 대해 엔진이 2개, 접속 방식이 3가지(SQLAlchemy×2 dialect + raw connector)** 존재. 커넥션 풀도 따로 관리되고, 트랜잭션/오토커밋 동작이 미묘하게 다를 수 있음.
- 라우터마다 `get_db()` 의존성 함수도 3번 복붙되어 있음(`buy_router.py`, `sell_router.py`, `user_router.py`).
- **조치 필요**: `database.py` 하나로 통일하고, `get_db` 의존성은 공용 모듈(예: `deps.py`)에서 한 번만 정의.

### 4.2 죽은 코드 / 사용되지 않는 파일
- `flutter_app/lib/features/chart/` (chart_model.dart, stock_chart_screen.dart, stock_chart_widget.dart) — 어디서도 import 안 됨. `alpha/` 기능으로 대체된 것으로 보임.
- `flutter_app/lib/features/mock_investment/mock_investment_model.dart` — 어디서도 사용 안 됨.
- `flutter_app/lib/services/stock_service.dart` — 내용 전체가 주석 처리된 죽은 코드 + 그 안에 API 토큰 노출까지 있음.
- `flutter_app/lib/services/signup.dart:5-7` — 파일 최상단에 전역 `TextEditingController` 3개를 만들어두는데 아무 데서도 참조 안 됨(실제 화면은 자기 로컬 컨트롤러를 씀). dispose도 안 됨.
- `services/finn.py` — Finnhub 웹소켓으로 실시간 시세를 DB에 쌓는 스크립트인데, `main.py`나 어떤 라우터에서도 실행되지 않음. 완전히 고립된 스크립트.
- `utils/serializer.py`의 `serialize_item` — 어디서도 호출 안 됨.
- `routers/user_router.py:5` — `import routers` (자기 자신 패키지 import, 미사용).
- **조치 필요**: 실제로 안 쓰는 게 맞다면 삭제, 나중에 쓸 계획이면 이 문서에 "보류 중" 표시만 남기고 브랜치 분리 권장.

### 4.3 클라이언트 서버 주소가 전부 하드코딩된 `http://127.0.0.1:3050`
- `auth_service.dart`, `signup.dart`, `buy_service.dart`, `sell_stock.dart`, `user_service.dart`, `check_service.dart`, `gemini_service.dart`, `gemini_dictionary_screen.dart`, `exchange.dart` 등 거의 모든 서비스 파일에 로컬호스트 주소가 각자 따로 박혀 있음.
- 실제 기기(에뮬레이터 아닌 폰)에서 테스트하거나, 배포용 서버로 옮기는 순간 전부 고쳐야 함. 포트를 바꾸려 해도 8곳 이상을 손봐야 함.
- **조치 필요**: `ApiConfig.baseUrl` 같은 상수 하나로 통일하고, `--dart-define` 또는 `.env`로 환경별 주소 주입.

### 4.4 서드파티 API 키가 클라이언트 바이너리에 그대로 들어감
- `TWELVEDATA_API_KEY`가 Flutter 앱의 `.env` 에셋에 번들되어 배포됨(`alpha_service.dart:7`) → 앱을 디컴파일/압축 해제하면 누구나 키를 추출해서 자기 용도로 쓸 수 있음(요금/쿼터 도용).
- **조치 필요**: 시세 조회를 백엔드가 대신 호출하는 프록시 엔드포인트로 옮기고, 클라이언트는 자체 백엔드만 호출하게 변경.

### 4.5 세션 유지(로그인 상태 복원) 로직이 절반만 구현됨
- `flutter_app/lib/features/auth/splash_screen.dart`가 `AuthService.isLoggedIn()`을 확인해서 로그인 여부에 따라 분기하는 로직을 갖고 있지만, `app.dart:16`에서 앱의 `home`이 `SplashScreen`이 아니라 **`LoginScreen`으로 고정**되어 있어서 이 스플래시 화면 자체가 호출되지 않음.
- 설령 연결하더라도, 로그인 상태만 확인할 뿐 `UserProvider.userId`를 복원하는 코드가 없어서 토큰이 있어도 `userId`가 `null`인 채로 `MainScreen`에 진입하게 됨(여러 화면에서 `userId!`로 강제 언랩하고 있어서 크래시 위험).
- **조치 필요**: `app.dart`의 `home`을 `SplashScreen`으로 바꾸고, 토큰이 있으면 `/user/me` 같은 엔드포인트로 `userId`까지 복원하는 로직 추가.

---

## 5. 🟢 사소한 것들 (일관성/스타일)

- `services/buy_service.py:3`, `services/sell_service.py:4` — `from requests import Session` (HTTP 클라이언트 라이브러리 `requests`의 `Session`을 타입힌트로 씀). 원래 의도는 `sqlalchemy.orm.Session`. 타입힌트라 런타임 에러는 안 나지만 정적 분석기가 완전히 잘못된 타입으로 인식하고, 읽는 사람도 헷갈림.
- `Decimal(order.trade_price)` (`buy_service.py:9`, `sell_service.py:11`) — `trade_price`가 `float`이라 `Decimal(float)`을 쓰면 부동소수점 오차가 그대로 들어감(`Decimal(str(order.trade_price))`를 쓰는 게 안전).
- `routers/trade_history.py:5,21` — `import yfinance as yf`를 해두고 실제로는 TwelveData REST API를 씀. 미사용 import + 주석("야후 파이낸스")도 실제 동작과 다름.
- `routers/trade_history.py:22` — 외부 API 실패 시 조용히 `100.0`을 기본 시세로 반환 → 실패를 숨겨서 포트폴리오 평가금액이 사용자 모르게 틀리게 표시될 수 있음. 최소한 로그 레벨을 올리거나 응답에 "가격 조회 실패" 표시 필요.
- 백엔드 어디에도 외부 HTTP 호출(`requests.get/post`)에 `timeout=`이 지정되어 있지 않음(`stock_api.py`, `candle_service.py`, `finnhub_service.py`, `gemini_router.py`, `trade_history.py`). 외부 서비스가 응답을 안 주면 요청이 무한 대기.
- `flutter_app/lib/services/check_service.dart:10`은 `response.body`를 바로 쓰는데, 다른 서비스들은 한글 깨짐 방지로 `utf8.decode(response.bodyBytes)`를 씀 — 백엔드가 charset을 명시하지 않는 엔드포인트에서는 한글이 깨질 수 있어 일관성 필요.
- `flutter_app/lib/features/alpha/alpha_chart_screen.dart`와 `controllers/sell_stock.dart`에서 거래 `type` 값이 각각 `'buy'`(소문자)/`'SELL'`(대문자)로 대소문자가 섞여 있음. 지금은 `.lower()` 비교라 안 터지지만 통일 권장.
- `login.py`, `buy_router.py`, `gemini_router.py` 등 여러 곳에 디버깅용 `print`가 많이 남아있음(`print("로그인시도중중")` 등). 운영 전 `logging` 모듈로 정리 권장.
- 여러 async 함수(`_loadCashFromServer`, `_buyStock` 등)가 `await` 이후 `mounted` 체크 없이 `setState`/`context` 사용 — 화면 전환 타이밍에 경고/크래시 가능성.

---

## 6. 제안하는 새로운 방향

지금 구조는 "일단 되게 만들기" 단계의 프로토타입이고, 위 문제들 대부분은 **한 사람이 기능을 빠르게 추가하면서 서버 검증을 생략하고 클라이언트를 신뢰**한 데서 나옵니다. 다음 방향을 검토해볼 만합니다.

1. **인증을 실제로 동작하게 만들기 (최우선)**
   FastAPI에 `Depends(get_current_user)` 하나를 만들고, `Authorization: Bearer` 헤더에서 JWT를 검증해서 `user_id`를 꺼내는 방식으로 전환. 클라이언트가 body/path에 `user_id`를 실어 보내는 지금 방식은 전부 없애야 함. 이건 보안뿐 아니라 "누가 로그인했는지"를 서버가 아는 유일한 방법이 되므로, 3.5/4.5의 세션 문제도 같이 해결됨.

2. **거래(매수/매도)는 "서버가 가격을 결정"하는 구조로 전환**
   현재는 클라이언트가 본 시세를 그대로 신뢰하는데, 모의투자 앱이라도 이 구조는 나중에 실거래로 확장하기 어렵고 지금도 버그(2.6, 1.3, 1.4)의 근원임. 주문 요청 시 `{symbol, quantity, side}`만 받고, 서버가 그 순간 시세를 조회해서 가격/총액을 계산 → 이렇게 하면 `trade_price`/`trade_date`를 클라이언트가 보낼 필요가 없어지고 스키마도 단순해짐.

3. **포트폴리오 조회는 `UserPortfolio` 테이블 하나만 정답으로 취급**
   지금 `check_screen`/`trade_history.py`는 `trade_history`를 다시 집계해서 보유 현황을 만드는데, 이미 매수/매도 시점에 정확하게 갱신되는 `UserPortfolio`가 있음. `trade_history` 라우터는 "거래 내역 리스트"만 반환하고, 보유 현황/평균가는 `UserPortfolio` 테이블에서 바로 읽어오는 걸로 역할을 나누는 게 버그도 줄고 이해하기도 쉬움.

4. **환경 재현성 확보 (오늘 문제의 재발 방지)**
   - `requirements.txt`(또는 `pyproject.toml`) 커밋
   - `schema.sql` 또는 Alembic 마이그레이션 커밋
   - `flutter_app/assets/.env.example`, 루트 `.env.example` 커밋
   - 가능하면 백엔드는 `docker-compose.yml`로 FastAPI + MySQL을 묶어서, "컴퓨터가 바뀌어도 `docker compose up` 한 줄이면 되는" 상태를 목표로 하는 것을 권장. 지금처럼 로컬 MySQL을 손으로 깔고 스키마도 손으로 만드는 방식은 이번처럼 컴퓨터를 바꿀 때마다 반복적으로 문제를 만듦.

5. **서드파티 키는 전부 백엔드 프록시 뒤로**
   TwelveData(시세)도 Gemini처럼 백엔드가 대신 호출하고 클라이언트는 자체 API만 부르게 통일. 클라이언트에 박히는 키를 하나도 남기지 않는 게 목표.

6. **API 주소/설정값 중앙화**
   Flutter 쪽에 `lib/config/api_config.dart` 하나를 두고 `baseUrl`을 여기서만 관리. 지금처럼 8개 파일에 `127.0.0.1:3050`이 흩어져 있으면 배포 환경을 하나 늘릴 때마다 실수하기 쉬움.

7. **죽은 코드 정리 후 기능 단위 재점검**
   `chart/`, `mock_investment_model.dart`, `stock_service.dart`, `services/finn.py`처럼 안 쓰는 코드를 먼저 지우고 나면, 실제로 살아있는 기능(로그인/회원가입, alpha 차트+모의투자, 투자기록, Gemini 용어사전/조언)만 남아서 다음 리팩터링 범위가 훨씬 명확해짐.

---

## 우선순위 요약

| 순서 | 항목 | 이유 |
|---|---|---|
| 1 | 1.2 인증 미검증 (IDOR) | 남의 계좌 조회/거래 가능 |
| 2 | 1.3, 1.4 가격/수량 조작 | 돈을 임의로 만들어낼 수 있음 |
| 3 | 2.6 신규 유저 balance NULL | 가입 직후 첫 매수가 바로 500 에러 |
| 4 | 2.1 candle INSERT 문법 오류 | 기능이 원천적으로 동작 안 함 |
| 5 | 2.2 login null 체크 순서 | 잘못된 아이디 입력 시 500 에러 |
| 6 | 1.1 키 노출 | 이미 커밋된 비밀번호/토큰 회전 필요 |
| 7 | 3.1~3.5 환경 이식성 | 다음에 또 컴퓨터/사람 바뀌면 재발 |
| 8 | 2.3 trade_history 집계 오류 | 매도 이력 있는 계정 ROI 오표시 |
| 9 | 나머지 (4, 5) | 유지보수성 개선, 급하지 않음 |
