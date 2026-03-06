import 'package:equatable/equatable.dart';

enum UserType { personal, business }

enum UserStatus { active, inactive, suspended }

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? mobileNumber;
  final UserType type;
  final UserStatus status;
  final String? lastActive;
  final double walletBalance;
  final String imageUrl;
  final bool isFraudulent;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.mobileNumber,
    required this.type,
    required this.status,
    this.lastActive,
    required this.walletBalance,
    required this.imageUrl,
    this.isFraudulent = false,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['_id']?.toString() ?? map['uid']?.toString() ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      mobileNumber: map['mobileNumber']?.toString(),
      type: map['type'] == 'business' ? UserType.business : UserType.personal,
      status: _parseStatus(map['status']),
      lastActive: _formatTime(map['lastActive'] ?? map['updatedAt']),
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      imageUrl: (map['imageUrl'] != null && map['imageUrl'] != '') 
          ? map['imageUrl'] 
          : 'https://images.unsplash.com/photo-1633332755192-727a05c4013d?w=200&q=80',
      isFraudulent: map['isFraudulent'] ?? false,
    );
  }

  static String _formatTime(dynamic time) {
    if (time == null) return 'N/A';
    // If it's a string from MongoDB (ISO 8601), we can just return it or simplify
    // For now, let's just make it look clean
    if (time is String && time.length > 10) {
      try {
        final dt = DateTime.parse(time);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
        if (diff.inHours < 24) return '${diff.inHours}h ago';
        return '${diff.inDays}d ago';
      } catch (e) {
        return time.substring(0, 10);
      }
    }
    return time.toString();
  }

  static UserStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return UserStatus.active;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.inactive;
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        mobileNumber,
        type,
        status,
        lastActive,
        walletBalance,
        imageUrl,
        isFraudulent,
      ];
}

class SystemLog extends Equatable {
  final String id;
  final String title;
  final String description;
  final String timestamp;
  final String iconType;

  const SystemLog({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.iconType,
  });

  @override
  List<Object?> get props => [id, title, description, timestamp, iconType];
}
