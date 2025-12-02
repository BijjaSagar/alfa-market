import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:candlesticks/candlesticks.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tick.dart';
import '../widgets/order_sheet.dart';

class StockDetailScreen extends StatefulWidget {
  final String symbol;
  final double currentPrice;

  const StockDetailScreen({
    super.key,
    required this.symbol,
    required this.currentPrice,
  });

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  List<Candle> candles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCandles();
  }

  Future<void> fetchCandles() async {
    // Using localhost with adb reverse
    const host = 'localhost'; 
    final url = Uri.parse('http://$host:8081/candles?symbol=${widget.symbol}');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          candles = data.map((json) => Candle(
            date: DateTime.fromMillisecondsSinceEpoch(json['time'] * 1000),
            high: (json['high'] as num).toDouble(),
            low: (json['low'] as num).toDouble(),
            open: (json['open'] as num).toDouble(),
            close: (json['close'] as num).toDouble(),
            volume: (json['volume'] as num).toDouble(),
          )).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching candles: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.symbol,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF2979FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'NSE',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2979FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Price Header
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050505),
                  const Color(0xFF1A1A1A).withOpacity(0.5),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Price',
                      style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${widget.currentPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.show_chart, color: Color(0xFF00E676)),
                ),
              ],
            ),
          ),
          
          // Chart
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              clipBehavior: Clip.antiAlias,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2979FF)))
                  : Candlesticks(
                      candles: candles,
                    ),
            ),
          ),
          
          // Trading Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF1744).withOpacity(0.1),
                        foregroundColor: const Color(0xFFFF1744),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFFF1744)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => OrderSheet(
                            symbol: widget.symbol,
                            currentPrice: widget.currentPrice,
                            side: 'SELL',
                          ),
                        );
                      },
                      child: Text(
                        'SELL',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: const Color(0xFF00E676).withOpacity(0.5),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => OrderSheet(
                            symbol: widget.symbol,
                            currentPrice: widget.currentPrice,
                            side: 'BUY',
                          ),
                        );
                      },
                      child: Text(
                        'BUY',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
