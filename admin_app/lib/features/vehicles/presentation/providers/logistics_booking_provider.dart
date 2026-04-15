import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/logistics_booking.dart';
import '../../data/repositories/logistics_booking_repository.dart';
import '../../../../core/network/dio_provider.dart';

final logisticsBookingRepoProvider = Provider<LogisticsBookingRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return LogisticsBookingRepository(dio);
});

final logisticsBookingsProvider = FutureProvider<List<LogisticsBooking>>((ref) async {
  final repo = ref.watch(logisticsBookingRepoProvider);
  return repo.getAllBookings();
});

final filteredLogisticsBookingsProvider = Provider.family<AsyncValue<List<LogisticsBooking>>, LogisticsBookingStatus?>((ref, status) {
  final bookingsAsync = ref.watch(logisticsBookingsProvider);
  
  return bookingsAsync.whenData((allBookings) {
    if (status == null) return allBookings;
    return allBookings.where((b) => b.status == status).toList();
  });
});

/// Bookings in supervisor "ACTIVE" pipeline (aligned with backend lifecycle).
final logisticsBookingsActivePipelineProvider =
    Provider<AsyncValue<List<LogisticsBooking>>>((ref) {
  final async = ref.watch(logisticsBookingsProvider);
  return async.whenData(
    (all) => all.where((b) => b.status.isActivePipeline).toList(),
  );
});
