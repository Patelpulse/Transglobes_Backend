import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/providers/admin_profile_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../auth/domain/models/admin_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/network_avatar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _twoFactorAuth = true;
  bool _analyticsEnabled = true;

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final success = await ref
          .read(adminProfileNotifierProvider.notifier)
          .updatePhoto(bytes, image.name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? "Profile photo updated!"
                : "Failed to update photo."),
            backgroundColor: success ? AppTheme.success : AppTheme.danger,
          ),
        );
      }
    }
  }

  void _showPasswordResetDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Change Password", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField("Current Password", currentPasswordController, true),
            const SizedBox(height: 12),
            _buildTextField("New Password", newPasswordController, true),
            const SizedBox(height: 12),
            _buildTextField("Confirm New Password", confirmPasswordController, true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match!")),
                );
                return;
              }

              final result = await ref
                  .read(adminProfileNotifierProvider.notifier)
                  .changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: result['success'] ? AppTheme.success : AppTheme.danger,
                  ),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF2D364A)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primaryColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(adminProfileNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  profileAsync.when(
                    data: (profile) => _buildProfileSection(profile),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader("APP PREFERENCES"),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      "Push Notifications",
                      "Receive real-time alerts",
                      Icons.notifications,
                      _pushNotifications,
                      (val) => setState(() => _pushNotifications = val),
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 1),
                    _buildSwitchTile(
                      "Email Notifications",
                      "Monthly reports and digests",
                      Icons.email,
                      _emailNotifications,
                      (val) => setState(() => _emailNotifications = val),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader("SECURITY & PRIVACY"),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildSwitchTile(
                      "Two-Factor Authentication",
                      "Extra layer of security",
                      Icons.security,
                      _twoFactorAuth,
                      (val) => setState(() => _twoFactorAuth = val),
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 1),
                    _buildActionTile(
                      "Change Password",
                      "Update account security",
                      Icons.lock_outline,
                      onTap: _showPasswordResetDialog,
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 1),
                    _buildSwitchTile(
                      "Analytics Data",
                      "Help improve development",
                      Icons.analytics,
                      _analyticsEnabled,
                      (val) => setState(() => _analyticsEnabled = val),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSectionHeader("SYSTEM"),
                  const SizedBox(height: 12),
                  _buildSettingsCard([
                    _buildActionTile(
                      "Language",
                      "English (US)",
                      Icons.language,
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 1),
                    _buildActionTile(
                      "Currency",
                      "USD (\$)",
                      Icons.attach_money,
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 1),
                    _buildActionTile("Theme", "System Default", Icons.palette),
                  ]),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2D364A), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          const Text(
            "Settings Configuration",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Icons.help_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(AdminProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              NetworkAvatarBox(
                imageUrl: profile.profilePhoto.isNotEmpty
                    ? profile.profilePhoto
                    : "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200&q=80",
                name: profile.name,
                size: 64,
                shape: BoxShape.circle,
                borderColor: const Color(0xFF135BEC).withOpacity(0.5),
                borderWidth: 2,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135BEC).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile.role.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF135BEC),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF64748B)),
            onPressed: () {
              // Future: Edit name/email
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.3),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF135BEC),
            activeTrackColor: const Color(0xFF135BEC).withOpacity(0.4),
            inactiveThumbColor: const Color(0xFF94A3B8),
            inactiveTrackColor: const Color(0xFF1E293B),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return InkWell(
      onTap: () => ref.read(authStateProvider.notifier).logout(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withOpacity(0.1),
          border: Border.all(color: const Color(0xFFF43F5E).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout, color: Color(0xFFF43F5E), size: 20),
            SizedBox(width: 8),
            Text(
              "Log Out Account",
              style: TextStyle(
                color: Color(0xFFF43F5E),
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
