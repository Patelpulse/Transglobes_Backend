import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _useMobileAuth = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    super.dispose();
  }

  bool _isValid() {
    final password = _passwordController.text.trim();
    if (password.length < 6) return false;

    if (_isLogin) {
      return _useMobileAuth
          ? _isValidMobile(_mobileController.text.trim())
          : _isValidEmail(_emailController.text.trim());
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) return false;
    if (_useMobileAuth) return _isValidMobile(_mobileController.text.trim());

    final email = _emailController.text.trim();
    final aadhar = _aadharController.text.trim();
    final pan = _panController.text.trim();
    if (!_isValidEmail(email)) return false;
    if (aadhar.length < 8 || pan.length < 6) return false;

    return true;
  }

  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  bool _isValidMobile(String value) {
    return RegExp(r'^\d{10}$').hasMatch(value.trim());
  }

  String _extractUserId(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is Map<String, dynamic>) {
      return (user['id'] ?? user['_id'] ?? user['uid'] ?? '').toString();
    }
    return '';
  }

  // Handles login and registration using backend APIs
  Future<void> _submit() async {
    if (!_isValid()) {
      setState(() {
        _errorMessage = _isLogin
            ? (_useMobileAuth
                ? 'Please enter valid 10-digit mobile and password.'
                : 'Please enter valid email and password.')
            : (_useMobileAuth
                ? 'Please enter valid name, mobile and password.'
                : 'Please enter valid name, email, password, Aadhaar and PAN.');
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);

      final password = _passwordController.text.trim();

      if (_isLogin) {
        final response = _useMobileAuth
            ? await authService.signInWithMobileCustom(
                mobileNumber: _mobileController.text.trim(),
                password: password,
              )
            : await authService.signInCustom(
                _emailController.text.trim(),
                password,
              );
        if (response['success']) {
          final isComplete = await dbService.isOnboardingComplete(
            _extractUserId(response),
            (response['token'] ?? '').toString(),
          );
          if (mounted) {
            setState(() => _isLoading = false);
            if (isComplete) {
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
        } else {
          setState(() {
            _errorMessage = response['message'];
            _isLoading = false;
          });
        }
      } else {
        final name = _nameController.text.trim();
        final response = _useMobileAuth
            ? await authService.signUpWithMobileCustom(
                name: name,
                mobileNumber: _mobileController.text.trim(),
                password: password,
              )
            : await authService.signUpCustom(
                name: name,
                email: _emailController.text.trim(),
                password: password,
                aadharCard: _aadharController.text.trim(),
                panCard: _panController.text.trim(),
              );

        if (response['success']) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! 🎉'),
                backgroundColor: AppTheme.neonGreen,
              ),
            );
            final isComplete = await dbService.isOnboardingComplete(
              _extractUserId(response),
              (response['token'] ?? '').toString(),
            );
            if (isComplete) {
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
        } else {
          final message = (response['message'] ?? '').toString();
          final normalizedMessage = message.toLowerCase();
          if (normalizedMessage.contains('already registered') ||
              normalizedMessage.contains('already in use') ||
              normalizedMessage.contains('already exists')) {
            final isMobileIssue = normalizedMessage.contains('mobile');
            setState(() {
              _errorMessage = isMobileIssue
                  ? 'Mobile number already registered. Please use another mobile number.'
                  : 'Email already registered. Please login with your credentials.';
              _isLogin = true;
              _isLoading = false;
            });
            return;
          }
          setState(() {
            _errorMessage =
                message.isNotEmpty ? message : 'Registration failed';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // ── Google Sign-In (Backend Driver API) ───────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final response = await authService.signInWithGoogleCustom();
      if (!(response['success'] == true)) {
        throw Exception((response['message'] ?? 'Google sign-in failed').toString());
      }
      final isComplete = await dbService.isOnboardingComplete(
        _extractUserId(response),
        (response['token'] ?? '').toString(),
      );

      if (mounted) {
        final user = (response['user'] as Map<String, dynamic>?) ?? const {};
        final userName = (user['name'] ?? 'Driver').toString();
        if (isComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, $userName! 🎉'),
              backgroundColor: AppTheme.neonGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pushReplacementNamed(context, AppRouter.home);
        } else {
          Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -110,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.08),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface.withOpacity(0.94),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.darkDivider.withOpacity(0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.30),
                          blurRadius: 42,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Logo ───────────────────────────────────────────────────────
                          Center(
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AppTheme.onlineGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.directions_car,
                                  color: Colors.white, size: 40),
                            ),
                          ),
                          const SizedBox(height: 28),

                          Center(
                            child: Text(
                              _isLogin ? 'Welcome Back!' : 'Join the Fleet',
                              style: const TextStyle(
                                color: AppTheme.darkTextPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              _isLogin
                                  ? 'Login to continue your journey'
                                  : 'Register and start earning today',
                              style: const TextStyle(
                                  color: AppTheme.darkTextSecondary,
                                  fontSize: 15),
                            ),
                          ),
                          const SizedBox(height: 36),

                          // ── Login / Sign Up Toggle ─────────────────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _tab(
                                    'Login',
                                    _isLogin,
                                    () => setState(() {
                                          _isLogin = true;
                                        })),
                                _tab(
                                    'Sign Up',
                                    !_isLogin,
                                    () => setState(() {
                                          _isLogin = false;
                                        })),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                _tab(
                                  'Email',
                                  !_useMobileAuth,
                                  () => setState(() => _useMobileAuth = false),
                                ),
                                _tab(
                                  'Mobile',
                                  _useMobileAuth,
                                  () => setState(() => _useMobileAuth = true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isLogin) ...[
                            _buildTextField(
                              'Full Name',
                              _nameController,
                              Icons.person_outline,
                              onChanged: (_) => setState(() {}),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (!_useMobileAuth) ...[
                            _buildTextField(
                              'Email',
                              _emailController,
                              Icons.email_outlined,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                          ],
                          if (_useMobileAuth) ...[
                            _buildTextField(
                              'Mobile Number',
                              _mobileController,
                              Icons.phone_outlined,
                              keyboardType: TextInputType.number,
                              maxLength: 10,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (!_isLogin && !_useMobileAuth) ...[
                            _buildTextField(
                              'Aadhaar Number',
                              _aadharController,
                              Icons.badge_outlined,
                              keyboardType: TextInputType.text,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              'PAN Number',
                              _panController,
                              Icons.credit_card_outlined,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                          ],
                          _buildTextField(
                            'Password',
                            _passwordController,
                            Icons.lock_outline,
                            isPassword: true,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading || !_isValid() ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.neonGreen,
                                foregroundColor: AppTheme.darkBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                disabledBackgroundColor: AppTheme.darkDivider,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.darkBg,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),

                          // ── Error Message ──────────────────────────────────────────────
                          if (_errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        Colors.red.shade700.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_errorMessage!,
                                        style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ── Divider ────────────────────────────────────────────────────
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: AppTheme.darkDivider)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color: AppTheme.darkTextSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: AppTheme.darkDivider)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: AppTheme.darkDivider.withOpacity(0.6),
                                  width: 1.5,
                                ),
                                backgroundColor: AppTheme.darkSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isGoogleLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.neonGreen,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _googleIcon(),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Continue with Google',
                                          style: TextStyle(
                                            color: AppTheme.darkTextPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _tab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.neonGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? AppTheme.darkBg : AppTheme.darkTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(color: AppTheme.darkTextPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.darkTextSecondary),
        prefixIcon: Icon(icon, color: AppTheme.darkTextSecondary),
        filled: true,
        fillColor: AppTheme.darkSurface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(2),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
