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

    return BookingModel(
      id: json['_id'] ?? json['id'] ?? '',
      userName: json['userName'] ?? 'Customer',
      userPhone: json['userPhone'] ?? json['phone'] ?? '',
      pickupAddress: json['pickupAddress'] ?? json['pick'] ?? '',
      dropAddress: json['dropAddress'] ?? json['drop'] ?? '',
      fare: parseDouble(json['fare']),
      distanceKm: (json['distanceKm'] != null)
          ? parseDouble(json['distanceKm'])
          : parseDouble(json['distance']?.toString().replaceAll(' km', '')),
      etaMinutes: parseInt(json['etaMinutes'], 10),
      vehicleType: json['rideMode'] == 'truck' ? 'truck' : 'cab',
      subType: json['rideMode']?.toString().toUpperCase() ?? 'SEDAN',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      otp: json['otp']?.toString(),
      actualFare: parseOptionalDouble(json['actualFare']),
      pickupLat: parseOptionalDouble(json['pickupLat']),
      pickupLng: parseOptionalDouble(json['pickupLng']),
      dropLat: parseOptionalDouble(json['dropLat']),
      dropLng: parseOptionalDouble(json['dropLng']),
      userId: json['userId']?.toString(),
      paymentStatus: json['paymentStatus'] ?? 'unpaid',
    );
  }
}
