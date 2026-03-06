import 'package:equatable/equatable.dart';

enum VehicleStatus { active, inactive, maintenance, expired }

enum VehicleType { cab, truck, bus }

class Vehicle extends Equatable {
  final String id;
  final String name;
  final String vin;
  final String plateNumber;
  final VehicleType type;
  final VehicleStatus status;
  final String imageUrl;
  final DateTime insuranceExpiry;
  final int? mileage;
  final double? batteryLevel;
  final bool needsInspection;

  const Vehicle({
    required this.id,
    required this.name,
    required this.vin,
    required this.plateNumber,
    required this.type,
    required this.status,
    required this.imageUrl,
    required this.insuranceExpiry,
    this.mileage,
    this.batteryLevel,
    this.needsInspection = false,
  });

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['_id']?.toString() ?? map['uid']?.toString() ?? '',
      name: map['vehicleModel'] ?? map['name'] ?? 'Unknown Vehicle',
      vin: map['vin'] ?? map['chassisNumber'] ?? 'N/A',
      plateNumber: map['vehicleNumberPlate'] ?? map['plateNumber'] ?? 'N/A',
      type: _parseType(map['categoryName'] ?? map['type']),
      status: _parseStatus(map['status']),
      imageUrl: map['vehicleImage'] ?? map['imageUrl'] ?? 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=500&q=80',
      insuranceExpiry: map['insuranceExpiry'] != null 
          ? DateTime.tryParse(map['insuranceExpiry'].toString()) ?? DateTime.now() 
          : DateTime.now(),
      mileage: map['mileage'] != null ? (map['mileage'] as num).toInt() : null,
      batteryLevel: map['batteryLevel'] != null ? (map['batteryLevel'] as num).toDouble() : null,
      needsInspection: map['needsInspection'] ?? false,
    );
  }

  static VehicleType _parseType(dynamic type) {
    final t = type?.toString().toLowerCase();
    if (t == 'truck') return VehicleType.truck;
    if (t == 'bus') return VehicleType.bus;
    return VehicleType.cab;
  }

  static VehicleStatus _parseStatus(dynamic status) {
    final s = status?.toString().toLowerCase();
    if (s == 'inactive') return VehicleStatus.inactive;
    if (s == 'maintenance') return VehicleStatus.maintenance;
    if (s == 'expired') return VehicleStatus.expired;
    return VehicleStatus.active;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        vin,
        plateNumber,
        type,
        status,
        imageUrl,
        insuranceExpiry,
        mileage,
        batteryLevel,
        needsInspection,
      ];
}
