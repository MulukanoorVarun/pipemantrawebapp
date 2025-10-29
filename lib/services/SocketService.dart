import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/network/api_config.dart';
import '../utils/AppLogger.dart';

class SocketService {
  static IO.Socket? _socket;

  static IO.Socket connect(String userId) {
    if (_socket == null) {
      _socket = IO.io(ApiConfig.socket_url, <String, dynamic>{
        'transports': ['websocket', 'polling'],
        'autoConnect': true,
        'query': {
          'userId': userId, // 👈 passed here
        },
      });

      _socket!.connect();

      _socket!
        ..onConnect((_) => AppLogger.info('Socket connected'))
        ..onDisconnect((_) => AppLogger.info('Socket disconnected'))
        ..onError((err) => AppLogger.info('Socket error: $err'));
    }
    return _socket!;
  }

  static void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
