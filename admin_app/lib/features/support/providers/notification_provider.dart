import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/socket_service.dart';
import '../../auth/providers/admin_profile_provider.dart';
import 'dart:async';

class SupportNotification {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime time;
  bool isRead;

  SupportNotification({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  SupportNotification copyWith({bool? isRead}) {
    return SupportNotification(
      id: id,
      senderId: senderId,
      senderName: senderName,
      message: message,
      time: time,
      isRead: isRead ?? this.isRead,
    );
  }
}

class AdminNotificationNotifier extends Notifier<List<SupportNotification>> {
  StreamSubscription? _socketSubscription;

  @override
  List<SupportNotification> build() {
    _setupListener();
    return [];
  }

  void _setupListener() {
    _socketSubscription?.cancel();
    final socketService = ref.watch(socketServiceProvider);

    _socketSubscription = socketService.messageStream.listen((data) {
      final adminProfile = ref.read(adminProfileNotifierProvider).value;
      if (adminProfile == null) return;

      final receiverId = data['receiverId'];
      final senderId = data['senderId'];
      
      // If it's for us and from someone else
      if (receiverId == adminProfile.id && senderId != adminProfile.id) {
        final newNotif = SupportNotification(
          id: data['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: senderId,
          senderName: data['senderName'] ?? 'Driver',
          message: data['message'] ?? '',
          time: DateTime.now(),
        );
        state = [newNotif, ...state];
      }
    });
  }

  void markRead(String id) {
    state = state.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
  }

  void markAllRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void clear() {
    state = [];
  }
}

final adminNotificationProvider = NotifierProvider<AdminNotificationNotifier, List<SupportNotification>>(
  AdminNotificationNotifier.new,
);

final adminUnreadCountProvider = Provider<int>((ref) {
  return ref.watch(adminNotificationProvider).where((n) => !n.isRead).length;
});
