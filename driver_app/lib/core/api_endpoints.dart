class ApiEndpoints {
  ApiEndpoints._();

  // Driver auth endpoints (Postman collection aligned)
  static const String driverEmailSignup = '/api/auth/driver/signup';
  static const String driverEmailLogin = '/api/auth/driver/login';
  static const String driverMobileSignup = '/api/auth/driver/mobile-signup';
  static const String driverMobileLogin = '/api/auth/driver/mobile-login';
  static const String driverGoogleAuth = '/api/auth/driver/google-auth';
  static const String authProfile = '/api/auth/profile';

  // Driver endpoints
  static const String driverSync = '/api/driver/sync';
  static const String driverProfile = '/api/driver/profile';
  static const String driverStatus = '/api/driver/status';
}
