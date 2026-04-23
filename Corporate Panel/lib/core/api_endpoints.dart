class ApiEndpoints {
  ApiEndpoints._();

  // Corporate auth endpoints (Postman collection aligned)
  static const String corporateEmailSignup = '/api/auth/corporate/signup';
  static const String corporateEmailLogin = '/api/auth/corporate/login';
  static const String corporateMobileSignup =
      '/api/auth/corporate/mobile-signup';
  static const String corporateMobileLogin = '/api/auth/corporate/mobile-login';
  static const String corporateGoogleAuth = '/api/auth/corporate/google-auth';
  static const String corporateProfile = '/api/auth/corporate/profile';
  static const String authProfile = '/api/auth/profile';

  // Legacy fallback endpoints
  static const String corporateLegacySignup = '/api/corporate/signup';
  static const String corporateLegacyLogin = '/api/corporate/login';
  static const String corporateLegacyMobileSignup =
      '/api/corporate/mobile-signup';
  static const String corporateLegacyMobileLogin =
      '/api/corporate/mobile-login';
  static const String corporateLegacyGoogleAuth = '/api/corporate/google-auth';
}
