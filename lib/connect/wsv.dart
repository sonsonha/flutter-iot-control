import 'package:frontend_daktmt/apis/apis_login.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class WebSocketService {
  late WebSocketChannel _channel;
  bool _isConnected = false;

  void connect(String url) {
    try {
      _channel = IOWebSocketChannel.connect(url);
      _isConnected = true;
      logger.i("WebSocket connected to $url");
    } catch (e) {
      _isConnected = false;
      logger.e("Error connecting to WebSocket: $e");
    }
  }

  Stream<dynamic> receiveMessage() {
    if (!_isConnected) {
      throw Exception("WebSocket is not connected!");
    }
    return _channel.stream;
  }

  void sendMessage(String message) {
    if (!_isConnected) {
      logger.w("WebSocket is not connected. Cannot send message.");
      return;
    }
    _channel.sink.add(message);
    logger.i("Sent: $message");
  }

  void disconnect() {
    if (_isConnected) {
      _channel.sink.close();
      _isConnected = false;
      logger.i("WebSocket connection closed.");
    }
  }
}