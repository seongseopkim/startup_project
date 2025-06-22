from decimal import Decimal
from datetime import datetime

def serialize_item(item):
    return {
        "symbol": item["symbol"],
        "price": float(item["price"]) if isinstance(item["price"], Decimal) else item["price"],
        "timestamp": item["timestamp"].isoformat() if isinstance(item["timestamp"], datetime) else item["timestamp"]
    }
