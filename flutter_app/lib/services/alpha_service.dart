import 'dart:convert';
import 'package:http/http.dart' as http;
import '../features/alpha/alpha_chart_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<List<ChartData>> fetchStockData(String symbol) async {
  final twelvedata_apiKey = dotenv.env['TWELVEDATA_API_KEY'];
  final url = Uri.parse(
    'https://api.twelvedata.com/time_series?symbol=$symbol&interval=1day&&outputsize=1000&apikey=$twelvedata_apiKey',
  );

  print('📦 요청 URL: $url');

  final response = await http.get(url);
  print("응답 코드: ${response.statusCode}");

  final data = jsonDecode(response.body);

  // ❗ 에러 확인
  if (data['values'] == null) {
    throw Exception('데이터 불러오기 실패: ${data['message'] ?? 'Unknown error'}');
  }

  final List<ChartData> chartData = [];

  // 날짜 내림차순으로 오는데, 오름차순 정렬 필요하면 sort
  final sorted = (data['values'] as List).reversed;

  for (final item in sorted) {
    chartData.add(ChartData(
      time: DateTime.parse(item['datetime']),
      open: double.parse(item['open']),
      high: double.parse(item['high']),
      low: double.parse(item['low']),
      close: double.parse(item['close']),
    ));
  }

  return chartData;
}
