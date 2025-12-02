import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/socket_service.dart';
import '../models/tick.dart';
import 'stock_detail_screen.dart';
import 'strategy_screen.dart';
import '../widgets/watchlist_tile.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Map<String, Tick> _ticks = {};
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.connect();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A), // Dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: Text(
          'Market Watch',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StrategyScreen()),
              );
            },
          ),
          StreamBuilder<SocketStatus>(
            stream: _socketService.statusStream,
            initialData: SocketStatus.connecting,
            builder: (context, snapshot) {
               Color color = Colors.orange;
               if (snapshot.data == SocketStatus.connected) color = Colors.greenAccent;
               if (snapshot.data == SocketStatus.error) color = Colors.redAccent;
               return Container(
                 margin: const EdgeInsets.only(right: 16, left: 8),
                 width: 12,
                 height: 12,
                 decoration: BoxDecoration(color: color, shape: BoxShape.circle),
               );
            }
          ),
        ],
      ),
      body: StreamBuilder<Tick>(
        stream: _socketService.tickStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final tick = snapshot.data!;
            _ticks[tick.symbol] = tick;
          }

          if (_ticks.isEmpty) {
            return StreamBuilder<SocketStatus>(
              stream: _socketService.statusStream,
              initialData: SocketStatus.connecting,
              builder: (context, statusSnapshot) {
                String statusText = 'Connecting...';
                if (statusSnapshot.data == SocketStatus.error) {
                  statusText = 'Connection Error. Check Backend.';
                } else if (statusSnapshot.data == SocketStatus.disconnected) {
                  statusText = 'Disconnected';
                }
                
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 16),
                      Text(
                        statusText,
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                      if (statusSnapshot.data == SocketStatus.error)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: ElevatedButton(
                            onPressed: () => _socketService.connect(),
                            child: const Text('Retry'),
                          ),
                        )
                    ],
                  ),
                );
              },
            );
          }

          final sortedSymbols = _ticks.keys.toList()..sort();

          return ListView.separated(
            itemCount: sortedSymbols.length,
            separatorBuilder: (ctx, i) => const Divider(
              color: Color(0xFF222222),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final symbol = sortedSymbols[index];
              return WatchlistTile(tick: _ticks[symbol]!)
                  .animate()
                  .fadeIn(delay: (50 * index).ms)
                  .slideX(begin: 0.2, end: 0);
            },
          );
        },
      ),
    );
  }
}
