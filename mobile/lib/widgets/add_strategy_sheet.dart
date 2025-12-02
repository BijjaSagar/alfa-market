import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/strategy_service.dart';

class AddStrategySheet extends StatefulWidget {
  final VoidCallback onStrategyAdded;

  const AddStrategySheet({super.key, required this.onStrategyAdded});

  @override
  State<AddStrategySheet> createState() => _AddStrategySheetState();
}

class _AddStrategySheetState extends State<AddStrategySheet> {
  final _symbolController = TextEditingController(text: 'RELIANCE');
  final _fastPeriodController = TextEditingController(text: '20');
  final _slowPeriodController = TextEditingController(text: '50');
  final _quantityController = TextEditingController(text: '10');
  final _strategyService = StrategyService();
  bool _isLoading = false;

  void _createStrategy() async {
    setState(() => _isLoading = true);
    
    final success = await _strategyService.createStrategy(
      symbol: _symbolController.text,
      fastPeriod: int.tryParse(_fastPeriodController.text) ?? 20,
      slowPeriod: int.tryParse(_slowPeriodController.text) ?? 50,
      quantity: int.tryParse(_quantityController.text) ?? 10,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        widget.onStrategyAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Strategy Started')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to Start Strategy')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Strategy',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _symbolController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Symbol'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _fastPeriodController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Fast SMA'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _slowPeriodController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Slow SMA'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Quantity'),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _createStrategy,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'START STRATEGY',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
