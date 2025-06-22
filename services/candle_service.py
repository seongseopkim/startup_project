import time
from datetime import datetime, timedelta
import requests
from config import API_KEY
from database import get_connection


def fetch_daily_candles(symbol: str):
    end_time = int(time.time())
    start_time = int((datetime.now() - timedelta(days=365 * 3)).timestamp())
    url = f"https://finnhub.io/api/v1/stock/candle?symbol={symbol}&resolution=D&from={start_time}&to={end_time}&token={API_KEY}"
    
    print(f"✅ 요청 URL: {url}")  # 반드시 확인용 출력 추
    response = requests.get(url)
    data = response.json()

    if data.get("s") != "ok":
        print(f"{symbol} 데이터 오류")
        return

    conn = get_connection()
    cursor = conn.cursor()

    for i in range(len(data["t"])):
        cursor.execute("""
            INSERT IGNORE INTO DailyPrice ()
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (
            symbol,
            datetime.fromtimestamp(data["t"][i]).date(),
            data["o"][i],
            data["h"][i],
            data["l"][i],
            data["c"][i],
            data["v"][i]
        ))

    conn.commit()
    cursor.close()
    conn.close()
