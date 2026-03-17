import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_model.dart';
import 'api_service.dart';

final rideServiceProvider = Provider<RideService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return RideService(apiService);
});

final myRidesProvider = FutureProvider<List<RideModel>>((ref) async {
  final rideService = ref.watch(rideServiceProvider);
  return rideService.getMyRides();
});

class RideService {
  final ApiService _apiService;

  RideService(this._apiService);

  Future<RideModel> createRide({
    required List<double> pickupCoordinates,
    required List<double> dropoffCoordinates,
    required String pickupAddress,
    required String dropoffAddress,
    required String serviceType,
    required double fareEstimation,
    required double distance,
    required double duration,
    bool isScheduled = false,
    DateTime? scheduledTime,
    String? vehicleType,
    String? typeOfGood,
  }) async {
    final response = await _apiService.post('/rides', {
      'pickupLocation': {'coordinates': pickupCoordinates},
      'dropoffLocation': {'coordinates': dropoffCoordinates},
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'serviceType': serviceType,
      'fareEstimation': fareEstimation,
      'distance': distance,
      'duration': duration,
      'isScheduled': isScheduled,
      if (scheduledTime != null)
        'scheduledTime': scheduledTime.toIso8601String(),
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (typeOfGood != null) 'typeOfGood': typeOfGood,
    });
    return RideModel.fromJson(response);
  }

  Future<RideModel> createRideRequest({
    required Map<String, dynamic> locations,
    required String rideMode,
    required double fare,
    String? distance,
    String? paymentMode,
    String? vehicleType,
    String? typeOfGood,
    int? helperCount,
    List<Map<String, dynamic>>? logisticItems,
  }) async {
    final response = await _apiService.post('/ride-request', {
      'locations': locations,
      'rideMode': rideMode,
      'fare': fare,
      if (distance != null) 'distance': distance,
      if (paymentMode != null) 'paymentMode': paymentMode,
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (typeOfGood != null) 'typeOfGood': typeOfGood,
      if (helperCount != null) 'helperCount': helperCount,
      if (logisticItems != null) 'logisticItems': logisticItems,
    });
    return RideModel.fromJson(response['data'] ?? response);
  }

  Future<List<RideModel>> getMyRides() async {
    final response = await _apiService.get('/rides/my-rides');
    return (response as List).map((e) => RideModel.fromJson(e)).toList();
  }

  Future<RideModel?> getRideById(String rideId) async {
    final response = await _apiService.get('/rides/$rideId');
    return response != null ? RideModel.fromJson(response) : null;
  }

  Future<RideModel> updateRideStatus(
    String rideId,
    String status, {
    String? delayReason,
  }) async {
    final response = await _apiService.put('/rides/$rideId/status', {
      'status': status,
      if (delayReason != null) 'delayReason': delayReason,
    });
    return RideModel.fromJson(response);
  }

  Future<RideModel> cancelRide(String rideId) async {
    return updateRideStatus(rideId, 'cancelled');
  }

  Future<Map<String, dynamic>> updateFare(String rideId, int extraFare) async {
    final response = await _apiService.put('/api/ride/update-fare', {
      'rideId': rideId,
      'extraFare': extraFare,
    });
    return response;
  }

  Future<void> submitReview({
    required String bookingId,
    required String driverId,
    required int rating,
    required String comment,
  }) async {
    await _apiService.post('/api/ride/review', {
      'bookingId': bookingId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
    });
  }
}
