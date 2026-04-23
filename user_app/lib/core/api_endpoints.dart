class ApiEndpoints {
  ApiEndpoints._();
}

class AuthEndpoints {
  AuthEndpoints._();

  static const String userSignup = '/api/auth/user/signup';
  static const String userLogin = '/api/auth/user/login';
  static const String userMobileSignup = '/api/auth/user/mobile-signup';
  static const String userMobileLogin = '/api/auth/user/mobile-login';
  static const String profile = '/api/auth/profile';
  static const String userFcmToken = '/api/user/fcm-token';
}

class RideEndpoints {
  RideEndpoints._();

  static String rides(String suffix) => '/api/rides$suffix';
  static String rideLegacy(String suffix) => '/api/ride$suffix';
  static String payRide(String rideId) => '/api/ride/rides/$rideId/pay';
  static const String createRideRequestLegacy = '/api/ride/ride-request';
  static const String rideTypes = '/api/rides/vehicles';
  static const String rideTypesLegacy = '/api/ride/ride-types';
}

class LogisticsEndpoints {
  LogisticsEndpoints._();

  static const String calculateFare = '/api/user/calculate-fare';
  static const String book = '/api/logistics/book';
  static const String bookingsLegacy = '/api/logistics-bookings';
  static String history(String userId) =>
      '/api/logistics/history?userId=${Uri.encodeQueryComponent(userId)}';
  static String userBookingsLegacy(String userId) =>
      '/api/logistics-bookings/user/$userId';
  static const String goodsUploadImage = '/api/logistic-goods/upload-image';
  static const String goods = '/api/logistic-goods';
  static const String vehicles = '/api/logistics-vehicles';
  static const String typeGood = '/api/typegood';
}

class MapsEndpoints {
  MapsEndpoints._();

  static String autocomplete({
    required String input,
    required String apiKey,
  }) =>
      '/api/maps/autocomplete?input=${Uri.encodeComponent(input)}&key=$apiKey&components=country:in';

  static String details({
    required String placeId,
    required String apiKey,
  }) =>
      '/api/maps/details?place_id=$placeId&key=$apiKey&fields=geometry';

  static String geocode({
    required String lat,
    required String lng,
    required String apiKey,
  }) =>
      '/api/maps/geocode?latlng=$lat,$lng&key=$apiKey';

  static String directions({
    required String origin,
    required String destination,
    required String apiKey,
  }) =>
      '/api/maps/directions?origin=$origin&destination=$destination&key=$apiKey';
}
