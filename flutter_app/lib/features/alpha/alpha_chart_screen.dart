import 'package:flutter/material.dart';
import 'package:flutter_app/services/gemini_service.dart';
import 'package:flutter_app/user_provider.dart';
import 'package:provider/provider.dart';
import 'alpha_chart_model.dart';
import '../../services/alpha_service.dart';
import 'alpha_chart_widget.dart';
import '../../services/buy_service.dart';
import '../../controllers/sell_stock.dart';
import '../../services/user_service.dart';
import 'package:intl/intl.dart';
import '../../services/exchange.dart';

final formatter = NumberFormat('#,###');

class AlphaChartScreen extends StatefulWidget {
  const AlphaChartScreen({super.key});

  @override
  State<AlphaChartScreen> createState() => _AlphaChartScreenState();
}

class _AlphaChartScreenState extends State<AlphaChartScreen> {
  late Future<List<ChartData>> charFuture;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSymbol = 'AAPL';

  void _searchStock() {
    final input = _searchController.text.trim();
    if (input.isNotEmpty) {
      setState(() {
        _selectedSymbol = input.toUpperCase();
      });
    }
  }

  void _goToMockInvestment() async {
    final chartData = await fetchStockData(_selectedSymbol);
    if (!mounted) return;
    final userId = Provider.of<UserProvider>(context, listen: false).userId!;
    final cash = await fetchUserCash(userId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: const Text(' ANT HOUSE',
                style: TextStyle(color: Colors.purpleAccent)),
            backgroundColor: const Color(0xFF1F1F1F),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: MockInvestmentContent(
            symbol: _selectedSymbol,
            chartData: chartData,
            initialCash: cash ?? 0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            '차트 탭',
            style: TextStyle(color: Colors.purpleAccent),
          )),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: '종목 검색 (예: AAPL, MSFT)',
                      labelStyle: TextStyle(color: Colors.white),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.grey), //  검색 아이콘 회색
                      hintText: '종목 검색 (예: AAPL, MSFT)',
                      hintStyle:
                          const TextStyle(color: Colors.grey), //  힌트 글자 회색
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E), // 입력창 배경 어둡게
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchStock,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ChartData>>(
                future: fetchStockData(_selectedSymbol),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('에러: \${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return AlphaChartWidget(data: snapshot.data!);
                  } else {
                    return const Center(child: Text('데이터가 없습니다.'));
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2C2C), // ✅ 배경 어둡게
                foregroundColor: Colors.white, // ✅ 글자 흰색
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: _goToMockInvestment,
              child: const Text(
                '모의 투자',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MockInvestmentContent extends StatefulWidget {
  final String symbol;
  final List<ChartData> chartData;
  final double initialCash;

  const MockInvestmentContent({
    super.key,
    required this.symbol,
    required this.chartData,
    required this.initialCash,
  });

  @override
  State<MockInvestmentContent> createState() => _MockInvestmentContentState();
}

class _MockInvestmentContentState extends State<MockInvestmentContent> {
  double cash = 0;

  double usdAmount = 0; // 보유 달러
  double? exchangeRate = 0; // API로 받은 환율

  final List<Map<String, dynamic>> trades = [];
  @override
  void initState() {
    super.initState();
    cash = widget.initialCash;
    _loadCashFromServer();
    _loadExchangeRate();

    usdAmount = cash;

    print(" 전달받은 종목: ${widget.symbol}");
    print(" 받은 차트 데이터 개수: ${widget.chartData.length}");
  }

  Future<void> _loadCashFromServer() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final result = await fetchUserCash(userId!);
    if (result != null) {
      setState(() {
        cash = result;
      });
    }
  }

  Future<void> _loadExchangeRate() async {
    exchangeRate = await fetchUsdToKrwExim();
    print("💱 현재 환율: $exchangeRate");
    setState(() {}); // UI 갱신
  }

  final symbolController = TextEditingController();
  final quantityController = TextEditingController();
  final priceController = TextEditingController();
  double get latestPrice => widget.chartData.last.close;

  Future<void> _buyStock() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final qty = int.tryParse(quantityController.text) ?? 0;
    final symbol = widget.symbol;
    final price = latestPrice;
    print(userId);

    if (qty <= 0) return;

    final total = qty * price;
    //buy_service API 호출!
    bool success = await buyStockApi(
        userId: userId!,
        symbol: symbol,
        quantity: qty,
        price: price,
        timestamp: DateTime.now());

    if (success) {
      setState(() {
        cash -= total;
        trades.add({
          'symbol': symbol,
          'qty': qty,
          'price': price,
          'timestamp': DateTime.now(),
          'type': 'buy',
        });
        quantityController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("매수 요청 실패")),
      );
    }
  }

/////////////////////////////////////////////////////////////////////
//여기서부터 거래 내역 부분이라고 생각하셈
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              " 보유현금: \$${formatter.format(cash)} ",
              style: const TextStyle(color: Colors.white),
            ),
            if (exchangeRate != null && exchangeRate != 0)
              Text(
                " 약 ₩${formatter.format((cash * exchangeRate!).round())}원",
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF9966CC),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "종목 : ${widget.symbol}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 68, 62, 73),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      "현재가 : \$${latestPrice.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
            ),
            SizedBox(
              width: 300,
              child: TextField(
                controller: quantityController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '수량',
                  labelStyle: const TextStyle(
                    color: Colors.white,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.grey[900],
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _buyStock,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 18), // 내부 패딩 ↑
                        textStyle: const TextStyle(
                            // 텍스트 스타일 직접 설정
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        backgroundColor: Colors.green),
                    child: const Text("매수하기"),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = context.read<UserProvider>().userId!;
                      final qty = int.tryParse(quantityController.text) ?? 0;
                      final price = latestPrice;

                      final result = await sellstock(
                          userId: userId,
                          cash: cash,
                          symbol: widget.symbol,
                          qty: qty,
                          price: price,
                          timestamp: DateTime.now(),
                          updateCash: (newCash) =>
                              setState(() => cash = newCash),
                          addTrade: (trade) {
                            print("매도 거래 추가됨 : $trade");
                            setState(() => trades.add(trade));
                          });

                      if (result != null) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(result)));
                      } else {
                        quantityController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60), // 높이 ↑
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 18), // 내부 패딩 ↑
                      textStyle: const TextStyle(
                          // 텍스트 스타일 직접 설정
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                      backgroundColor: Colors.red,
                    ),
                    child: const Text("매도하기"),
                  ),
                ),
              ],
            ),
            const Divider(),
            const Text(" 거래 내역", style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            trades.isEmpty
                ? const Text(
                    "거래 내역이 없습니다.",
                    style: TextStyle(color: Colors.white),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: trades.length,
                    itemBuilder: (context, index) {
                      final t = trades[index];
                      final isBuy = t['type'] == 'buy';
                      final actionText = isBuy ? '매수' : '매도';
                      final actionColor = isBuy ? Colors.green : Colors.red;

                      return Card(
                        color: Colors.grey[900],
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text("${t['symbol']} ${t['qty']}주 $actionText",
                              style: TextStyle(color: actionColor)),
                          subtitle: Text("₩${t['price']} | ${t['timestamp']}",
                              style: TextStyle(color: Colors.white70)),
                          onTap: () async {
                            final answer = await fetchTradeFeedback(
                                symbol: t['symbol'],
                                price: t['price'],
                                qty: t['qty'],
                                tradeType: t['type']);

                            if (answer != null) {
                              showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                        backgroundColor: Colors.grey[900],
                                        title: const Text(
                                          "*Gemini 피드백*",
                                          style: TextStyle(
                                              color: Colors.purpleAccent),
                                        ),
                                        content: Text(
                                          answer,
                                          style: TextStyle(
                                              color: const Color.fromARGB(
                                                  255, 203, 188, 210)),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text("닫기")),
                                        ],
                                      ));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Gemini 응답 실패, AlertDialog")),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
