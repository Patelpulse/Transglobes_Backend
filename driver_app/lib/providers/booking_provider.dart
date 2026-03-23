import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/driver_service.dart';
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
    
    // Clean up on dispose
    ref.onDispose(() => _pollingTimer?.cancel());
    
    return [];
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      fetchBookings();
    });
  }

  // -----------------------------------------------------------------------
  // Fetch bookings from the backend
  // -----------------------------------------------------------------------
  Future<void> fetchBookings() async {
    try {
      final service = ref.read(driverServiceProvider);
      final list = await service.getDriverBookings();
      print('🔍 [DEBUG] Fetched ${list.length} bookings from backend');
      for (var b in list) {
        print('   - ID: ${b.id}, Status: ${b.status}, Type: ${b.vehicleType}');
      }
      state = list;
    } catch (e) {
      print('❗️ Error fetching bookings: $e');
    }
  }

  // -----------------------------------------------------------------------
  // Update a booking’s status locally & sync with backend
  // -----------------------------------------------------------------------
  Future<void> updateStatus(String id, String newStatus, {double? actualFare}) async {
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
    }
  }

  // Convenience helpers
  void acceptBooking(String id) => updateStatus(id, 'accepted');

  void rejectBooking(String id) async {
    // Optimistic UI: Mark as rejected locally so it moves to history tab
    state = state
        .map((b) => b.id == id ? b.copyWith(status: 'rejected') : b)
        .toList();

    try {
      final service = ref.read(driverServiceProvider);
      await service.rejectRide(id);
    } catch (e) {
      print('❗️ Error rejecting ride: $e');
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
  return ref.watch(bookingProvider).where((b) => b.status == 'pending').toList();
});

final activeBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
      ['accepted', 'on_the_way', 'arrived', 'ongoing'].contains(b.status)).toList();
});

final historyBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
      ['completed', 'cancelled', 'rejected'].contains(b.status)).toList();
});

final currentActiveBookingProvider = Provider<BookingModel?>((ref) {
  final active = ref.watch(activeBookingsProvider);
  return active.isNotEmpty ? active.first : null;
});
