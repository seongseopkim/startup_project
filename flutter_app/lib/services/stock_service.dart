// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../features/chart/chart_model.dart';
// import '../config/api.dart';

// Future<List<ChartData>> fetchStockData(String symbol) async {
//   final now = DateTime.now();
//   final from =
//       now.subtract(Duration(days: 365 * 3)).millisecondsSinceEpoch ~/ 1000;
//   final to = now.millisecondsSinceEpoch ~/ 1000;

//   final url = Uri.parse(
//       'https://finnhub.io/api/v1/stock/candle?symbol=$symbol&resolution=D&from=$from&to=$to&token=d0cno81r01ql2j3echngd0cno81r01ql2j3echo0');

//   print('📦 요청 URL: $url');

//   final response = await http.get(url);
//   final data = jsonDecode(response.body);

//   if (data['s'] != 'ok') {
//     throw Exception('데이터 불로오기 실패');
//   }

//   final List<ChartData> chartData = [];
//   for (int i = 0; i < data['t'].length; i++) {
//     chartData.add(ChartData(
//       time: DateTime.fromMillisecondsSinceEpoch(data['t'][i] * 1000),
//       open: data['o'][i].toDouble(),
//       high: data['h'][i].toDouble(),
//       low: data['l'][i].toDouble(),
//       close: data['c'][i].toDouble(),
//     ));
//   }

//   return chartData;
// }





                                                                                                                    
// // 📦 요청 URL: https://finnhub.io/api/v1/stock/candle?symbol=AAPL&resolution=D&from=1651977351&to=1746585351&token=d0cno81r01ql2j3echngd0cno81r01ql2j3echo0
// // finnhub.io/api/v1/stock/candle?symbol=AAPL&resolution=D&from=1651977351&to=1746585351&token=d0cno81r01ql2j3echngd0cno81r01ql2j3echo0:1 
            
            
// //            Failed to load resource: the server responded with a status of 403 ()