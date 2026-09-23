-- ANT HOUSE 데이터베이스 스키마
-- model.py, services/*.py에서 실제로 쓰는 테이블 기준으로 작성.
-- Docker MySQL 컨테이너 최초 기동 시 자동 실행됨 (docker-compose.yml 참고).

CREATE DATABASE IF NOT EXISTS anthouse
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE anthouse;

-- 사용자 테이블 (model.py User)
CREATE TABLE IF NOT EXISTS users (
  user_id     INT AUTO_INCREMENT PRIMARY KEY,
  username    VARCHAR(50),
  email       VARCHAR(100),
  password    VARCHAR(255),
  nickname    VARCHAR(50),
  balance     DECIMAL(15, 2) NOT NULL DEFAULT 1000000.00,
  created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- 거래 기록 테이블 (model.py TradeHistory)
CREATE TABLE IF NOT EXISTS trade_history (
  trade_id      INT AUTO_INCREMENT PRIMARY KEY,
  user_id       INT NOT NULL,
  stock_symbol  VARCHAR(20) NOT NULL,
  trade_type    ENUM('BUY', 'SELL') NOT NULL,
  trade_price   DECIMAL(15, 2) NOT NULL,
  quantity      INT NOT NULL,
  trade_date    DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_trade_history_user (user_id)
);

-- 보유 종목 테이블 (model.py UserPortfolio)
CREATE TABLE IF NOT EXISTS user_portfolio (
  portfolio_id   INT AUTO_INCREMENT PRIMARY KEY,
  user_id        INT NOT NULL,
  stock_symbol   VARCHAR(20) NOT NULL,
  quantity       INT NOT NULL,
  average_price  DECIMAL(15, 2) NOT NULL,
  UNIQUE KEY uq_user_symbol (user_id, stock_symbol)
);

-- 종목 리스트 테이블 (services/finnhub_service.py fetch_and_save_stock_list)
CREATE TABLE IF NOT EXISTS Stocks (
  symbol    VARCHAR(20) PRIMARY KEY,
  name      VARCHAR(255),
  currency  VARCHAR(10),
  exchange  VARCHAR(10),
  type      VARCHAR(50)
);

-- 일봉 시세 테이블 (services/candle_service.py fetch_daily_candles)
CREATE TABLE IF NOT EXISTS DailyPrice (
  symbol      VARCHAR(20) NOT NULL,
  price_date  DATE NOT NULL,
  open        DECIMAL(15, 4),
  high        DECIMAL(15, 4),
  low         DECIMAL(15, 4),
  close       DECIMAL(15, 4),
  volume      BIGINT,
  PRIMARY KEY (symbol, price_date)
);
