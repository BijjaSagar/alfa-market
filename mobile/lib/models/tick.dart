class Tick {
  final String symbol;
  final double price;
  final int volume;
  final int timestamp;

  Tick({
    required this.symbol,
    required this.price,
    required this.volume,
    required this.timestamp,
  });

  factory Tick.fromJson(Map<String, dynamic> json) {
    return Tick(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      volume: json['volume'] as int,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'price': price,
      'volume': volume,
      'timestamp': timestamp,
    };
  }
}
