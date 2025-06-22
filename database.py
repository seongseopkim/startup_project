from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "mysql+pymysql://root:1807@localhost:3306/anthouse"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# db_connection.py
import mysql.connector
from mysql.connector import Error


DB_HOST = "localhost"
DB_USER = "root"
DB_PASSWORD = "1807"
DB_NAME = "anthouse"



def get_connection():
    """
    MySQL 데이터베이스에 연결하고, 연결 객체를 반환하는 함수입니다.
    연결에 실패하면 예외를 발생시킵니다.
    """
    
    try:
        connection = mysql.connector.connect(
            host='localhost',       # 데이터베이스 서버 주소
            user='root',   # 사용자명
            password='1807', # 비밀번호
            database='anthouse'     # 사용할 데이터베이스 이름
        )
        if connection.is_connected():
            print("MySQL에 성공적으로 연결되었습니다.")
            return connection
    except Error as e:
        print(f"오류 발생: {e}")
        raise
