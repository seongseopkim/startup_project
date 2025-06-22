from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from schemas import BuyRequest
from services.buy_service import process_buy_order


router = APIRouter()

#DB 세션 의존성 주입 
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


#매수 요청 API
@router.post("/buy")
def buy_stock(order: BuyRequest, db: Session=Depends(get_db)):
    try:
        result = process_buy_order(db ,order)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    
print("buy_router loaded")