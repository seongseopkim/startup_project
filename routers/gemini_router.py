from fastapi import APIRouter, HTTPException
import os
import requests
from dotenv import load_dotenv
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List

load_dotenv()

router = APIRouter()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GEMINI_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={GEMINI_API_KEY}"

print("✅ GEMINI_API_KEY:", GEMINI_API_KEY)

@router.post("/ask-gemini")
def ask_gemini(payload: dict):
    prompt = payload.get("question")
    if not prompt:
        raise HTTPException(status_code=400, detail="질문을 보내주세요")
    
    headers = {"Content-Type": "application/json"}
    body = {
        "contents": [{"parts": [{"text": prompt}]}]
    }

    response = requests.post(GEMINI_URL, headers=headers, json=body)

    if response.status_code == 200:
        res_json = response.json()
        text = res_json['candidates'][0]['parts'][0]['text']
        return {"answer": text}
    else:
        print(response.text)
        raise HTTPException(status_code=500, detail="Gemini 응답 오류, gemini_router.py")


@router.post("/trade-feedback")
def trade_feedback(payload: dict):
    """
    매수 / 매도에 대한 피드백을 제공함!
    """

    symbol = payload.get("symbol")
    price = payload.get("price")
    qty = payload.get("qty")
    trade_type = payload.get("trade_type")

    # trade_type 디버깅용 print
    print(f"받은 데이터 : ", trade_type)


    if any(v in [None, ""] for v in [symbol, price, qty, trade_type]):
        raise HTTPException(status_code=400, detail="필수 정보가 부족합니다")
    if trade_type.lower() == "buy":
        type = '매수'
    elif trade_type.lower() == "sell":
        type = '매도'
    else:
        raise HTTPException(
            status_code=400, 
            detail="trade_type은 buy거나 sell이어야 합니다.")
    prompt = (
        f"모의 투자 어플에서 {symbol}주식을 {price}달러에 {qty}주 {type}했습니다.\n"
        f"이 거래가 초보 투자자 입장에서 괜찮은 평가해 주세요.\n"
        f"혹시 매도를 하였다면 수익성이 명확한 다른 종목이 있다면 추천해주세요. 없다면 없습니다 라고 하지 말고 어느곳에서 인사이트를 얻으면 좋을지 알려주세요.\n"
        f"이 주식에 관련이 있는 뉴스가 있다면 그 정보도 포함해서 전체 2~3줄로 설명해주고, 당신이 투자를 한다면 어떤 방식으로 진행할지 쉬운 단어로 설명해주세요"

    )
    
    headers = {"Content-Type": "application/json"}

    body = {
        "contents" : [{"parts": [{"text": prompt}]}]
    }

    response = requests.post(GEMINI_URL, headers=headers, json=body)

    if response.status_code == 200:
        res_json = response.json()
        text = res_json['candidates'][0]['content']['parts'][0]['text']
        return {"answer": text}
    else:
        print("gemini 응답 오류 ", response.text)
        raise HTTPException(status_code=500, detail="GEMINI 응답 오류, trade-feedback")

print("gemini router loaded")


# 여기서부터 투자 조언!!
class TradeItem(BaseModel):
    symbol: str
    quantity: int
    average_price: float
    current_price: float
    total_value: float

@router.post("/gemini/advice")
async def gemini_advice(trades: List[TradeItem]):
    prompt = "다음은 투자 기록입니다.\n\n"
    for trade in trades:
        prompt += (
            f"- 종목: {trade.symbol}, 수량: {trade.quantity}, "
            f"매입가: {trade.average_price}, 현재가: {trade.current_price}\n"
        )

    prompt += "\n전문가로서 이 투자에 대해 조언해주고 바꿀 부분이 있다면 친절하게 설명해주세요. 사용자라는 단어는 쓰지 마세요."

    headers = {"Content-Type": "application/json"}
    body = {"contents": [{"parts": [{"text": prompt}]}]}

    response = requests.post(GEMINI_URL, headers=headers, json=body)
    response.encoding = 'utf-8'  # ✅ 반드시 .json() 하기 전에 지정

    if response.status_code == 200:
        res_json = response.json()
        text = res_json['candidates'][0]['content']['parts'][0]['text']
        return {"answer": text}
    else:
        print("Gemini 응답 오류:", response.text)
        raise HTTPException(status_code=500, detail="Gemini 응답 실패")

@router.post("/gemini/term-explanation")
def explain_term(payload: dict):
    term = payload.get("term")
    if not term:
        raise HTTPException(status_code=400, detail="용어를 입력해주세요")

    prompt = (
        f"주식 초보자가 이해할 수 있도록 '{term}'이라는 용어를 쉬운 단어로 설명해줘. "
        f"예시나 비교 설명을 포함해서 2~3문단 이내로 해줘."
    )

    headers = {"Content-Type": "application/json"}
    body = {"contents": [{"parts": [{"text": prompt}]}]}

    response = requests.post(GEMINI_URL, headers=headers, json=body)
    response.encoding = 'utf-8'

    if response.status_code == 200:
        response.encoding = 'utf-8'
        res_json = response.json()
        text = res_json['candidates'][0]['content']['parts'][0]['text']
        #final decoded = utf8.decode(response.bodyBytes);
        #final data = jsonDecode(decoded);
        return JSONResponse(
            content={"answer": text},
            media_type="application/json; charset=utf-8"
        )
    else:
        print("Gemini 용어 설명 오류:", response.text)
        raise HTTPException(status_code=500, detail="Gemini 용어 설명 실패")