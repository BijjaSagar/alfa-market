import 'dart:convert';
import 'package:http/http.dart' as http;

class OrderService {
  // Using localhost with adb reverse
  static const String _baseUrl = 'http://localhost:8082';

  Future<bool> placeOrder({
    required String symbol,
    required String side, // 'BUY' or 'SELL'
    required int quantity,
    required double price,
  }) async {
    final url = Uri.parse('$_baseUrl/orders');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'symbol': symbol,
          'side': side,
          'type': 'MARKET', // Default to MARKET for MVP
          'quantity': quantity,
          'price': price,
        }),
      );

      if (response.statusCode == 200) {
        print('Order placed successfully: ${response.body}');
        return true;
      } else {
        print('Failed to place order: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }
}
