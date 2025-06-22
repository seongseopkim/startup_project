from decimal import Decimal
from fastapi import HTTPException

from requests import Session

import model
import schemas

def process_sell_order(db: Session, order: schemas.SellRequest):
    print("selling 작업이 진행중입니다")
    current_price = Decimal(order.trade_price)
    total_income = current_price * order.quantity
    #사용자 확인인
    user = db.query(model.User).filter(model.User.user_id == order.user_id).first()
    if not user:
        raise ValueError("사용자 정보가 존재하지 않습니다다")

    user.balance += total_income
    db.add(user)

    #포트폴리오 DB안에 매수한 주식이 있는지 확인
    portfolio = db.query(model.UserPortfolio).filter(
        model.UserPortfolio.user_id == order.user_id,
        model.UserPortfolio.stock_symbol == order.stock_symbol
    ).first()

    if not portfolio:
        raise HTTPException(status_code=400, detail="해당 종목 미보유입니다")

    if portfolio.quantity < order.quantity:
        raise HTTPException(status_code=400, detail="보유 수량이 부족합니다")

    portfolio.quantity -= order.quantity
    if portfolio.quantity == 0:
        db.delete(portfolio)
        print(f"{order.stock_symbol}  주식을 전부 매도했습니다")

    
    trade = model.TradeHistory(
        user_id = order.user_id,
        stock_symbol = order.stock_symbol,
        trade_type="SELL",
        trade_price=current_price,
        quantity = order.quantity,
        trade_date = order.trade_date

    )
    db.add(trade)
    db.commit()
    print("db에 매도 처리리 완료!")
    return{"new_balance" : float(user.balance)}
    