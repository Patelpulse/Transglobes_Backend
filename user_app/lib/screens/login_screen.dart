import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import '../providers/app_providers.dart';
import 'home_screen.dart';
import 'name_input_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _otpSent = false;
  String? _verificationId;

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
    _phoneController.dispose();
    _otpController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      await authService.verifyPhoneNumber(
        phoneNumber: '+91${_phoneController.text}',
        onCodeSent: (verificationId, resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _isLoading = false;
            });
            _showSnackBar(
              kDemoMode
                  ? 'Demo Mode: Enter any 6 digits'
                  : 'OTP sent successfully!',
              isSuccess: true,
            );
          }
        },
        onVerificationFailed: (e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar('Error: ${e.message}', isSuccess: false);
          }
        },
        onVerificationCompleted: (credential) async {
          await authService.signInWithCredential(credential);
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Error: $e', isSuccess: false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.length != 6) {
      _showSnackBar('Please enter a 6-digit OTP', isSuccess: false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithPhoneCredential(
        _verificationId!,
        _otpController.text,
      );

      if (mounted) {
        if (kDemoMode) {
          ref.read(demoUserProvider.notifier).login();
        }

        // Save phone number to DB after OTP verification
        try {
          final apiService = ref.read(apiServiceProvider);
          final mobileNumber = '+91${_phoneController.text}';

          final response = await apiService.post('/api/user/register-phone', {
            'mobileNumber': mobileNumber,
          });

          final isNewUser = response['isNewUser'] == true;
          final existingName = response['user']?['name'] ?? '';

          if (isNewUser || existingName.isEmpty) {
            // First time user — navigate to Name Input Screen (mandatory)
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => NameInputScreen(mobileNumber: mobileNumber),
                ),
              );
            }
            return;
          }
        } catch (syncError) {
          debugPrint('Failed to register phone with backend: $syncError');
        }

        // Existing user with name — go directly to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar('Invalid OTP', isSuccess: false);
      }
    }
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
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

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
                          _otpSent ? 'Verify OTP' : 'Login or Sign up',
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _otpSent
                                ? 'Enter the 6-digit code sent to\n+91 ${_phoneController.text}'
                                : 'Enter your mobile number to proceed. We will send you an OTP to verify.',
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

                      if (!_otpSent) ...[
                        // Phone Number Label
                        Text(
                          'Enter your phone number',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Phone Input
                        Container(
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.theme.dividerColor.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Country Code
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: context.theme.dividerColor
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '+91',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                              ),
                              // Phone Field
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Enter your phone number',
                                    hintStyle: TextStyle(
                                      color: context.colors.textSecondary
                                          ?.withOpacity(0.5),
                                    ),
                                    counterText: '',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.length != 10) {
                                      return 'Enter a valid 10-digit number';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // OTP Input
                        _buildOtpInput(),

                        const SizedBox(height: 16),

                        // Change phone number
                        Center(
                          child: TextButton(
                            onPressed: () {
                              setState(() {
                                _otpSent = false;
                                _otpController.clear();
                              });
                            },
                            child: Text(
                              'Change phone number',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Continue / Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_otpSent ? _verifyOtp : _sendOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.theme.primaryColor,
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
                                  _otpSent ? 'Verify' : 'Continue',
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
    );
  }

  Widget _buildOtpInput() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(0.1),
            ),
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 16,
              color: context.colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '• • • • • •',
              hintStyle: TextStyle(
                fontSize: 24,
                letterSpacing: 8,
                color: context.colors.textSecondary?.withOpacity(0.5),
              ),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter 6-digit OTP',
          style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
        ),
      ],
    );
  }
}
