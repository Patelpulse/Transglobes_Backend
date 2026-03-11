import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'dart:async';

enum ChatMessageType { text, voice }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime time;
  final ChatMessageType type;
  final String? senderId;
  final String? receiverId;
  final bool isEdited;
  final bool isDeleted;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.type = ChatMessageType.text,
    this.senderId,
    this.receiverId,
    this.isEdited = false,
    this.isDeleted = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String currentUserId) {
    DateTime parsedTime = DateTime.now();
    final timeStr = map['timestamp'] ?? map['createdAt'];
    if (timeStr != null) {
      try {
        parsedTime = DateTime.parse(timeStr.toString());
      } catch (_) {}
    }

    return ChatMessage(
      id: map['_id'] ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: map['message'] ?? '',
      isUser: map['senderId'] == currentUserId,
      time: parsedTime,
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      isEdited: map['isEdited'] ?? false,
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  ChatMessage copyWith({
    String? text,
    bool? isEdited,
    bool? isDeleted,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      time: time,
      type: type,
      senderId: senderId,
      receiverId: receiverId,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ChatNotifier extends Notifier<List<ChatMessage>> {
  StreamSubscription? _messageSubscription;
  StreamSubscription? _historySubscription;
  String? _currentReceiverId;

  @override
  List<ChatMessage> build() => [];

  void initChat(String receiverId, String userId) {
    _currentReceiverId = receiverId;
    final socketService = ref.read(socketServiceProvider);
    
    socketService.connect(userId);
    socketService.fetchHistory(userId, receiverId);

    _messageSubscription?.cancel();
    _messageSubscription = socketService.messageStream.listen((data) {
      if ((data['senderId'] == receiverId && data['receiverId'] == userId) ||
          (data['senderId'] == userId && data['receiverId'] == receiverId)) {
        final newMsg = ChatMessage.fromMap(data, userId);
        
        final index = state.indexWhere((m) => m.id == newMsg.id || (m.id.startsWith('temp-') && m.text == newMsg.text));

        if (index != -1) {
          final newState = List<ChatMessage>.from(state);
          newState[index] = newMsg;
          state = newState;
        } else {
          state = [...state, newMsg];
        }
      }
    });

    _historySubscription?.cancel();
    _historySubscription = socketService.historyStream.listen((history) {
       final messages = history.map((m) => ChatMessage.fromMap(Map<String, dynamic>.from(m), userId)).toList();
       state = messages;
    });

    socketService.socket?.on("message_edited", (data) {
      final msgId = data['messageId'];
      final newText = data['newMessage'];
      state = state.map((m) => m.id == msgId ? m.copyWith(text: newText, isEdited: true) : m).toList();
    });

    socketService.socket?.on("message_deleted", (data) {
      final msgId = data['messageId'];
      state = state.map((m) => m.id == msgId ? m.copyWith(text: "This message was deleted", isDeleted: true) : m).toList();
    });
  }

  void sendMessage(String text) {
    if (_currentReceiverId == null) return;
    final userId = ref.read(authServiceProvider).currentUser?.uid;
    if (userId == null) return;

    // Try to get user name from userProfileProvider
    final userName = ref.read(userProfileProvider).value ?? 'User';

    ref.read(socketServiceProvider).sendMessage(
      userId,
      _currentReceiverId!,
      text,
      senderName: userName,
      senderRole: 'user',
    );

    final msg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      text: text,
      isUser: true,
      time: DateTime.now(),
      senderId: userId,
      receiverId: _currentReceiverId,
    );
    state = [...state, msg];
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(
  ChatNotifier.new,
);
