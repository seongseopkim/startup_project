from fastapi import APIRouter
from pydantic import BaseModel, EmailStr
from services.signup import sign_up

router = APIRouter()

class SignupData(BaseModel):
    username: str
    password: str
    email: EmailStr

@router.post("/signup")
def signup_route(data : SignupData):
    result = sign_up(data)

    if result:
        return { "success": True, "message": "회원가입 성공"}
    else:
        return {"success": False, "messages": "회원가입 실패"}
    
    