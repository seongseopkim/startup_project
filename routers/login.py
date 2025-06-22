from fastapi import APIRouter
from services.login import log_in
from pydantic import BaseModel

router = APIRouter()

class LoginRequest(BaseModel):
    username: str
    password: str



@router.post("/login")
def login(login_data: LoginRequest) :
    print("로그인시도중중")
    return log_in(login_data)




