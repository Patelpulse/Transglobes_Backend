import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/driver_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'database_service.dart';

final driverServiceProvider = Provider<DriverService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authService = ref.watch(authServiceProvider);
  return DriverService(apiService, authService);
});

final driverProfileProvider = FutureProvider<DriverModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final user = authService.currentUser;
  
  if (user != null) {
    final token = await authService.getIdToken();
    if (token != null) {
      return await dbService.getDriverProfile(user.uid, token);
    }
  }
  return null;
});

final isOnboardingCompleteProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final user = authService.currentUser;
  
  if (user != null) {
    final token = await authService.getIdToken();
    if (token != null) {
      return await dbService.isOnboardingComplete(user.uid, token);
    }
  }
  return false;
});

class DriverService {
  final ApiService _apiService;
  final AuthService _authService;
  final DatabaseReference _rtdb = FirebaseDatabase.instance.ref();

  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationTimer;
  bool _isOnline = false;

  DriverService(this._apiService, this._authService);

  Future<DriverModel?> getMyProfile() async {
    try {
      final response = await _apiService.get('/drivers/me');
      return response != null ? DriverModel.fromJson(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<DriverModel> createProfile({
    required String name,
    required String vehicleId,
  }) async {
    final response = await _apiService.post('/drivers', {
      'name': name,
      'vehicleId': vehicleId,
    });
    return DriverModel.fromJson(response);
  }

  Future<void> goOnline() async {
    _isOnline = true;

    // Update status in backend
    await _apiService.put('/drivers/me/status', {
      'status': 'available',
      'isOnline': true,
    });

    // Start streaming location to Firebase Realtime Database
    await _startLocationStream();
  }

  Future<void> goOffline() async {
    _isOnline = false;

    // Update status in backend
    await _apiService.put('/drivers/me/status', {
      'status': 'offline',
      'isOnline': false,
    });

    // Stop location streaming
    _stopLocationStream();

    // Remove from Firebase RTDB
    final userId = _authService.currentUser?.uid;
    if (userId != null) {
      await _rtdb.child('drivers/$userId').remove();
    }
  }

  Future<void> _startLocationStream() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // Start periodic location updates
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isOnline) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Update location in Firebase Realtime Database
        await _rtdb.child('drivers/$userId').set({
          'location': {'lat': position.latitude, 'lng': position.longitude},
          'status': 'available',
          'updatedAt': ServerValue.timestamp,
        });

        // Also update in MongoDB for geospatial queries
        await _apiService.put('/drivers/me/location', {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      } catch (e) {
        print('Error updating location: $e');
      }
    });
  }

  void _stopLocationStream() {
    _locationSubscription?.cancel();
    _locationTimer?.cancel();
    _locationSubscription = null;
    _locationTimer = null;
  }

  Future<void> updateStatus(String status) async {
    await _apiService.put('/drivers/me/status', {
      'status': status,
      'isOnline': status != 'offline',
    });
  }

  Future<List<dynamic>> getPendingRideRequests() async {
    return await _apiService.get('/rides/pending') ?? [];
  }

  Future<DriverModel> acceptRide(String rideId) async {
    final response = await _apiService.put('/rides/$rideId/assign', {});
    await updateStatus('busy');
    return DriverModel.fromJson(response);
  }

  Future<void> updateRideStatus(
    String rideId,
    String status, {
    String? delayReason,
  }) async {
    await _apiService.put('/rides/$rideId/status', {
      'status': status,
      if (delayReason != null) 'delayReason': delayReason,
    });
  }

  Future<void> completeRide(String rideId, double actualFare) async {
    await _apiService.put('/rides/$rideId/complete', {
      'actualFare': actualFare,
    });
    await updateStatus('available');
  }

  void dispose() {
    _stopLocationStream();
  }
}
