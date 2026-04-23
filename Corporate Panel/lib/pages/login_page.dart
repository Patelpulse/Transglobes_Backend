import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/corporate_auth_provider.dart';
import 'dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _companyNameController = TextEditingController();
  final _gstinController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _isSignupMode = false;
  bool _useMobileAuth = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstinController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final authProvider = context.read<CorporateAuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);
    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Google sign-in failed')),
      );
    }
  }

  Future<void> _handleLogin() async {
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final mobile = _mobileController.text.trim();
    final companyName = _companyNameController.text.trim();
    final gstin = _gstinController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();
    final address = _addressController.text.trim();

    if (password.isEmpty ||
        (_useMobileAuth ? mobile.isEmpty : email.isEmpty) ||
        (_isSignupMode &&
            (companyName.isEmpty ||
                gstin.isEmpty ||
                contactPhone.isEmpty ||
                address.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final authProvider = context.read<CorporateAuthProvider>();
    final bool success;

    if (_isSignupMode) {
      if (_useMobileAuth) {
        success = await authProvider.signupWithMobile(
          companyName: companyName,
          gstin: gstin,
          mobileNumber: mobile,
          contactPhone: contactPhone,
          address: address,
          password: password,
        );
      } else {
        success = await authProvider.signupWithEmail(
          companyName: companyName,
          gstin: gstin,
          email: email,
          contactPhone: contactPhone,
          address: address,
          password: password,
        );
      }
    } else {
      if (_useMobileAuth) {
        success = await authProvider.loginWithMobile(
          mobileNumber: mobile,
          password: password,
        );
      } else {
        success = await authProvider.loginWithEmail(
          email: email,
          password: password,
        );
      }
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Authentication failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Stack(
        children: [
          // Background Gradient Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.electricBlue.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.electricBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.package2,
                        size: 40,
                        color: AppTheme.electricBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Transglobe Panel',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Precision Logistics for Enterprise',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignupMode
                                ? 'Create Corporate Account'
                                : 'Welcome Back',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Sign In'),
                                  selected: !_isSignupMode,
                                  onSelected: (_) {
                                    setState(() => _isSignupMode = false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Sign Up'),
                                  selected: _isSignupMode,
                                  onSelected: (_) {
                                    setState(() => _isSignupMode = true);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Email'),
                                  selected: !_useMobileAuth,
                                  onSelected: (_) {
                                    setState(() => _useMobileAuth = false);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Mobile'),
                                  selected: _useMobileAuth,
                                  onSelected: (_) {
                                    setState(() => _useMobileAuth = true);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (_isSignupMode) ...[
                            TextField(
                              controller: _companyNameController,
                              decoration: const InputDecoration(
                                hintText: 'Company Name',
                                prefixIcon:
                                    Icon(LucideIcons.building2, size: 20),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _gstinController,
                              decoration: const InputDecoration(
                                hintText: 'GSTIN',
                                prefixIcon:
                                    Icon(LucideIcons.badgeCheck, size: 20),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_useMobileAuth)
                            TextField(
                              controller: _mobileController,
                              decoration: const InputDecoration(
                                hintText: 'Mobile Number',
                                prefixIcon:
                                    Icon(LucideIcons.smartphone, size: 20),
                              ),
                            )
                          else
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'Email Address',
                                prefixIcon: Icon(LucideIcons.mail, size: 20),
                              ),
                            ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              prefixIcon:
                                  const Icon(LucideIcons.lock, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? LucideIcons.eye
                                      : LucideIcons.eyeOff,
                                  size: 20,
                                ),
                                onPressed: () => setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                          ),
                          if (_isSignupMode) ...[
                            const SizedBox(height: 20),
                            TextField(
                              controller: _contactPhoneController,
                              decoration: const InputDecoration(
                                hintText: 'Contact Phone',
                                prefixIcon: Icon(LucideIcons.phone, size: 20),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _addressController,
                              minLines: 2,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Company Address',
                                prefixIcon: Icon(LucideIcons.mapPin, size: 20),
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleLogin,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : Text(_isSignupMode
                                    ? 'CREATE ACCOUNT'
                                    : 'SIGN IN'),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or',
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: (_isSubmitting || _isGoogleLoading)
                                ? null
                                : _handleGoogleSignIn,
                            icon: _isGoogleLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Image.network(
                                    'https://www.google.com/favicon.ico',
                                    width: 18,
                                    height: 18,
                                  ),
                            label: const Text('Continue with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignupMode
                                ? 'Google signup requires company details setup on first login.'
                                : 'Use Google if your corporate account is linked.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Partner Integration? Contact Support',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
