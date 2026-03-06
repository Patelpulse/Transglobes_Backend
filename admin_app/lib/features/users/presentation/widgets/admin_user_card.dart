import 'package:flutter/material.dart';
import '../../domain/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/community_card.dart';
import '../../../support/presentation/screens/chat_screen.dart';

class AdminUserCard extends StatelessWidget {
  final AppUser user;
  final VoidCallback onViewProfile;

  const AdminUserCard({
    super.key,
    required this.user,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityCard(
      imageUrl: user.imageUrl,
      name: user.name,
      subtitle: user.email,
      avatarBorderColor: user.status == UserStatus.active 
          ? AppTheme.success 
          : AppTheme.textMutedLight,
      onChat: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              receiverId: user.id,
              receiverName: user.name,
              receiverImage: user.imageUrl,
            ),
          ),
        );
      },
      onView: onViewProfile,
      onDelete: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColorDark,
            title: const Text('Delete User', style: TextStyle(color: Colors.white)),
            content: Text('Are you sure you want to delete ${user.name}?', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            ],
          ),
        );
      },
    );
  }
}
