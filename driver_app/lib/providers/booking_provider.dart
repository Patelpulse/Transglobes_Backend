import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/driver_service.dart';
import '../services/socket_service.dart';
import '../models/booking_model.dart';

// ---------------------------------------------------------------------------
// BookingNotifier – handles the full booking lifecycle
// ---------------------------------------------------------------------------
class BookingNotifier extends Notifier<List<BookingModel>> {
  Timer? _pollingTimer;

  /// Tracks IDs being optimistically updated (prevent poll from overwriting)
  final Set<String> _updatingIds = {};

  /// Tracks IDs this driver has REJECTED (prevent socket/poll from re-adding)
  final Set<String> _rejectedIds = {};

  @override
  List<BookingModel> build() {
    Future.microtask(() => fetchBookings());
    _startPolling();

    final socket = ref.watch(socketServiceProvider);

    // ── 1. New booking dispatched by admin ──────────────────────────────────
    socket.newRideStream.listen((data) {
      try {
        final booking = BookingModel.fromJson(data);
        // Don't add if this driver has already rejected it
        if (_rejectedIds.contains(booking.id)) return;
        addBooking(booking);
        print('>>> Socket: new booking received ${booking.id}');
      } catch (e) {
        print('Error parsing socket new_ride: $e');
      }
    });

    // ── 2. Another driver accepted — remove from ALL drivers' pending ────────
    socket.rideAssignedStream.listen((data) {
      // Backend emits { rideId: '...' } from acceptBooking
      // and { bookingId: '...' } from assignDriver — handle both
      final rideId = data['rideId']?.toString() ?? data['bookingId']?.toString();
      if (rideId != null) {
        // Only remove if it's in pending state for this driver
        // (if this driver accepted it, it's already in 'accepted' state — keep it)
        state = state.where((b) {
          if (b.id != rideId) return true;
          // Keep if this driver already accepted (it's their active order)
          if (['accepted', 'confirmed', 'on_the_way', 'arrived',
               'ongoing', 'in_transit'].contains(b.status)) return true;
          // Remove from pending for all other drivers
          return false;
        }).toList();
        print('>>> Socket: ride_assigned — removed $rideId from pending');
      }
    });

    ref.onDispose(() => _pollingTimer?.cancel());
    return [];
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Poll every 8 seconds for responsive updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      fetchBookings();
    });
  }

  // ─── Fetch from backend ───────────────────────────────────────────────────
  Future<void> fetchBookings() async {
    try {
      final service = ref.read(driverServiceProvider);
      final list = await service.getDriverBookings();
      print('>>> DRIVER FETCHED ${list.length} BOOKINGS');

      // Merge: keep optimistic local state for IDs being updated
      final mergedRows = list.map((remote) {
        if (_updatingIds.contains(remote.id)) {
          final local = state.where((b) => b.id == remote.id).firstOrNull;
          if (local != null) return local;
        }
        return remote;
      }).toList();

      // ── Race-condition fix ────────────────────────────────────────────────
      // Keep socket-received pending bookings that the API hasn't confirmed yet
      // BUT exclude any the driver has already rejected or accepted locally.
      final activeStatuses = {
        'accepted', 'confirmed', 'on_the_way', 'arrived', 'ongoing', 'in_transit'
      };
      final socketOnlyPending = state.where((b) {
        // Must be pending
        if (!['pending', 'pending_for_driver'].contains(b.status)) return false;
        // Must not already be in the fetched list
        if (mergedRows.any((r) => r.id == b.id)) return false;
        // Must not have been rejected by this driver
        if (_rejectedIds.contains(b.id)) return false;
        return true;
      }).toList();

      // Preserve this driver's active orders even if API doesn't return them yet
      final localActiveOrders = state.where((b) {
        if (!activeStatuses.contains(b.status)) return false;
        if (mergedRows.any((r) => r.id == b.id)) return false;
        return true;
      }).toList();

      state = [...mergedRows, ...socketOnlyPending, ...localActiveOrders];
    } catch (e) {
      print('❗️ Error fetching bookings: $e');
    }
  }

  // ─── Accept ───────────────────────────────────────────────────────────────
  Future<void> acceptBooking(String id) async {
    final b = state.where((item) => item.id == id).firstOrNull;
    if (b == null) return;

    // All vehicle types that are logistics (not regular cab/bus)
    final isLogistics = _isLogisticsBooking(b);

    _updatingIds.add(id);

    // Optimistic UI: instantly move to Active
    state = state
        .map((item) => item.id == id ? item.copyWith(status: 'accepted') : item)
        .toList();

    try {
      final service = ref.read(driverServiceProvider);
      if (isLogistics) {
        await service.acceptBooking(id);
      } else {
        await service.acceptRide(id);
      }
      print('>>> Booking $id accepted successfully');
    } catch (e) {
      print('❗️ Error accepting booking: $e');
      // Revert optimistic update on failure
      state = state
          .map((item) => item.id == id
              ? item.copyWith(status: b.status)
              : item)
          .toList();
    } finally {
      Future.delayed(const Duration(seconds: 3), () => _updatingIds.remove(id));
    }
  }

  // ─── Reject ───────────────────────────────────────────────────────────────
  Future<void> rejectBooking(String id) async {
    final b = state.where((item) => item.id == id).firstOrNull;
    if (b == null) return;

    final isLogistics = _isLogisticsBooking(b);

    // Track rejection BEFORE removing from state
    _rejectedIds.add(id);

    // Optimistic UI: instantly remove from this driver's pending list
    // Move to history as 'rejected'
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
      print('>>> Booking $id rejected successfully');
    } catch (e) {
      print('❗️ Error rejecting booking: $e');
      // If reject API fails, keep in rejected state locally (prevent re-showing)
    }
  }

  // ─── Status updates ───────────────────────────────────────────────────────
  Future<void> updateStatus(String id, String newStatus, {double? actualFare}) async {
    _updatingIds.add(id);

    state = state
        .map((b) => b.id == id ? b.copyWith(status: newStatus) : b)
        .toList();

    try {
      final service = ref.read(driverServiceProvider);
      if (newStatus == 'completed' && actualFare != null) {
        await service.completeRide(id, actualFare);
      } else {
        await service.updateRideStatus(id, newStatus);
      }
    } catch (e) {
      print('❗️ Error syncing status: $e');
    } finally {
      Future.delayed(const Duration(seconds: 3), () => _updatingIds.remove(id));
    }
  }

  void startTrip(String id) => updateStatus(id, 'ongoing');
  void completeTrip(String id, double fare) =>
      updateStatus(id, 'completed', actualFare: fare);
  void markOnTheWay(String id) => updateStatus(id, 'on_the_way');
  void markArrived(String id) => updateStatus(id, 'arrived');

  // ─── Add booking (socket push) ────────────────────────────────────────────
  void addBooking(BookingModel booking) {
    if (state.any((b) => b.id == booking.id)) return;
    if (_rejectedIds.contains(booking.id)) return; // Never re-add rejected
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
      state = state
          .map((b) => b.id == id ? b.copyWith(status: 'ongoing') : b)
          .toList();
    } catch (e) {
      print('❗️ Error verifying OTP: $e');
      rethrow;
    }
  }

  // ─── Helper ───────────────────────────────────────────────────────────────
  bool _isLogisticsBooking(BookingModel b) {
    // vehicleType is derived: 'truck' for train/flight/ship/logistics
    // subType is the raw mode uppercased
    if (b.vehicleType == 'truck') return true;
    final sub = b.subType.toLowerCase();
    return ['train', 'flight', 'ship', 'sea', 'cargo', 'logistics',
            'flatbed', 'pickup', 'container', 'sea cargo'].any(sub.contains);
  }
}

// ---------------------------------------------------------------------------
// Provider declarations
// ---------------------------------------------------------------------------
final bookingProvider =
    NotifierProvider<BookingNotifier, List<BookingModel>>(BookingNotifier.new);

/// Pending: bookings waiting for driver to accept
final pendingBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
    b.status == 'pending' ||
    b.status == 'processing' ||
    b.status == 'pending_for_driver'
  ).toList();
});

/// Active: bookings accepted and in progress
final activeBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
    ['accepted', 'on_the_way', 'arrived', 'ongoing',
     'confirmed', 'in_transit'].contains(b.status)
  ).toList();
});

/// History: completed, cancelled, rejected
final historyBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) =>
    ['completed', 'cancelled', 'rejected', 'delivered'].contains(b.status)
  ).toList();
});

final currentActiveBookingProvider = Provider<BookingModel?>((ref) {
  final active = ref.watch(activeBookingsProvider);
  return active.isNotEmpty ? active.first : null;
});
