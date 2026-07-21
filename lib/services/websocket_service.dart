import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/env.dart';
import 'token_service.dart';
import 'api_service.dart';

class WebSocketService {
  static final WebSocketService instance = WebSocketService._internal();
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  final _dataUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get dataUpdateStream =>
      _dataUpdateController.stream;

  final _connectionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);

  /// Call on warm app start and on foreground resume. Cancels any scheduled
  /// retry and resets the give-up counter before connecting: a backgrounded
  /// app can burn through all reconnect attempts (OS kills the socket, network
  /// flaps) and would otherwise stay dead until the process restarts.
  void ensureConnected() {
    if (_isConnected) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    connect();
  }

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await TokenService.getToken();
    if (token == null) return;

    try {
      const wsUrl = Env.wsBaseUrl;

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;

      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
          _handleMessage(data);
        },
        onError: (error) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      // Send auth as first message
      _channel!.sink.add(jsonEncode({
        'event': 'auth',
        'data': {'token': token},
      }));

      _isConnected = true;
      _connectionStatusController.add(true);
    } catch (e) {
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data.toString());
      final event = message['event'] as String?;
      final payload = message['data'] as Map<String, dynamic>?;

      if (event == 'data:update' && payload != null) {
        final type = payload['type'];
        if (type != null) {
          ApiService.cacheInterceptor.invalidate('/$type');
        }
        _dataUpdateController.add(payload);
      }
    } catch (e) {
      // Ignore malformed messages
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionStatusController.add(false);
    _channel?.sink.close();

    if (_reconnectAttempts < _maxReconnectAttempts) {
      final delay = _baseReconnectDelay * (1 << _reconnectAttempts.clamp(0, 5));
      _reconnectTimer = Timer(delay, () {
        _reconnectAttempts++;
        connect();
      });
    }
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionStatusController.add(false);
  }

  void dispose() {
    disconnect();
    _dataUpdateController.close();
    _connectionStatusController.close();
  }
}
