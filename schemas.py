from pydantic import BaseModel
from datetime import datetime

class BuyRequest(BaseModel):
    user_id: int
    stock_symbol: str
    quantity: int
    trade_price: float
    trade_date: datetime

class SellRequest(BaseModel):
    user_id: int
    stock_symbol: str
    quantity : int
    trade_price: float
    trade_date: datetime