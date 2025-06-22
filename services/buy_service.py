from decimal import Decimal

from requests import Session

import schemas
import model

def process_buy_order(db: Session, order: schemas.BuyRequest):
    current_price = Decimal(order.trade_price)
    total_cost = current_price * order.quantity

    user = db.query(model.User).filter(model.User.user_id == order.user_id).first()
    if not user:
        raise ValueError("사용자 정보가 존재하지 않습니다다")
    if user.balance < total_cost:
        raise ValueError("잔고가 부족합니다ㅜㅜㅜ")
    
    user.balance -= total_cost
    db.add(user)

    trade = model.TradeHistory(
        user_id=order.user_id,
        stock_symbol=order.stock_symbol,
        trade_type="BUY",
        trade_price=current_price,
        quantity=order.quantity,
        trade_date=order.trade_date
    )
    db.add(trade)

    portfolio = db.query(model.UserPortfolio).filter(
        model.UserPortfolio.user_id == order.user_id,
        model.UserPortfolio.stock_symbol == order.stock_symbol
    ).first()

    if portfolio:
        total_qty = portfolio.quantity + order.quantity
        total_value = (portfolio.average_price * portfolio.quantity) + total_cost
        portfolio.quantity = total_qty
        portfolio.average_price = total_value / total_qty
    else:
        portfolio = model.UserPortfolio(
            user_id=order.user_id,
            stock_symbol=order.stock_symbol,
            quantity=order.quantity,
            average_price=current_price
        )
        db.add(portfolio)
    db.commit()
    return{
        "message": "매수가 완료되었습니다.",
        "trade_price": str(current_price),
        "total_cost": str(total_cost),
        "remaining_balance": str(user.balance)
    }
