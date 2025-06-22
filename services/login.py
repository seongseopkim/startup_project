import bcrypt
from fastapi import HTTPException
from database import get_connection
from utils.jwt_utils import create_access_token


def log_in(login_data) :

    username = login_data.username
    password = login_data.password

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
    user = cursor.fetchone()
    print("비교 결과:", bcrypt.checkpw(password.encode(), user["password"].encode()))

    if not user:
        raise HTTPException(status_code=404, detail="존재하지 않는 사용자입니다")
    
    if not bcrypt.checkpw(password.encode(), user["password"].encode()):
        raise HTTPException(status_code=401, detail="비밀번호가 틀렸습니다")


    token = create_access_token({"sub": user["username"]})
    
    return {"access_token" : token, 
            "token_type" : "bearer",
            "user_id": user["user_id"]}

