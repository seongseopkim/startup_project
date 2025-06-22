import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_app/user_provider.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

Future<String?> sellstock({
  required int userId,
  required double cash,
  required String symbol,
  required int qty,
  required double price,
  required DateTime timestamp,
  required void Function(double newCash) updateCash,
  required void Function(Map<String, dynamic> trade) addTrade,
}) async {
  if (qty <= 0) return "수량을 선택해주세요";
  final total = qty * price;

  final response = await http.post(
    Uri.parse('http://127.0.0.1:3050/order/sell'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "user_id": userId,
      "stock_symbol": symbol,
      "quantity": qty,
      "trade_price": price,
      "trade_date": timestamp.toIso8601String(),
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    print("매도 성공! $data");

    final newCash = (data['new_balance'] as num).toDouble();
    updateCash(newCash);
    final trade = {
      'symbol': symbol,
      'qty': qty,
      'price': price,
      'timestamp': timestamp.toIso8601String(),
      'type': 'SELL',
    };
    addTrade(trade); // ← 이게 있어야 위에 정의된 함수가 실행됨

    return null;
  } else {
    print("매도 실패: ${response.statusCode} ${response.body}");
    return "매도 실패: ${response.body}";
  }
}
