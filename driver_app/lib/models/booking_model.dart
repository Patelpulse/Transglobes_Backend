import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String? userId;
  final double? actualFare;
  final String paymentStatus; // unpaid, paid
  final String? railwayStation;
  final Map<String, dynamic>? pickupDetails;
  final Map<String, dynamic>? dropDetails;
  final List<dynamic>? items;
  final double? vehiclePrice;
  final double? helperCost;
  final double? discountAmount;
  final String? transportName;
  final String? transportNumber;

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
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.actualFare,
    this.userId,
    this.paymentStatus = 'unpaid',
    this.railwayStation,
    this.pickupDetails,
    this.dropDetails,
    this.items,
    this.vehiclePrice,
    this.helperCost,
    this.discountAmount,
    this.transportName,
    this.transportNumber,
  });

  BookingModel copyWith({
    String? status,
    double? actualFare,
    String? userId,
    double? fare,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? otp,
    String? paymentStatus,
    String? railwayStation,
    List<dynamic>? items,
    double? vehiclePrice,
    double? helperCost,
    double? discountAmount,
  }) =>
      BookingModel(
        id: id,
        userName: userName,
        userPhone: userPhone,
        pickupAddress: pickupAddress,
        dropAddress: dropAddress,
        fare: fare ?? this.fare,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
        vehicleType: vehicleType,
        subType: subType,
        status: status ?? this.status,
        createdAt: createdAt,
        otp: otp ?? this.otp,
        userRating: userRating,
        pickupLat: pickupLat ?? this.pickupLat,
        pickupLng: pickupLng ?? this.pickupLng,
        dropLat: dropLat ?? this.dropLat,
        dropLng: dropLng ?? this.dropLng,
        actualFare: actualFare ?? this.actualFare,
        userId: userId ?? this.userId,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        railwayStation: railwayStation ?? this.railwayStation,
        items: items ?? this.items,
        vehiclePrice: vehiclePrice ?? this.vehiclePrice,
        helperCost: helperCost ?? this.helperCost,
        discountAmount: discountAmount ?? this.discountAmount,
      );

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    double? parseOptionalDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    int parseInt(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    String deriveVehicleType(String? mode) {
      if (mode == null) return 'cab';
      final m = mode.toLowerCase();
      if (['pickup', 'mini_truck', 'container', 'flatbed', 'ace', 'pickup8ft', '3wheeler', 'truck', 'train', 'flight', 'ship', 'cargo', 'logistics', 'sea', 'sea cargo'].contains(m)) {
        return 'truck';
      }
      if (['mini_bus', 'standard', 'luxury', 'sleeper', 'bus'].contains(m)) {
        return 'bus';
      }
      return 'cab';
    }

    String mapStatus(String? s) {
      if (s == null) return 'pending';
      switch (s.toLowerCase()) {
        case 'confirmed': return 'accepted';
        case 'pending_for_driver': return 'pending_for_driver'; // keep as-is for filter
        case 'processing': return 'pending';
        case 'in_transit': return 'ongoing';
        case 'delivered': return 'completed';
        default: return s;
      }
    }

    // Support both nested {address,latitude,longitude} objects (from DB)
    // and flat strings (from socket events)
    String resolveAddress(dynamic nested, String flatFallback) {
      if (nested is Map) return nested['address']?.toString() ?? '';
      if (nested is String) return nested;
      return json[flatFallback]?.toString() ?? '';
    }
    double? resolveLatFromObj(dynamic nested, String flatKey) {
      if (nested is Map) return parseOptionalDouble(nested['latitude'] ?? nested['lat']);
      return parseOptionalDouble(json[flatKey]);
    }
    double? resolveLngFromObj(dynamic nested, String flatKey) {
      if (nested is Map) return parseOptionalDouble(nested['longitude'] ?? nested['lng']);
      return parseOptionalDouble(json[flatKey]);
    }

    final pickupRaw = json['pickup'] ?? json['pickupAddress'];
    final dropRaw   = json['dropoff'] ?? json['dropAddress'] ?? json['receivedAddress'];
    final mode = json['rideMode']?.toString() ?? json['modeOfTravel']?.toString() ?? json['vehicleType']?.toString();

    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      userName: json['userName'] ?? 'Customer',
      userPhone: json['userPhone'] ?? json['phone'] ?? '',
      pickupAddress: resolveAddress(pickupRaw, 'pick'),
      dropAddress:   resolveAddress(dropRaw, 'drop'),
      fare: parseDouble(json['totalPrice'] ?? json['fare'] ?? json['vehiclePrice'] ?? 0),
      distanceKm: (json['distanceKm'] != null)
          ? parseDouble(json['distanceKm'])
          : parseDouble(json['distance']?.toString().replaceAll(' km', '')),
      etaMinutes: parseInt(json['etaMinutes'], 10),
      vehicleType: deriveVehicleType(mode),
      subType: mode?.toUpperCase() ?? 'LOGISTICS',
      status: mapStatus(json['status']),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      otp: json['otp']?.toString(),
      actualFare: parseOptionalDouble(json['actualFare']),
      pickupLat: resolveLatFromObj(pickupRaw, 'pickupLat'),
      pickupLng: resolveLngFromObj(pickupRaw, 'pickupLng'),
      dropLat: resolveLatFromObj(dropRaw, 'dropLat'),
      dropLng: resolveLngFromObj(dropRaw, 'dropLng'),
      userId: json['userId']?.toString(),
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
      railwayStation: json['railwayStation'] ?? json['transitPoint'],
      pickupDetails: pickupRaw is Map ? Map<String, dynamic>.from(pickupRaw) : null,
      dropDetails:   dropRaw is Map   ? Map<String, dynamic>.from(dropRaw)   : null,
      items: json['items'] is List ? List<dynamic>.from(json['items']) : null,
      vehiclePrice: parseOptionalDouble(json['vehiclePrice'] ?? json['baseFare']),
      helperCost: parseOptionalDouble(json['helperCost']),
      discountAmount: parseOptionalDouble(json['discountAmount']),
      transportName: json['transportName'],
      transportNumber: json['transportNumber'],
    );
  }
}
