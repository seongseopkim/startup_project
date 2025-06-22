import websocket
from database import get_connection
import json

# 전역 변수로 연결과 커서를 초기화
conn = None
cursor = None

# db 연결
def init_db_connection():
    global conn, cursor
    try:
        conn = get_connection()
        cursor = conn.cursor()
        print("DB 연결 및 커서 생성 완료")
    except Exception as e:
        print(f"데이터베이스 연결 중 오류 발생: {e}")
    # db 연결 종료료
def close_db_connection():
    global conn, cursor
    try:
        if cursor:
            cursor.close()
        if conn and conn.is_connected():
            conn.close()
            print("MySQL 연결 종료.")
    except Exception as e:
        print(f"연결 종료 중 오류 발생: {e}")

    #실제로 데이터 넣기기
def on_message(ws, message):
    global conn, cursor
    try:
        data = json.loads(message)
        if data.get("type") == "trade":
            trades = data.get("data", [])
            for trade in trades:
                symbol = trade.get("s")
                price = trade.get("p")
                if symbol and price:
                    insert_sql = "INSERT INTO finnhub (symbol, price) VALUES (%s, %s)"
                    cursor.execute(insert_sql, (symbol, price))
                    conn.commit()
                    print(f"Inserted: {symbol} {price}")
    except Exception as e:
        print("Error processing message:", e)

def on_error(ws, error):
    print("WebSocket error:", error)

def on_close(ws, close_status_code, close_msg):
    print("WebSocket closed:", close_status_code, close_msg)
    # 연결을 종료할 때 DB 연결도 닫도록 함
    close_db_connection()

def on_open(ws):
    # 관심 종목 구독 (원하는 종목으로 수정 가능)
    subscriptions = [
        {"type": "subscribe", "symbol": "AAPL"},
        {"type": "subscribe", "symbol": "AMZN"},
        {"type": "subscribe", "symbol": "BINANCE:BTCUSDT"},
        {"type": "subscribe", "symbol": "IC MARKETS:1"}
    ]
    for sub in subscriptions:
        ws.send(json.dumps(sub))

def run_finnhub():

    # Finnhub API 토큰을 YOUR_API_TOKEN 부분에 입력
    ws_url = "wss://ws.finnhub.io?token=cvn631hr01qqv4gvmo70cvn631hr01qqv4gvmo7g"
    
    # WebSocket 실행 전에 DB 연결 초기화
    init_db_connection()
    
    ws = websocket.WebSocketApp(ws_url,
                                on_message=on_message,
                                on_error=on_error,
                                on_close=on_close)
    ws.on_open = on_open
    ws.run_forever()
    

if __name__ == "__main__":
    run_finnhub()
