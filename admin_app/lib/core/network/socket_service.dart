import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'deploy_hosts.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

String _resolveSocketBaseUrl() {
  const String prodUrl = 'http://72.61.172.182:2020';
  if (isVpsDeployedWeb) {
    return kVpsApiOrigin;
  }

  return prodUrl;
}

class SocketService {
  IO.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _historyController = StreamController<List<dynamic>>.broadcast();
  IO.Socket? get socket => _socket;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<dynamic>> get historyStream => _historyController.stream;

  void connect(String userId) {
    if (_socket != null) {
      if (!(_socket!.connected)) {
        _socket!.connect();
      } else {
        _socket!.emit("register", userId);
      }
      return;
    }

    final String baseUrl = _resolveSocketBaseUrl();

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print("Socket Connected Successfully");
      _socket?.emit("register", userId);
    });

    _socket?.on("receive_message", (data) {
      print("Socket Message Received: $data");
      _messageController.add(data);
    });

    _socket?.on("chat_history", (data) {
      _historyController.add(data);
    });

    _socket?.onDisconnect((_) => print("Socket Disconnected"));
  }

  void sendMessage(String senderId, String receiverId, String message, {String senderRole = 'admin', String? senderName}) {
    _socket?.emit("send_message", {
      "senderId": senderId,
      "receiverId": receiverId,
      "message": message,
      "senderRole": senderRole,
      "senderName": senderName
    });
  }

  void fetchHistory(String userId1, String userId2) {
    _socket?.emit("fetch_history", {
      "userId1": userId1,
      "userId2": userId2
    });
  }

  void dispose() {
    _socket?.dispose();
    _messageController.close();
    _historyController.close();
  }
}
