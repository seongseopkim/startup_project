from sqlalchemy import Enum as SQLAlchemyEnum, DECIMAL, Column, Integer, String, Float, DateTime
from datetime import datetime
from database import Base
import enum

class TradeTypeEnum(str, enum.Enum):
    BUY = "BUY"
    SELL = "SELL"

    
# 사용자 테이블
class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50))
    email = Column(String(100))
    password = Column(String(255))
    nickname = Column(String(50))
    balance = Column(DECIMAL(15, 2))
    created_at = Column(DateTime)
    updated_at = Column(DateTime)

# 거래 기록 테이블
class TradeHistory(Base):
    __tablename__ = "trade_history"

    trade_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer)
    stock_symbol = Column(String(20))
    trade_type = Column(SQLAlchemyEnum(TradeTypeEnum), nullable=False)
    trade_price = Column(DECIMAL(15, 2))
    quantity = Column(Integer)
    trade_date = Column(DateTime, default=datetime.utcnow)

# 보유 종목 테이블
class UserPortfolio(Base):
    __tablename__ = "user_portfolio"

    portfolio_id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer)
    stock_symbol = Column(String(20))
    quantity = Column(Integer)
    average_price = Column(DECIMAL(15, 2))

