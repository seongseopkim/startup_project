from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db import get_db
from model import TradeHistory
import yfinance as yf
from decimal import Decimal
import requests
import os
router = APIRouter(prefix="/trade_history", tags=["Trades"])

# 현재 주가 가져오기 (야후 파이낸스)
def get_current_price(symbol: str) -> float:
    twelvedata_api_key = os.getenv("TWELVEDATA_API_KEY")
    url = f"https://api.twelvedata.com/price?symbol={symbol}&apikey={twelvedata_api_key}"
    try:
        response = requests.get(url)
        response.raise_for_status()
        price = float(response.json()["price"])
        return round(price, 2)
    except Exception as e:
        print(f"❌ TwelveData 주가 조회 실패: {symbol} - {e}")
        return 100.0  # fallback 기본값

@router.get("/{user_id}")
def get_user_trades(user_id: int, db: Session = Depends(get_db)):
    user_trades = db.query(TradeHistory).filter(TradeHistory.user_id == user_id).all()

    if not user_trades:
        raise HTTPException(status_code=404, detail="No trades found")
    
    portfolio = {}

    for trade in user_trades:
        symbol = trade.stock_symbol
        qty = trade.quantity
        price = trade.trade_price  # Decimal

        if symbol not in portfolio:
            portfolio[symbol] = {
                "quantity": 0,
                "total_cost": Decimal("0.0")  # ✅ Decimal로 초기화
            }

        portfolio[symbol]["quantity"] += qty
        portfolio[symbol]["total_cost"] += price * qty

    result = []

    for symbol, data in portfolio.items():
        quantity = data["quantity"]
        total_cost = data["total_cost"]

        if quantity <= 0:
            continue

        average_price = float(round(total_cost / quantity, 2))
        current_price = get_current_price(symbol)
        total_value = round(current_price * quantity, 2)

        result.append({
            "symbol": symbol,
            "quantity": quantity,
            "average_price": average_price,
            "current_price": current_price,
            "total_value": total_value
        })

    return result
