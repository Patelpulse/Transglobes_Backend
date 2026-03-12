import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class ProfileProvider with ChangeNotifier {
  String companyName = 'Transglobe Logistics';
  String enterpriseId = 'TG_9921';
  String tier = 'Platinum';
  String email = 'admin@transglobe.log';
  String phone = '+91 98765 43210';
  String address = 'Logistics Hub, Mumbai, IN';

  void updateProfile({String? name, String? mail, String? p, String? addr}) {
    if (name != null) companyName = name;
    if (mail != null) email = mail;
    if (p != null) phone = p;
    if (addr != null) address = addr;
    notifyListeners();
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final p = Provider.of<ProfileProvider>(context, listen: false);
    _nameController = TextEditingController(text: p.companyName);
    _emailController = TextEditingController(text: p.email);
    _phoneController = TextEditingController(text: p.phone);
    _addressController = TextEditingController(text: p.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    if (_isEditing) {
      Provider.of<ProfileProvider>(context, listen: false).updateProfile(
        name: _nameController.text,
        mail: _emailController.text,
        p: _phoneController.text,
        addr: _addressController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated Successfully')));
    }
    setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    final p = Provider.of<ProfileProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.bgLow,
      appBar: AppBar(
        title: Text('CORPORATE PROFILE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? LucideIcons.check : LucideIcons.edit3, color: AppTheme.electricBlue),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(p),
            const SizedBox(height: 32),
            _buildInfoSection(p),
            const SizedBox(height: 32),
            _buildActionSection('ACCOUNT SETTINGS', [
              _buildActionItem(LucideIcons.users, 'Team Members', 'Invite and manage users'),
              _buildActionItem(LucideIcons.shieldCheck, 'Security', 'Password & 2FA'),
            ]),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              ),
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('SIGN OUT', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                elevation: 0,
                minimumSize: const Size.fromHeight(60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            Text('Version 2.4.1 Premium', style: TextStyle(color: AppTheme.slateGray.withOpacity(0.5), fontSize: 11)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileProvider p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(LucideIcons.building2, color: AppTheme.primaryBlue, size: 40),
          ),
          const SizedBox(height: 24),
          if (_isEditing)
             TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(border: InputBorder.none, hintText: 'Company Name', hintStyle: TextStyle(color: Colors.white30)),
            )
          else
            Text(p.companyName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(p.enterpriseId, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, letterSpacing: 1)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildQuickStat('TIER', p.tier),
              const SizedBox(width: 48),
              _buildQuickStat('LICENSE', 'ACTIVE'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildInfoSection(ProfileProvider p) {
    return _buildActionSection('COMPANY DETAILS', [
      _buildActionEditableItem(LucideIcons.mail, 'Official Email', _emailController, p.email),
      _buildActionEditableItem(LucideIcons.phone, 'Contact Number', _phoneController, p.phone),
      _buildActionEditableItem(LucideIcons.mapPin, 'Office Address', _addressController, p.address),
    ]);
  }

  Widget _buildActionEditableItem(IconData icon, String label, TextEditingController controller, String value) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue, size: 18),
      title: Text(label, style: const TextStyle(color: AppTheme.slateGray, fontSize: 10, fontWeight: FontWeight.bold)),
      subtitle: _isEditing 
        ? TextField(controller: controller, style: const TextStyle(fontSize: 14, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none))
        : Text(value, style: const TextStyle(fontSize: 14, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }

  Widget _buildActionSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.slateGray, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.glassBorder)),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String title, String sub) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryBlue, size: 18),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.slateGray)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.slateGray),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    );
  }
}
