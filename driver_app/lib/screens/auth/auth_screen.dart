import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _showEmailForm = false; // toggle for "Continue with Email"
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isFacebookLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValid() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return false;
    final isEmail = email.contains('@') && email.contains('.');
    return isEmail && password.length >= 6;
  }

  // Handles both login and registration using Firebase Auth
  Future<void> _submit() async {
    if (!_isValid()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      dynamic userCredential;
      
      if (_isLogin) {
        userCredential = await authService.signInWithEmail(email, password);
      } else {
        userCredential = await authService.signUpWithEmail(email, password);
      }
      
      if (mounted) {
        final user = userCredential.user ?? userCredential; // Handle mock user or UserCredential
        if (user != null) {
          // Save or sync driver to backend database
          final isComplete = await dbService.saveDriverToBackend(user);

          if (mounted) {
            setState(() => _isLoading = false);
            if (isComplete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back! 🎉'),
                  backgroundColor: AppTheme.neonGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
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

  // ── Google Sign-In ─────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final userCredential = await authService.signInWithGoogle();
      
      if (mounted) {
        final user = userCredential.user;
        if (user != null) {
          // Save Google user to backend database
          final isComplete = await dbService.saveDriverToBackend(user);

          if (mounted) {
            if (isComplete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${user.displayName ?? 'Driver'}! 🎉'),
                  backgroundColor: AppTheme.neonGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
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

  // ── Facebook Sign-In ───────────────────────────────────────────────────────
  Future<void> _signInWithFacebook() async {
    setState(() {
      _isFacebookLoading = true;
      _errorMessage = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      final dbService = ref.read(databaseServiceProvider);
      final userCredential = await authService.signInWithFacebook();
      
      if (mounted) {
        final user = userCredential.user;
        if (user != null) {
          // Save Facebook user to backend database
          final isComplete = await dbService.saveDriverToBackend(user);

          if (mounted) {
            if (isComplete) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${user.displayName ?? 'Driver'}! 🎉'),
                  backgroundColor: AppTheme.neonGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRouter.home);
            } else {
              Navigator.pushReplacementNamed(context, AppRouter.onboarding);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isFacebookLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

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
                      color: AppTheme.darkTextSecondary, fontSize: 15),
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
                    _tab('Login', _isLogin, () => setState(() {
                          _isLogin = true;
                          _showEmailForm = false;
                        })),
                    _tab('Sign Up', !_isLogin, () => setState(() {
                          _isLogin = false;
                          _showEmailForm = false;
                        })),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Sign Up CTA (not login tab) ────────────────────────────────
              if (!_isLogin) ...[
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Join as a partner to start earning',
                        style: TextStyle(
                            color: AppTheme.darkTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.neonGreen, width: 1.5),
                            backgroundColor: AppTheme.darkSurface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: AppTheme.neonGreen, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _googleIcon(),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'CONTINUE WITH GOOGLE',
                                      style: TextStyle(
                                          color: AppTheme.neonGreen,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Email Form (animated, shown when _showEmailForm = true) ────
              AnimatedCrossFade(
                crossFadeState: (_isLogin && _showEmailForm)
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                duration: const Duration(milliseconds: 300),
                firstChild: Column(
                  children: [
                    _buildTextField(
                      'Email',
                      _emailController,
                      Icons.email_outlined,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      'Password',
                      _passwordController,
                      Icons.lock_outline,
                      isPassword: true,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?',
                            style: TextStyle(color: AppTheme.neonGreen)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading || !_isValid() ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonGreen,
                          foregroundColor: AppTheme.darkBg,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          disabledBackgroundColor: AppTheme.darkDivider,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: AppTheme.darkBg, strokeWidth: 2))
                            : const Text('LOGIN',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
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
                        color: Colors.red.shade700.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Divider ────────────────────────────────────────────────────
              if (_isLogin) ...[
                const Row(
                  children: [
                    Expanded(child: Divider(color: AppTheme.darkDivider)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR',
                          style: TextStyle(
                              color: AppTheme.darkTextSecondary, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppTheme.darkDivider)),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Google Sign-In Button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isGoogleLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: AppTheme.darkDivider.withOpacity(0.6),
                          width: 1.5),
                      backgroundColor: AppTheme.darkSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: AppTheme.neonGreen, strokeWidth: 2))
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
                const SizedBox(height: 14),

                // ── Continue with Email Button (toggle) ────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () =>
                        setState(() => _showEmailForm = !_showEmailForm),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: _showEmailForm
                              ? AppTheme.neonGreen.withOpacity(0.6)
                              : AppTheme.darkDivider.withOpacity(0.6),
                          width: 1.5),
                      backgroundColor: _showEmailForm
                          ? AppTheme.neonGreen.withOpacity(0.08)
                          : AppTheme.darkSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showEmailForm
                              ? Icons.keyboard_arrow_up
                              : Icons.email_outlined,
                          color: _showEmailForm
                              ? AppTheme.neonGreen
                              : AppTheme.darkTextPrimary,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _showEmailForm
                              ? 'Hide Email Form'
                              : 'Continue with Email',
                          style: TextStyle(
                            color: _showEmailForm
                                ? AppTheme.neonGreen
                                : AppTheme.darkTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Other social buttons ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(Icons.apple, () {}),
                    const SizedBox(width: 16),
                    _socialButton(
                      Icons.facebook, 
                      _isFacebookLoading ? null : _signInWithFacebook,
                      isLoading: _isFacebookLoading,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ],
          ),
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
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
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
          borderSide:
              const BorderSide(color: AppTheme.neonGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, VoidCallback? onTap, {bool isLoading = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkDivider),
        ),
        child: isLoading
            ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.darkTextPrimary))
            : Icon(icon, color: AppTheme.darkTextPrimary, size: 28),
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
