import os
from dotenv import load_dotenv

load_dotenv()

API_KEY = os.getenv("FINNHUB_API_KEY")  # Finnhub에서 발급받은 API 키, .env에서 로드
