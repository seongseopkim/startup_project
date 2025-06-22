import 'dart:convert';
import 'package:http/http.dart' as http;

/// 사용자 투자 기록 가져오기
Future<List<Map<String, dynamic>>> fetchTrades(int userId) async {
  final url = Uri.parse('http://127.0.0.1:3050/trade_history/$userId');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  } else {
    throw Exception('투자 기록을 불러오지 못했습니다');
  }
}

/// Gemini에게 투자 조언 받기
Future<String> getGeminiAdvice(List<Map<String, dynamic>> trades) async {
  final uri = Uri.parse('http://127.0.0.1:3050/gemini/advice');

  final response = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(trades),
  );

  if (response.statusCode == 200) {
    // ✅ 한글 깨짐 방지: 바이트 → UTF-8 → JSON 디코딩
    final decoded = utf8.decode(response.bodyBytes);
    final data = jsonDecode(decoded);
    return data['answer'];
  } else {
    throw Exception("Gemini 조언 요청 실패: ${response.statusCode}");
  }
}
