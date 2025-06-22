import 'dart:convert';
import 'package:http/http.dart' as http;

/// 실제 매수 요청을 FastAPI로 보내는 함수
Future<bool> buyStockApi({
  required int userId,
  required String symbol,
  required int quantity,
  required double price,
  required DateTime timestamp,
}) async {
  final url = Uri.parse('http://127.0.0.1:3050/order/buy');

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_id": userId,
      "stock_symbol": symbol,
      "quantity": quantity,
      "trade_price": price,
      "trade_date": timestamp.toIso8601String(),
    }),
  );

  if (response.statusCode == 200) {
    final decodedBody = utf8.decode(response.bodyBytes);
    print("매수 성공: $decodedBody");
    return true;
  } else {
    print(" 매수 실패: ${response.statusCode} ${response.body}");
    return false;
  }
}
