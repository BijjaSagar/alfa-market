import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/strategy_service.dart';
import '../widgets/add_strategy_sheet.dart';

class StrategyScreen extends StatefulWidget {
  const StrategyScreen({super.key});

  @override
  State<StrategyScreen> createState() => _StrategyScreenState();
}

class _StrategyScreenState extends State<StrategyScreen> {
  final _strategyService = StrategyService();
  List<Strategy> _strategies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    setState(() => _isLoading = true);
    final strategies = await _strategyService.getStrategies();
    setState(() {
      _strategies = strategies;
      _isLoading = false;
    });
  }

  Future<void> _deleteStrategy(String id) async {
    await _strategyService.deleteStrategy(id);
    _loadStrategies();
  }

  void _showAddStrategySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddStrategySheet(
        onStrategyAdded: _loadStrategies,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        title: Text('Active Strategies', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: const Color(0xFF050505),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2979FF)))
          : _strategies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 64, color: Colors.grey[800]),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Strategies',
                        style: GoogleFonts.inter(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _strategies.length,
                  itemBuilder: (context, index) {
                    final strategy = _strategies[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF2979FF).withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2979FF).withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2979FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.bolt, color: Color(0xFF2979FF)),
                        ),
                        title: Text(
                          strategy.symbol,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildTag('Fast: ${strategy.fastPeriod}', Colors.orange),
                                const SizedBox(width: 8),
                                _buildTag('Slow: ${strategy.slowPeriod}', Colors.purple),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quantity: ${strategy.quantity}',
                              style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.power_settings_new, color: Color(0xFFFF1744)),
                          onPressed: () => _deleteStrategy(strategy.id),
                        ),
                      ),
                    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2, end: 0);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStrategySheet,
        backgroundColor: const Color(0xFF2979FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('NEW BOT', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
