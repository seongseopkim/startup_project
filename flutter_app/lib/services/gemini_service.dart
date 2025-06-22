import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fetchTradeFeedback({
  required String symbol,
  required double price,
  required int qty,
  required String tradeType,
}) async {
  final url = Uri.parse("http://127.0.0.1:3050/trade-feedback");

  final response = await http.post(
    url,
    headers: {"Content-type": "application/json"},
    body: jsonEncode({
      "symbol": symbol,
      "price": price,
      "qty": qty,
      "trade_type": tradeType,
    }),
  );

  if (response.statusCode == 200) {
    final decoded = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decoded);
    return data['answer'];
  } else {
    print("Gemini 피드백 오류: ${utf8.decode(response.bodyBytes)}");
    return null;
  }
}
