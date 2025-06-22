import requests
from database import get_connection
from config import API_KEY

def fetch_and_save_stock_list(exchanges=["US", "KS", "KQ"]):
    conn = get_connection()
    cursor = conn.cursor()

    for exchange in exchanges:
        url = f"https://finnhub.io/api/v1/stock/symbol?exchange={exchange}&token={API_KEY}"
        response = requests.get(url)
        stocks = response.json()

        print(f"[{exchange}] 종목 {len(stocks)}개 수신")

        for stock in stocks:
            try:
                sql = """
                    INSERT IGNORE INTO Stocks (symbol, name, currency, exchange, type)
                    VALUES (%s, %s, %s, %s, %s)
                """
                values = (
                    stock["symbol"],
                    stock.get("description", ""),
                    stock.get("currency", ""),
                    exchange,  # <- 여기에 그대로 저장
                    stock.get("type", "")
                )
                cursor.execute(sql, values)
            except Exception as e:
                print(f"[{exchange}] Insert error: {e} - {stock['symbol']}")

    conn.commit()
    cursor.close()
    conn.close()
