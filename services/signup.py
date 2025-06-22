import bcrypt
from fastapi import HTTPException
from database import get_connection

def sign_up(data) -> bool:
    username = data.username
    password = data.password
    email = data.email

    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
    if cursor.fetchone():
        raise HTTPException(status_code=400, detail="이미 존재하는 아이디입니다")
    
    hashed_pw = bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()
    cursor.execute("INSERT INTO users(username, password, email) VALUES (%s, %s, %s)", (username, hashed_pw, email))

    conn.commit()
    conn.close()

    return True


