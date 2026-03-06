import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Demo booking data model ──
class BookingModel {
  final String id;
  final String userName;
  final String userPhone;
  final String pickupAddress;
  final String dropAddress;
  final double fare;
  final double distanceKm;
  final int etaMinutes;
  final String vehicleType;
  final String subType;
  final String status; // pending, accepted, on_the_way, arrived, started, completed, cancelled
  final DateTime createdAt;
  final String? otp;
  final double? userRating;

  const BookingModel({
    required this.id,
    required this.userName,
    required this.userPhone,
    required this.pickupAddress,
    required this.dropAddress,
    required this.fare,
    required this.distanceKm,
    required this.etaMinutes,
    required this.vehicleType,
    required this.subType,
    required this.status,
    required this.createdAt,
    this.otp,
    this.userRating,
  });

  BookingModel copyWith({String? status}) => BookingModel(
        id: id,
        userName: userName,
        userPhone: userPhone,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        fare: fare,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
        vehicleType: vehicleType,
        subType: subType,
        status: status ?? this.status,
        createdAt: createdAt,
        otp: otp,
        userRating: userRating,
      );
}

final _demoBookings = [
  BookingModel(
    id: 'B001',
    userName: 'Priya Sharma',
    userPhone: '+91 98765 43210',
    pickupAddress: 'Gaur City 2, Sector 16C, Noida',
    dropAddress: 'Pari Chowk, Greater Noida',
    fare: 180,
    distanceKm: 4.2,
    etaMinutes: 12,
    vehicleType: 'cab',
    subType: 'Sedan',
    status: 'pending',
    createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    otp: '4829',
  ),
  BookingModel(
    id: 'B002',
    userName: 'Rahul Verma',
    userPhone: '+91 87654 32109',
    pickupAddress: 'Sector 18 Metro, Noida',
    dropAddress: 'Connaught Place, New Delhi',
    fare: 450,
    distanceKm: 18.5,
    etaMinutes: 5,
    vehicleType: 'cab',
    subType: 'SUV',
    status: 'accepted',
    createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
    otp: '7341',
  ),
  BookingModel(
    id: 'B003',
    userName: 'Amit Kumar',
    userPhone: '+91 76543 21098',
    pickupAddress: 'Industrial Area, Phase 2, Gurgaon',
    dropAddress: 'Warehouse NH-48, Manesar',
    fare: 2400,
    distanceKm: 45.0,
    etaMinutes: 20,
    vehicleType: 'truck',
    subType: 'Mini Truck',
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    otp: '9156',
    userRating: 4.8,
  ),
  BookingModel(
    id: 'B004',
    userName: 'Sunita Devi',
    userPhone: '+91 65432 10987',
    pickupAddress: 'Central Bus Terminal, Noida',
    dropAddress: 'Railway Station, Platform 3',
    fare: 650,
    distanceKm: 22.0,
    etaMinutes: 15,
    vehicleType: 'bus',
    subType: 'Standard',
    status: 'completed',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    otp: '3782',
    userRating: 4.5,
  ),
];

class BookingNotifier extends Notifier<List<BookingModel>> {
  @override
  List<BookingModel> build() => List.from(_demoBookings);

  void updateStatus(String id, String newStatus) {
    state = state
        .map((b) => b.id == id ? b.copyWith(status: newStatus) : b)
        .toList();
  }

  void acceptBooking(String id) => updateStatus(id, 'accepted');
  void rejectBooking(String id) => updateStatus(id, 'cancelled');
  void startTrip(String id) => updateStatus(id, 'started');
  void completeTrip(String id) => updateStatus(id, 'completed');
  void markOnTheWay(String id) => updateStatus(id, 'on_the_way');
  void markArrived(String id) => updateStatus(id, 'arrived');
}

final bookingProvider = NotifierProvider<BookingNotifier, List<BookingModel>>(
  BookingNotifier.new,
);

final pendingBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) => b.status == 'pending').toList();
});

final activeBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) => ['accepted', 'on_the_way', 'arrived', 'started'].contains(b.status)).toList();
});

final historyBookingsProvider = Provider<List<BookingModel>>((ref) {
  return ref.watch(bookingProvider).where((b) => ['completed', 'cancelled'].contains(b.status)).toList();
});
