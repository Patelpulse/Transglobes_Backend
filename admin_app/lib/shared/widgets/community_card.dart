import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'network_avatar.dart';

class CommunityCard extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final String subtitle;
  final VoidCallback onView;
  final VoidCallback onChat;
  final VoidCallback onDelete;
  final Color? avatarBorderColor;
  final Widget? trailingAction;

  const CommunityCard({
    super.key,
    this.imageUrl,
    required this.name,
    required this.subtitle,
    required this.onView,
    required this.onChat,
    required this.onDelete,
    this.avatarBorderColor,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Premium dark surface
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Section: Avatar + Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkAvatarBox(
                imageUrl: imageUrl,
                name: name,
                size: 60,
                shape: BoxShape.circle,
                borderColor: avatarBorderColor ?? AppTheme.primaryColor,
                borderWidth: 2,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (trailingAction != null) trailingAction!,
            ],
          ),
          const SizedBox(height: 20),
          // Action Buttons
          Row(
            children: [
              // Chat Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: onChat,
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text(
                    "Chat",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135BEC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // View Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text(
                    "View",
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Color(0xFFF43F5E), size: 20),
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
