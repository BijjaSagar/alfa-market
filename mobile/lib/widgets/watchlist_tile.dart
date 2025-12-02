import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/tick.dart';
import '../screens/stock_detail_screen.dart';

class WatchlistTile extends StatefulWidget {
  final Tick tick;

  const WatchlistTile({super.key, required this.tick});

  @override
  State<WatchlistTile> createState() => _WatchlistTileState();
}

class _WatchlistTileState extends State<WatchlistTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Color _flashColor = Colors.transparent;
  double _prevPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _prevPrice = widget.tick.price;
  }

  @override
  void didUpdateWidget(WatchlistTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tick.price != oldWidget.tick.price) {
      _flashColor = widget.tick.price > oldWidget.tick.price 
          ? Colors.green.withOpacity(0.3) 
          : Colors.red.withOpacity(0.3);
      _controller.forward(from: 0).then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUp = widget.tick.price >= _prevPrice;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StockDetailScreen(
                  symbol: widget.tick.symbol,
                  currentPrice: widget.tick.price,
                ),
              ),
            );
          },
          child: Container(
            color: Color.lerp(Colors.transparent, _flashColor, _controller.value),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tick.symbol,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'NSE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.tick.price.toStringAsFixed(2),
                      style: GoogleFonts.robotoMono(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isUp ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
