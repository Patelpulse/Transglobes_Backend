import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignup = false;
  bool _mobileMode = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      Map<String, dynamic> response;
      if (_mobileMode) {
        if (_isSignup) {
          response = await authService.mobileSignup(
            name: _nameController.text.trim(),
            mobileNumber: _normalizePhone(_mobileController.text),
            password: _passwordController.text.trim(),
          );
        } else {
          response = await authService.mobileLogin(
            mobileNumber: _normalizePhone(_mobileController.text),
            password: _passwordController.text.trim(),
          );
        }
      } else {
        if (_isSignup) {
          response = await authService.signup(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            mobileNumber: _normalizePhone(_mobileController.text),
          );
        } else {
          response = await authService.login(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response['success'] == true) {
        _showSnackBar(
          _isSignup ? 'Registration successful' : 'Login successful',
          isSuccess: true,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showSnackBar(
          (response['message'] ?? 'Authentication failed').toString(),
          isSuccess: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isSuccess: false);
      }
    }
  }

  String _normalizePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('91') && digits.length > 10) {
      return '+$digits';
    }
    return '+91$digits';
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? AppTheme.success : AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.theme.primaryColor;
    final cardBorder = context.theme.dividerColor.withOpacity(0.12);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -70,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withOpacity(0.08),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 470),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.theme.cardColor,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: cardBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 34,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),

                                // Illustration
                                Center(
                                  child: Image.asset(
                                    'assets/images/login_hero.png',
                                    height: 220,
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Title
                                Center(
                                  child: Text(
                                    _isSignup ? 'Create Account' : 'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Subtitle
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Text(
                                      _mobileMode
                                          ? (_isSignup
                                              ? 'Use mobile number to create your account.'
                                              : 'Login quickly using mobile number and password.')
                                          : (_isSignup
                                              ? 'Register with name, email, mobile and password.'
                                              : 'Login using your email and password.'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: context.colors.textSecondary,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _modeToggle('Email', !_mobileMode, () {
                                        setState(() => _mobileMode = false);
                                      }),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _modeToggle('Mobile', _mobileMode, () {
                                        setState(() => _mobileMode = true);
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_isSignup) ...[
                                  _buildInput(
                                    controller: _nameController,
                                    hint: 'Full name',
                                    icon: Icons.person_outline,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Name required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (!_mobileMode) ...[
                                  _buildInput(
                                    controller: _emailController,
                                    hint: 'Email address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Email required';
                                      if (!v.contains('@')) return 'Valid email required';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  if (_isSignup) ...[
                                    _buildInput(
                                      controller: _mobileController,
                                      hint: 'Mobile number (10 digits)',
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      validator: (v) {
                                        if (v == null || v.length != 10) {
                                          return 'Enter 10-digit mobile number';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ] else ...[
                                  _buildInput(
                                    controller: _mobileController,
                                    hint: 'Mobile number (10 digits)',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.length != 10) {
                                        return 'Enter 10-digit mobile number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _buildInput(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: Icons.lock_outline,
                                  obscure: true,
                                  validator: (v) {
                                    if (v == null || v.length < 6) {
                                      return 'Password must be at least 6 chars';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 32),

                                // Continue / Verify Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          context.theme.primaryColor,
                                      disabledBackgroundColor:
                                          context.theme.disabledColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Text(
                                            _isSignup ? 'Create Account' : 'Login',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 36),
                                Center(
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isSignup = !_isSignup;
                                      });
                                    },
                                    child: Text(
                                      _isSignup
                                          ? 'Already have an account? Login'
                                          : 'New user? Create account',
                                      style: TextStyle(
                                        color: context.theme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: Text(
                                    'Need help?',
                                    style: TextStyle(
                                      color: context.theme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeToggle(String label, bool active, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            active ? context.theme.primaryColor.withOpacity(0.1) : Colors.transparent,
        side: BorderSide(
          color: active ? context.theme.primaryColor : context.theme.dividerColor,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? context.theme.primaryColor : context.colors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        ),
      ),
    );
  }
}
