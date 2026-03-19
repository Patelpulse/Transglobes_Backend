import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/logistics_booking.dart';

final logisticsBookingsProvider = Provider<List<LogisticsBooking>>((ref) {
  return [
    LogisticsBooking(
      id: '1',
      userName: 'Gaurav',
      pickupName: 'Mumbai Port Area',
      dropName: 'Surat Central Warehouse',
      modeOfTravel: 'Train',
      price: 12000,
      status: LogisticsBookingStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    LogisticsBooking(
      id: '2',
      userName: 'Gaurav',
      pickupName: 'Delhi International Airport',
      dropName: 'Mumbai Airport Terminal 2',
      modeOfTravel: 'Flight',
      price: 25000,
      status: LogisticsBookingStatus.processing,
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
    ),
    LogisticsBooking(
      id: '3',
      userName: 'Rahul Sharma',
      pickupName: 'Singapore Sea Port',
      dropName: 'Chennai Container Terminal',
      modeOfTravel: 'Sea',
      price: 150000,
      status: LogisticsBookingStatus.inTransit,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    LogisticsBooking(
      id: '4',
      userName: 'Gaurav',
      pickupName: 'Ahmedabad Junction',
      dropName: 'Pune Railway Station',
      modeOfTravel: 'Train',
      price: 8500,
      status: LogisticsBookingStatus.completed,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    LogisticsBooking(
      id: '5',
      userName: 'Vivek Singh',
      pickupName: 'Dubai Heliport',
      dropName: 'Mumbai High Complex',
      modeOfTravel: 'Flight',
      price: 45000,
      status: LogisticsBookingStatus.delayed,
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    ),
  ];
});

final filteredLogisticsBookingsProvider = Provider.family<List<LogisticsBooking>, LogisticsBookingStatus?>((ref, status) {
  final allBookings = ref.watch(logisticsBookingsProvider);
  if (status == null) return allBookings;
  return allBookings.where((b) => b.status == status).toList();
});
