from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import stocks, login, signup, buy_router, sell_router, user_router, gemini_router, trade_history
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4747"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(stocks.router)
app.include_router(login.router)
app.include_router(signup.router)
app.include_router(buy_router.router, prefix="/order")
app.include_router(sell_router.router, prefix="/order")
app.include_router(user_router.router, prefix="/user")
app.include_router(gemini_router.router)
app.include_router(trade_history.router)
print("직접 임포트 시도도")