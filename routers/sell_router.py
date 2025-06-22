from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import SessionLocal
from schemas import SellRequest
from services.sell_service import process_sell_order


router = APIRouter()

# db세션 의존성 주입
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/sell")
def sell_stock(order: SellRequest, db: Session=Depends(get_db)):
    try:
        result = process_sell_order(db, order)
        print("sell_service로 잘 넘김!")
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))