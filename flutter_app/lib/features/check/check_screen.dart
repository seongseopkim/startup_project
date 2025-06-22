import 'package:flutter/material.dart';
import 'package:flutter_app/user_provider.dart';
import 'package:provider/provider.dart';
import 'check_service.dart'; // fetchTrades 함수 import

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  double roi = 0.0; // 수익률
  List<Map<String, dynamic>> trades = []; // 투자 기록
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  Future<void> _loadTrades() async {
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId!;
      print(userId);
      final data = await fetchTrades(userId);
      print("fetchtrades에서 가져온 데이터터");
      print(data);
      setState(() {
        trades = data;
        roi = _calculateROI(data);
        isLoading = false;
      });
    } catch (e) {
      print(" 투자 기록 불러오기 실패: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  double _calculateROI(List<Map<String, dynamic>> trades) {
    double initialCost = 0.0;
    double currentValue = 0.0;

    for (var trade in trades) {
      initialCost +=
          (trade['average_price'] as num) * (trade['quantity'] as int);
      currentValue +=
          (trade['current_price'] as num) * (trade['quantity'] as int);
    }

    if (initialCost == 0) return 0.0;
    return ((currentValue - initialCost) / initialCost) * 100;
  }

  void _askGeminiForAdvice() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('AI 피드백 요청 중...'),
        content: Center(child: CircularProgressIndicator()),
      ),
    );

    try {
      final advice = await getGeminiAdvice(trades);
      Navigator.pop(context); // 로딩창 닫기

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(' AI 투자 피드백'),
          content: SingleChildScrollView(
            child: Text(
              advice,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
              softWrap: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text(' 실패'),
          content: Text('Gemini 피드백 요청에 실패했습니다.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: const Text(
          "투자 기록",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 85, 85, 85),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryBox(),
                const Divider(),
                Expanded(child: _buildTradeList()),
              ],
            ),
    );
  }

  Widget _buildSummaryBox() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              " 수익률: ${roi.toStringAsFixed(2)}%",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: roi >= 0 ? Colors.green : Colors.red,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _askGeminiForAdvice,
            label: const Text("AI 조언 받기"),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeList() {
    return ListView.builder(
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        return ListTile(
          leading: Text(
            trade['symbol'],
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          title: Text(
            "수량: ${trade['quantity']}",
            style: TextStyle(color: Colors.purpleAccent),
          ),
          subtitle: Text(
            "매수: \$${trade['average_price']} / 현재가: \$${trade['current_price']}",
            style: TextStyle(color: Colors.white),
          ),
          trailing: Text(
            " 평가액: \$${trade['total_value']}",
            style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        );
      },
    );
  }
}
