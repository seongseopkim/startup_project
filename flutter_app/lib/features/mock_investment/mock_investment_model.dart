class Trade {
  final String symbol;
  final bool isBuy;
  final int quantity;
  final double price;
  final DateTime timestamp;

  Trade({
    required this.symbol,
    required this.isBuy,
    required this.quantity,
    required this.price,
    required this.timestamp,
  });
}

class Portfolio {
  double cash;
  List<Trade> trades;

  Portfolio({this.cash = 1000000, List<Trade>? trades}) : trades = trades ?? [];
}
