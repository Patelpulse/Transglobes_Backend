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
    });
    return RideModel.fromJson(response);
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
}
