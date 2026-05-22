import 'package:signalr_netcore/signalr_client.dart';

import '../config/api_config.dart';

typedef ChatHubHandler = void Function(Map<String, dynamic> payload);

/// SignalR realtime — JoinRoom + lắng nghe ReceiveMessage (giống web).
class ChatHubService {
  HubConnection? _connection;
  final _messageListeners = <ChatHubHandler>{};

  bool get isConnected =>
      _connection?.state == HubConnectionState.Connected;

  void addMessageListener(ChatHubHandler handler) => _messageListeners.add(handler);

  void removeMessageListener(ChatHubHandler handler) => _messageListeners.remove(handler);

  Future<void> connect({
    required String accessToken,
    void Function(String status)? onStatus,
    ChatHubHandler? onReceiveMessage,
    ChatHubHandler? onMessageUpdated,
    ChatHubHandler? onMessageDeleted,
  }) async {
    await disconnect();

    _connection = HubConnectionBuilder()
        .withUrl(
          chatHubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
          ),
        )
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveMessage', (args) {
      if (args == null || args.isEmpty || args[0] is! Map) return;
      final payload = Map<String, dynamic>.from(args[0] as Map);
      onReceiveMessage?.call(payload);
      for (final listener in _messageListeners) {
        listener(payload);
      }
    });
    if (onMessageUpdated != null) {
      _connection!.on('MessageUpdated', (args) {
        if (args != null && args.isNotEmpty && args[0] is Map) {
          onMessageUpdated(Map<String, dynamic>.from(args[0] as Map));
        }
      });
    }
    if (onMessageDeleted != null) {
      _connection!.on('MessageDeleted', (args) {
        if (args != null && args.isNotEmpty && args[0] is Map) {
          onMessageDeleted(Map<String, dynamic>.from(args[0] as Map));
        }
      });
    }

    onStatus?.call('Đang kết nối...');
    await _connection!.start();
    onStatus?.call('Đã kết nối SignalR');
  }

  Future<void> joinRoom(int roomId) async {
    await _connection?.invoke('JoinRoom', args: [roomId]);
  }

  Future<void> leaveRoom(int roomId) async {
    await _connection?.invoke('LeaveRoom', args: [roomId]);
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _connection = null;
    }
  }
}
