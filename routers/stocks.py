from fastapi import APIRouter
from services.finnhub_service import fetch_and_save_stock_list
from services.candle_service import fetch_daily_candles

router = APIRouter()

# 1. 종목 리스트 전체 로딩 (미국 + 한국)
@router.post("/load_stock_list")
def load_stock_list():
    fetch_and_save_stock_list()  # 내부에서 US, KS, KQ 가져오도록 되어 있음
    return {"message": "종목 리스트 저장 완료"}

# 2. 종목 하나 선택 시 3년치 일봉 데이터 로딩
@router.post("/load_candles/{symbol}")
def load_candles(symbol: str):
    fetch_daily_candles(symbol.upper())  # 시세 저장 함수 호출
    return {"message": f"{symbol} 일봉 데이터 저장 완료"}
