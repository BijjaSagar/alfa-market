import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/order_service.dart';

class OrderSheet extends StatefulWidget {
  final String symbol;
  final double currentPrice;
  final String side; // 'BUY' or 'SELL'

  const OrderSheet({
    super.key,
    required this.symbol,
    required this.currentPrice,
    required this.side,
  });

  @override
  State<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<OrderSheet> {
  int _quantity = 1;
  bool _isLoading = false;
  final OrderService _orderService = OrderService();

  void _placeOrder() async {
    setState(() => _isLoading = true);
    
    final success = await _orderService.placeOrder(
      symbol: widget.symbol,
      side: widget.side,
      quantity: _quantity,
      price: widget.currentPrice,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context); // Close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Order Placed Successfully' : 'Failed to Place Order',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBuy = widget.side == 'BUY';
    final color = isBuy ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${isBuy ? 'Buy' : 'Sell'} ${widget.symbol}',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quantity Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantity',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (_quantity > 1) setState(() => _quantity--);
                    },
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                  ),
                  Text(
                    '$_quantity',
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() => _quantity++);
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Price Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Price (Market)',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
              Text(
                widget.currentPrice.toStringAsFixed(2),
                style: GoogleFonts.robotoMono(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _placeOrder,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Text(
                      'CONFIRM ${widget.side}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
