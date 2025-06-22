import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double> fetchUsdToKrwExim() async {
  print("exchange.dart 실행중!");

  final url = Uri.parse(
    'https://api.frankfurter.app/latest?from=USD&to=KRW',
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final rate = data['rates']['KRW'];
    print("exchange.dart는 정상 작동됨");
    return rate.toDouble();
  } else {
    throw Exception('환율 조회 실패: ${response.statusCode}');
  }
}
