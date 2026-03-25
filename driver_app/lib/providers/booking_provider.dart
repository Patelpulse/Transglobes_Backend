import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/driver_service.dart';
import '../services/socket_service.dart';
import '../models/booking_model.dart';

// ---------------------------------------------------------------------------
// BookingNotifier – handles state and backend sync
// ---------------------------------------------------------------------------
class BookingNotifier extends Notifier<List<BookingModel>> {
  Timer? _pollingTimer;

  @override
  List<BookingModel> build() {
    // Start polling immediately
    Future.microtask(() => fetchBookings());
    _startPolling();

    // Socket listeners for real-time updates
    final socket = ref.watch(socketServiceProvider);
    
    // 1. New Ride Request
    socket.newRideStream.listen((data) {
      try {
        final booking = BookingModel.fromJson(data);
        addBooking(booking);
      } catch (e) {
        print('Error parsing socket new_ride: $e');
      }
    });

    // 2. Ride Assigned (Another driver took it)
    socket.rideAssignedStream.listen((data) {
      final rideId = data['rideId']?.toString();
      if (rideId != null) {
        state = state.where((b) => b.id != rideId).toList();
      }
    });

    // Clean up on dispose
    ref.onDispose(() => _pollingTimer?.cancel());
    
    return [];
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchBookings();
    });
  }

  // -----------------------------------------------------------------------
  // Fetch bookings from the backend
  // -----------------------------------------------------------------------
  // -----------------------------------------------------------------------
  // Update a booking’s status locally & sync with backend
  // -----------------------------------------------------------------------
  final Set<String> _updatingIds = {};

  Future<void> updateStatus(String id, String newStatus, {double? actualFare}) async {
    _updatingIds.add(id);
    
    // Optimistic UI update
    state = state
        .map((b) => b.id == id ? b.copyWith(status: newStatus) : b)
        .toList();

    // Persist to backend
    try {
      final service = ref.read(driverServiceProvider);
      if (newStatus == 'completed' && actualFare != null) {
        await service.completeRide(id, actualFare);
      } else {
        await service.updateRideStatus(id, newStatus);
      }
    } catch (e) {
      print('❗️ Error syncing status: $e');
      // On error, let the next fetch fix it
    } finally {
      // Remove from updating set after a short delay to allow backend to propagate
      Future.delayed(const Duration(seconds: 2), () {
        _updatingIds.remove(id);
      });
    }
  }

  Future<void> fetchBookings() async {
    try {
      final service = ref.read(driverServiceProvider);
      final list = await service.getDriverBookings();
      print('>>> DRIVER FETCHED ${list.length} BOOKINGS: $list');
      
      // Merge: Keep local 'updating' status for any ID in _updatingIds
      final mergedRows = list.map((remote) {
        if (_updatingIds.contains(remote.id)) {
          final local = state.where((b) => b.id == remote.id).firstOrNull;
          if (local != null) return local;
        }
        return remote;
      }).toList();

      state = mergedRows;
    } catch (e) {
      print('❗️ Error fetching bookings: $e');
    }
  }

  // Convenience helpers
  Future<void> acceptBooking(String id) async {
    // Determine if it is a logistics booking or regular ride
    final b = state.where((item) => item.id == id).firstOrNull;
    bool isLogistics = b != null && b.subType.toLowerCase().contains('truck') || (b?.vehicleType == 'truck');

    // Optimistic UI update
    state = state.map((item) => item.id == id ? item.copyWith(status: 'accepted') : item).toList();

    try {
      final service = ref.read(driverServiceProvider);
      if (isLogistics) {
        await service.acceptBooking(id);
      } else {
        await service.acceptRide(id);
      }
    } catch (e) {
      print('❗️ Error accepting ride/booking: $e');
    }
  }

  void rejectBooking(String id) async {
    // Determine if it is a logistics booking or regular ride
    final b = state.where((item) => item.id == id).firstOrNull;
    bool isLogistics = b != null && b.subType.toLowerCase().contains('truck') || (b?.vehicleType == 'truck');

    // Optimistic UI: Mark as rejected locally so it moves to history tab or disappears
    state = state
        .map((item) => item.id == id ? item.copyWith(status: 'rejected') : item)
        .toList();

    try {
      final service = ref.read(driverServiceProvider);
      if (isLogistics) {
        await service.rejectBooking(id);
      } else {
        await service.rejectRide(id);
      }
    } catch (e) {
      print('❗️ Error rejecting ride/booking: $e');
    }
  }

  void startTrip(String id) => updateStatus(id, 'ongoing');
  void completeTrip(String id, double fare) =>
      updateStatus(id, 'completed', actualFare: fare);
  void markOnTheWay(String id) => updateStatus(id, 'on_the_way');
  void markArrived(String id) => updateStatus(id, 'arrived');

  // Add a new booking (used for real‑time push notifications)
  void addBooking(BookingModel booking) {
    if (state.any((b) => b.id == booking.id)) return;
    state = [booking, ...state];
  }

  void updateBookingFare(String id, double newFare) {
    state = state
        .map((b) => b.id == id ? b.copyWith(fare: newFare) : b)
        .toList();
  }

  Future<void> verifyOtp(String id, String otp) async {
    try {
      final service = ref.read(driverServiceProvider);
      await service.verifyOtp(id, otp);
      // Update state locally if successful
      state = state
          .map((b) => b.id == id ? b.copyWith(status: 'ongoing') : b)
          .toList();
    } catch (e) {
      print('❗️ Error verifying OTP: $e');
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Provider declarations
// ---------------------------------------------------------------------------
final bookingProvider =
    NotifierProvider<BookingNotifier, List<BookingModel>>(BookingNotifier.new);

final pendingBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) => b.status == 'pending' || b.status == 'processing').toList();
});

final activeBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
      ['accepted', 'on_the_way', 'arrived', 'ongoing', 'confirmed', 'in_transit'].contains(b.status)).toList();
});

final historyBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
      ['completed', 'cancelled', 'rejected', 'delivered'].contains(b.status)).toList();
});

final currentActiveBookingProvider = Provider<BookingModel?>((ref) {
  final active = ref.watch(activeBookingsProvider);
  return active.isNotEmpty ? active.first : null;
});
