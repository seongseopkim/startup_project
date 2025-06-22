// import 'package:flutter/material.dart';
// import 'mock_investment_screen.dart'; // 모의투자 화면으로 이동용
// import 'chart_model.dart';
// import '../../services/stock_service.dart';
// import 'stock_chart_widget.dart';

// class StockChartScreen extends StatefulWidget {
//   const StockChartScreen({super.key});

//   @override
//   State<StockChartScreen> createState() => _StockChartScreenState();
// }

// // 캔들 차트
// class CandleData {}

// class _StockChartScreenState extends State<StockChartScreen> {
//   late Future<List<ChartData>> charFuture;
//   final TextEditingController _searchController = TextEditingController();
//   String _selectedSymbol = 'AAPL'; // 기본 종목

//   void _searchStock() {
//     final input = _searchController.text.trim();
//     if (input.isNotEmpty) {
//       setState(() {
//         _selectedSymbol = input.toUpperCase();
//       });
//     }
//   }

//   void _goToMockInvestment() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const MockInvestmentScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('주식 차트 조회')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // 검색창
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _searchController,
//                     decoration: const InputDecoration(
//                       labelText: '종목 검색 (예: AAPL, TSLA)',
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.search),
//                   onPressed: _searchStock,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // 차트 자리 (나중에 실제 차트로 교체 가능)
//             Expanded(
//                 child: FutureBuilder<List<ChartData>>(
//                     future: fetchStockData(_selectedSymbol),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const Center(child: CircularProgressIndicator());
//                       } else if (snapshot.hasError) {
//                         return Center(child: Text('에러: ${snapshot.error}'));
//                       } else if (snapshot.hasData &&
//                           snapshot.data!.isNotEmpty) {
//                         return StockChartWidget(data: snapshot.data!);
//                       } else {
//                         return const Center(child: Text('데이터가 없습니다.'));
//                       }
//                     })),

//             const SizedBox(height: 16),

//             // 모의 투자 버튼
//             ElevatedButton(
//               onPressed: _goToMockInvestment,
//               child: const Text('모의 투자'),
//               style: ElevatedButton.styleFrom(
//                 minimumSize: const Size.fromHeight(50),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
