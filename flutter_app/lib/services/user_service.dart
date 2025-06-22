import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double?> fetchUserCash(int userId) async {
  final response =
      await http.get(Uri.parse("http://127.0.0.1:3050/user/balance/$userId"));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("응답 본문 : ${response.body}");
    return (data['balance'] as num).toDouble();
  } else {
    print("현금 요청 실패 : ${response.statusCode}");
    return null;
  }
}
