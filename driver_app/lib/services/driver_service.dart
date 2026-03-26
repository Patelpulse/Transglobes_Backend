import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/driver_model.dart';
import '../models/booking_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'database_service.dart';
import 'socket_service.dart';

final driverServiceProvider = Provider<DriverService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final socketService = ref.watch(socketServiceProvider);
  return DriverService(apiService, authService, socketService, ref);
});

final driverProfileProvider = FutureProvider<DriverModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final dbService = ref.watch(databaseServiceProvider);
  final driverId = authService.currentUser?.uid;
  if (driverId == null) return null;
  final token = await authService.getIdToken();
  if (token == null) return null;
  return await dbService.getDriverProfile(driverId, token);
});

class DriverService {
  final ApiService _api;
  final AuthService _auth;
  final SocketService _socket;
  final Ref _ref;
  late final DatabaseReference _locationRef;
  StreamSubscription<Position>? _positionSub;

  DriverService(this._api, this._auth, this._socket, this._ref) {
    _locationRef = FirebaseDatabase.instance.ref("drivers");
  }

  // --- Location Streaming ---
  Future<void> setOnline(bool online) async {
    final driverId = _auth.currentUser?.uid;
    if (driverId == null) return;

    if (online) {
      await _locationRef.child(driverId).update({'status': 'online'});
      await _api.put('/api/driver/status', {'status': 'active', 'isOnline': true});
      _startLocationStream(driverId);
    } else {
      await _locationRef.child(driverId).update({'status': 'offline'});
      await _api.put('/api/driver/status', {'status': 'offline', 'isOnline': false});
      _stopLocationStream();
    }
  }

  void _startLocationStream(String driverId) {
    _stopLocationStream();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
        distanceFilter: 2, // 2 meters for smoother tracking
      ),
    ).listen((pos) {
      // 1. Update Firebase RD (Already there)
      _locationRef.child(driverId).update({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'heading': pos.heading,
        'lastUpdate': DateTime.now().toIso8601String(),
      });

      // 2. Update via Socket.io if there's an active booking
      try {
        final activeBooking = _ref.read(currentActiveBookingProvider);
        if (activeBooking != null && 
            ['on_the_way', 'arrived', 'ongoing'].contains(activeBooking.status)) {
          _socket.updateLocation(
            rideId: activeBooking.id,
            userId: activeBooking.userId ?? '',
            latitude: pos.latitude,
            longitude: pos.longitude,
            heading: pos.heading,
          );
        }
      } catch (e) {
        debugPrint("Error sending socket location update: $e");
      }
    });
  }

  void _stopLocationStream() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  // --- Ride Status Management ---
  Future<void> updateRideStatus(String rideId, String status) async {
    await _api.put('/api/ride/rides/$rideId/status', {
      'status': status,
      'driverId': _auth.currentUser?.uid,
    });
  }

  Future<void> acceptRide(String rideId, {double? fare}) async {
    final driverId = _auth.currentUser?.uid;
    await _api.put('/api/ride/rides/$rideId/assign', {
      'driverId': driverId,
      if (fare != null) 'fare': fare,
    });
  }

  Future<void> rejectRide(String rideId) async {
    final driverId = _auth.currentUser?.uid;
    await _api.put('/api/ride/rides/$rideId/reject', {'driverId': driverId});
  }

  // --- New Logistics Booking APIs ---
  Future<void> acceptBooking(String id) async {
    try {
      await _api.patch('/api/booking/$id/accept', {});
      debugPrint('>>> Logistics booking $id accepted successfully');
    } catch (e) {
      debugPrint('>>> Error accepting logistics booking: $e');
      rethrow;
    }
  }

  Future<void> rejectBooking(String id) async {
    try {
      await _api.patch('/api/booking/$id/reject', {});
      debugPrint('>>> Logistics booking $id rejected successfully');
    } catch (e) {
      debugPrint('>>> Error rejecting logistics booking: $e');
      rethrow;
    }
  }

  Future<void> completeRide(String rideId, double actualFare) async {
    await _api.put('/api/ride/rides/$rideId/complete', {
      'status': 'completed',
      'actualFare': actualFare,
      'driverId': _auth.currentUser?.uid,
    });
  }

  // --- Statistics ---
  Future<Map<String, dynamic>> getDriverStats() async {
    final res = await _api.get('/api/driver/stats');
    return res.data;
  }

  // --- Fetch Bookings ---
  Future<List<BookingModel>> getDriverBookings() async {
    final List<BookingModel> results = [];

    // 1. Fetch regular ride bookings
    try {
      final res = await _api.get('/api/ride/driver-bookings');
      if (res != null) {
        final List bookings = res['bookings'] ?? [];
        results.addAll(bookings.map((e) => BookingModel.fromJson(e)));
      }
    } catch (e) {
      debugPrint('Error fetching regular driver bookings: $e');
    }

    // 2. Fetch pending logistics bookings dispatched to all drivers
    try {
      final res = await _api.get('/api/driver/pending-bookings');
      if (res != null) {
        final List bookings = res['bookings'] ?? [];
        final logisticsBookings = bookings.map((e) => BookingModel.fromJson(e)).toList();
        // Merge, avoiding duplicates
        for (final lb in logisticsBookings) {
          if (!results.any((b) => b.id == lb.id)) {
            results.add(lb);
          }
        }
        debugPrint('>>> Fetched ${logisticsBookings.length} pending logistics bookings');
      }
    } catch (e) {
      debugPrint('Error fetching logistics pending bookings: $e');
    }

    return results;
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await updateRideStatus(id, status);
    } catch (e) {
      debugPrint('Error updating ride status: $e');
      rethrow;
    }
  }

  Future<void> verifyOtp(String rideId, String otp) async {
    try {
      await _api.put('/api/ride/rides/$rideId/verify-otp', {
        'otp': otp,
      });
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      rethrow;
    }
  }

  Future<void> updateBilling(String bookingId, {
    required double vehiclePrice,
    required double helperCost,
    required double discountAmount,
    required double totalPrice,
  }) async {
    try {
      await _api.patch('/api/logistics-bookings/$bookingId/billing', {
        'vehiclePrice': vehiclePrice,
        'helperCost': helperCost,
        'discountAmount': discountAmount,
        'totalPrice': totalPrice,
      });
    } catch (e) {
      debugPrint('Error updating billing: $e');
      rethrow;
    }
  }
}
