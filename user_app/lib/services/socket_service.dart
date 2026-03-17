import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../core/config.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

class SocketService {
  IO.Socket? _socket;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _historyController = StreamController<List<dynamic>>.broadcast();
  final _rideAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _rideStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _driverLocationController = StreamController<Map<String, dynamic>>.broadcast();
  final _fareIncreasedController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionSuccessController = StreamController<Map<String, dynamic>>.broadcast();

  IO.Socket? get socket => _socket;

  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<List<dynamic>> get historyStream => _historyController.stream;
  Stream<Map<String, dynamic>> get rideAcceptedStream => _rideAcceptedController.stream;
  Stream<Map<String, dynamic>> get rideStatusStream => _rideStatusController.stream;
  Stream<Map<String, dynamic>> get driverLocationStream => _driverLocationController.stream;
  Stream<Map<String, dynamic>> get fareIncreasedStream => _fareIncreasedController.stream;
  Stream<Map<String, dynamic>> get connectionSuccessStream => _connectionSuccessController.stream;

  void connect(String userId, {String? name}) {
    if (_socket != null) {
      if (!(_socket!.connected)) {
        _socket!.connect();
      } else {
        _socket!.emit("register", {"userId": userId, "name": name ?? "User"});
      }
      return;
    }

    final baseUrl = AppConfig.apiBaseUrl;
    
    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      print("User Socket Connected: $userId");
      _socket?.emit("register", {"userId": userId, "name": name ?? "User"});
    });

    _socket?.on("connection_success", (data) {
      print("User Socket Connection Success: $data");
    });

    _socket?.on("ride_accepted", (data) {
      print("Ride Accepted Received: $data");
      _rideAcceptedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on("ride_status_update", (data) {
      print("Ride Status Update Received: $data");
      _rideStatusController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on("driver_location_update", (data) {
      _driverLocationController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on("receive_message", (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket?.on("chat_history", (data) {
      _historyController.add(List<dynamic>.from(data));
    });

    _socket?.on("fare_increased", (data) {
      print("Fare Increased: $data");
      _fareIncreasedController.add(Map<String, dynamic>.from(data));
    });

    _socket?.onDisconnect((_) => print("User Socket Disconnected"));
  }

  void sendMessage(String senderId, String receiverId, String message, {String senderRole = 'user', String? senderName}) {
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

  void joinRide(String rideId) {
    _socket?.emit("join_ride", rideId);
  }

  void dispose() {
    _socket?.dispose();
    _messageController.close();
    _rideAcceptedController.close();
    _rideStatusController.close();
    _driverLocationController.close();
  }
}
