import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/socket_service.dart';
import '../../../auth/providers/admin_profile_provider.dart';
import '../../providers/notification_provider.dart';
import 'dart:async';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverImage;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  StreamSubscription? _messageSubscription;
  StreamSubscription? _historySubscription;
  late final SocketService _socketService;

  @override
  void initState() {
    super.initState();
    _socketService = ref.read(socketServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChat();
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _historySubscription?.cancel();
    // Also remove socket listeners manually since they are attached to the socket object directly
    _socketService.socket?.off("message_edited");
    _socketService.socket?.off("message_deleted");
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initChat() {
    final adminProfile = ref.read(adminProfileNotifierProvider).value;
    if (adminProfile == null) return;

    // Clear notifications
    ref.read(adminNotificationProvider.notifier).markAllRead();

    final socketService = ref.read(socketServiceProvider);
    socketService.connect(adminProfile.id);
    socketService.fetchHistory(adminProfile.id, widget.receiverId);

    _messageSubscription?.cancel();
    _historySubscription?.cancel();

    _messageSubscription = socketService.messageStream.listen((data) {
      if ((data['senderId'] == widget.receiverId && data['receiverId'] == adminProfile.id) ||
          (data['senderId'] == adminProfile.id && data['receiverId'] == widget.receiverId)) {
        setState(() {
          // Find if we have an optimistic version of this message
          final index = _messages.indexWhere((m) {
            if (m['_id'] == data['_id']) return true;
            if (m['_id'] == null && m['message'] == data['message'] && m['senderId'] == data['senderId']) return true;
            return false;
          });

          if (index != -1) {
            _messages[index] = data; // Update with real ID and timestamp
          } else {
            _messages.add(data);
          }
        });
        _scrollToBottom();
      }
    });

    _historySubscription = socketService.historyStream.listen((history) {
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(history);
        });
        _scrollToBottom();
      }
    });

    // Handle Edit/Delete Socket Updates - Clear old listeners first
    socketService.socket?.off("message_edited");
    socketService.socket?.off("message_deleted");

    socketService.socket?.on("message_edited", (data) {
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) => m['_id'] == data['messageId'] 
            ? { ...m, 'message': data['newMessage'], 'isEdited': true } 
            : m).toList();
        });
      }
    });

    socketService.socket?.on("message_deleted", (data) {
      if (mounted) {
        setState(() {
          _messages = _messages.map((m) => m['_id'] == data['messageId'] 
            ? { ...m, 'message': 'This message was deleted', 'isDeleted': true } 
            : m).toList();
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final adminProfile = ref.read(adminProfileNotifierProvider).value;
    if (adminProfile == null) return;

    ref.read(socketServiceProvider).sendMessage(
      adminProfile.id,
      widget.receiverId,
      _messageController.text.trim(),
      senderRole: 'admin',
      senderName: adminProfile.name,
    );

    // Optimistically add to list (Backend will emit it back, but let's feel fast)
    setState(() {
      _messages.add({
        'senderId': adminProfile.id,
        'receiverId': widget.receiverId,
        'message': _messageController.text.trim(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _editMessage(String messageId, String newText) {
    if (newText.trim().isEmpty) return;
    final socketService = ref.read(socketServiceProvider);
    socketService.socket?.emit("edit_message", {
      "messageId": messageId,
      "newMessage": newText.trim(),
      "receiverId": widget.receiverId,
    });
    // Optimistic update
    setState(() {
      _messages = _messages.map((m) => m['_id'] == messageId ? { ...m, 'message': newText.trim(), 'isEdited': true } : m).toList();
    });
  }

  void _deleteMessage(String messageId) {
    final socketService = ref.read(socketServiceProvider);
    socketService.socket?.emit("delete_message", {
      "messageId": messageId,
      "receiverId": widget.receiverId,
    });
    // Optimistic update
    setState(() {
      _messages = _messages.map((m) => m['_id'] == messageId ? { ...m, 'message': 'This message was deleted', 'isDeleted': true } : m).toList();
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp).toUtc().add(const Duration(hours: 5, minutes: 30));
      String hour = (dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString().padLeft(2, '0');
      String minute = dt.minute.toString().padLeft(2, '0');
      String period = dt.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    } catch (e) {
      return '';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProfile = ref.watch(adminProfileNotifierProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColorDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.surfaceColorDark,
              backgroundImage: widget.receiverImage != null 
                  ? NetworkImage(widget.receiverImage!) 
                  : null,
              child: widget.receiverImage == null 
                  ? Text(widget.receiverName[0].toUpperCase()) 
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Online',
                  style: TextStyle(color: AppTheme.success, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                final adminProfile = ref.read(adminProfileNotifierProvider).value;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['senderId'] == adminProfile?.id;

                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    final text = msg['message'] ?? '';
    final isDeleted = msg['isDeleted'] ?? false;
    final isEdited = msg['isEdited'] ?? false;
    final timeStr = _formatTime(msg['timestamp'] ?? msg['createdAt']);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: isMe && !isDeleted ? () => _showOptions(msg) : null,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryColor : AppTheme.surfaceColorDark,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 20),
                ),
                border: isMe ? null : Border.all(color: AppTheme.borderDark),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 15,
                  fontStyle: isDeleted ? FontStyle.italic : null,
                  decoration: isDeleted ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
              child: Text(
                "${isEdited && !isDeleted ? 'Edited • ' : ''}$timeStr",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(Map<String, dynamic> msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColorDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
            title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showEditDialog(msg);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: AppTheme.danger),
            title: const Text('Delete Message', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _deleteMessage(msg['_id']);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> msg) {
    final ctrl = TextEditingController(text: msg['message']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColorDark,
        title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new message...',
            hintStyle: TextStyle(color: AppTheme.textMutedLight),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _editMessage(msg['_id'], ctrl.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColorDark,
        border: Border(top: BorderSide(color: AppTheme.borderDark)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColorDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppTheme.textMutedLight),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
