import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tick.dart';

enum SocketStatus { disconnected, connecting, connected, error }

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  final _tickController = StreamController<Tick>.broadcast();
  final _statusController = StreamController<SocketStatus>.broadcast();

  Stream<Tick> get tickStream => _tickController.stream;
  Stream<SocketStatus> get statusStream => _statusController.stream;
  String lastUrl = '';

  void connect() {
    _statusController.add(SocketStatus.connecting);
    
    // Using localhost with adb reverse for all Android devices
    const host = 'localhost';
    final url = 'ws://$host:8080/stream';
    lastUrl = url;
    
    print('Connecting to $url');
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _statusController.add(SocketStatus.connected);
      
      _channel!.stream.listen(
        (message) {
          try {
            final json = jsonDecode(message);
            final tick = Tick.fromJson(json);
            _tickController.add(tick);
          } catch (e) {
            print('Error parsing tick: $e');
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _statusController.add(SocketStatus.error);
        },
        onDone: () {
          print('WebSocket Closed');
          _statusController.add(SocketStatus.disconnected);
        },
      );
    } catch (e) {
      print('Connection Error: $e');
      _statusController.add(SocketStatus.error);
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _statusController.add(SocketStatus.disconnected);
  }
}
