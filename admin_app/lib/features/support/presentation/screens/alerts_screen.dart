import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notification_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'chat_screen.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(adminNotificationProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      body: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (notifications.isNotEmpty) ...[
                    _buildSupportInbox(context, notifications, ref),
                    const SizedBox(height: 24),
                  ],
                  _buildMessageDetailsSection(),
                  const SizedBox(height: 16),
                  _buildTargetingSchedule(),
                  const SizedBox(height: 16),
                  _buildPerformanceStats(),
                  const SizedBox(height: 24),
                  _buildDispatchButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "9:41",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.signal_cellular_4_bar, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              const Icon(Icons.wifi, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              const Icon(Icons.battery_full, color: Colors.white, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportInbox(BuildContext context, List<SupportNotification> notifications, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            "SUPPORT INBOX",
            style: TextStyle(
              color: Color(0xFF135BEC),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.take(5).length,
          itemBuilder: (context, index) {
            final n = notifications[index];
            return ListTile(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                  receiverId: n.senderId,
                  receiverName: n.senderName,
                )));
              },
              leading: CircleAvatar(
                backgroundColor: n.isRead ? Colors.grey : Colors.blue,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(n.senderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(n.message, style: const TextStyle(color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text("${DateTime.now().difference(n.time).inMinutes}m ago", style: const TextStyle(color: Colors.grey, fontSize: 10)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF2D364A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Transglobe CMS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    "Notification Center",
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.more_vert, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: const Color(0xFF2D364A), width: 1)),
      ),
      child: Row(
        children: [
          _buildTab("Compose", true),
          _buildTab("Templates", false),
          _buildTab("Analytics", false),
          _buildTab("Logs", false),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isActive) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: isActive
            ? BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: const Color(0xFF135BEC), width: 2),
                ),
              )
            : null,
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? const Color(0xFF135BEC) : const Color(0xFF94A3B8),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageDetailsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MESSAGE DETAILS",
            style: TextStyle(
              color: Color(0xFF135BEC),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Fleet Category",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildDropdown("All Platforms"),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC).withOpacity(0.1),
                    border: Border.all(color: const Color(0xFF135BEC)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF135BEC),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Push",
                        style: TextStyle(
                          color: Color(0xFF135BEC),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2331),
                    border: Border.all(color: const Color(0xFF2D364A)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sms, color: Color(0xFF94A3B8), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        "SMS",
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Headline",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildTextField("Enter notification title..."),
          const SizedBox(height: 16),
          const Text(
            "Message Body",
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          _buildTextArea("Write your message content here..."),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2331),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Icon(Icons.expand_more, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C2331),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hint,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
    );
  }

  Widget _buildTextArea(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2331),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hint,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      ),
    );
  }

  Widget _buildTargetingSchedule() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC).withOpacity(0.05),
          border: Border.all(color: const Color(0xFF135BEC).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: Color(0xFF135BEC), size: 20),
                const SizedBox(width: 8),
                const Text(
                  "Delivery Schedule",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Send immediately",
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                Container(
                  width: 48,
                  height: 24,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF101622),
                border: Border.all(color: const Color(0xFF2D364A)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Oct 24, 2023 - 14:00 PM",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "RECENT PERFORMANCE",
            style: TextStyle(
              color: Color(0xFF135BEC),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Avg. Delivery Rate",
                  "98.2%",
                  "+0.4%",
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Avg. Open Rate",
                  "24.5%",
                  "Stable",
                  const Color(0xFF135BEC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subValue,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subValue,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF135BEC),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF135BEC).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              "Dispatch Notification",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
