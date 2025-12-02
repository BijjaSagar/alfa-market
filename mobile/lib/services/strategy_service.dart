import 'dart:convert';
import 'package:http/http.dart' as http;

class Strategy {
  final String id;
  final String symbol;
  final int fastPeriod;
  final int slowPeriod;
  final int quantity;
  final bool active;
  final int position;

  Strategy({
    required this.id,
    required this.symbol,
    required this.fastPeriod,
    required this.slowPeriod,
    required this.quantity,
    required this.active,
    required this.position,
  });

  factory Strategy.fromJson(Map<String, dynamic> json) {
    return Strategy(
      id: json['id'],
      symbol: json['symbol'],
      fastPeriod: json['fast_period'],
      slowPeriod: json['slow_period'],
      quantity: json['quantity'],
      active: json['active'],
      position: json['position'],
    );
  }
}

class StrategyService {
  // Using localhost with adb reverse
  static const String _baseUrl = 'http://localhost:8000';

  Future<List<Strategy>> getStrategies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/strategies'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Strategy.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error fetching strategies: $e');
    }
    return [];
  }

  Future<bool> createStrategy({
    required String symbol,
    required int fastPeriod,
    required int slowPeriod,
    required int quantity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/strategies'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symbol': symbol,
          'fast_period': fastPeriod,
          'slow_period': slowPeriod,
          'quantity': quantity,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error creating strategy: $e');
      return false;
    }
  }

  Future<bool> deleteStrategy(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/strategies/$id'));
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting strategy: $e');
      return false;
    }
  }
}
