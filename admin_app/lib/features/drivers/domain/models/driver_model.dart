import 'package:equatable/equatable.dart';

enum DriverStatus { active, inactive, suspended, pending }

class Driver extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? mobileNumber;
  final DriverStatus status;
  final String? licenseNumber;
  final String? vehicleInfo; // e.g., "Toyota Prius • ABC-1234"
  final String? aadharCardNumber;
  final String? panCardNumber;
  final String? aadharCardPhoto;
  final String? drivingLicensePhoto;
  final String? panCardPhoto;
  final String? panCardImage; // New high-res field
  final String? rcBook;      // New field
  final String? insurance;   // New field
  final String? signatureUrl;
  final String? vehicleModel;
  final String? vehicleNumberPlate;
  final String? vehicleYear;
  final DateTime? dob; // Added Date of Birth
  final double rating;
  final double walletBalance;
  final String imageUrl;
  final bool isFraudulent;
  final bool? isOnline;

  const Driver({
    required this.id,
    required this.name,
    required this.email,
    this.mobileNumber,
    required this.status,
    this.licenseNumber,
    this.vehicleInfo,
    this.aadharCardNumber,
    this.panCardNumber,
    this.aadharCardPhoto,
    this.drivingLicensePhoto,
    this.panCardPhoto,
    this.panCardImage,
    this.rcBook,
    this.insurance,
    this.signatureUrl,
    this.vehicleModel,
    this.vehicleNumberPlate,
    this.vehicleYear,
    this.dob,
    this.rating = 0.0,
    required this.walletBalance,
    required this.imageUrl,
    this.isFraudulent = false,
    this.isOnline,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    String vInfo = "";
    if (map['vehicleModel'] != null && map['vehicleNumberPlate'] != null) {
      vInfo = "${map['vehicleModel']} • ${map['vehicleNumberPlate']}";
    } else {
      vInfo = map['vehicleInfo'] ?? "No vehicle info";
    }
    final rawName = (map['name'] ?? '').toString().trim();
    final email = (map['email'] ?? '').toString().trim();
    final mobile =
        (map['mobileNumber'] ?? map['phoneNumber'] ?? map['phone'])?.toString().trim();
    final fallbackName = email.isNotEmpty
        ? email.split('@').first
        : (mobile != null && mobile.length >= 4
            ? 'Driver ${mobile.substring(mobile.length - 4)}'
            : 'Unknown Driver');

    return Driver(
      id: map['_id']?.toString() ?? map['uid']?.toString() ?? '',
      name: rawName.isNotEmpty ? rawName : fallbackName,
      email: email,
      mobileNumber: mobile,
      status: _parseStatus(map['status']),
      licenseNumber: map['drivingLicenseNumber'] ?? map['licenseNumber'],
      vehicleInfo: vInfo,
      aadharCardNumber: map['aadharCardNumber']?.toString(),
      panCardNumber: map['panCardNumber']?.toString(),
      aadharCardPhoto: map['aadharCard'] ?? map['aadharCardPhoto'],
      drivingLicensePhoto: map['drivingLicense'] ?? map['drivingLicensePhoto'],
      panCardPhoto: map['panCard'] ?? map['panCardPhoto'],
      panCardImage: map['panCardImage'],
      rcBook: map['rcBook'],
      insurance: map['insurance'],
      signatureUrl: map['signature'] ?? map['signatureUrl'],
      vehicleModel: map['vehicleModel']?.toString(),
      vehicleNumberPlate: map['vehicleNumberPlate']?.toString(),
      vehicleYear: map['vehicleYear']?.toString(),
      dob: map['dob'] != null ? DateTime.parse(map['dob'].toString()) : null,
      rating: (map['rating'] ?? 0).toDouble(),
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      imageUrl: (map['photo'] != null && map['photo'] != '') 
          ? map['photo'] 
          : 'https://images.unsplash.com/photo-1591115765373-520b7a217215?w=200&q=80',
      isFraudulent: map['isFraudulent'] ?? false,
      isOnline: map['isOnline'] as bool?,
    );
  }

  static DriverStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return DriverStatus.active;
      case 'pending':
        return DriverStatus.pending;
      case 'suspended':
        return DriverStatus.suspended;
      default:
        return DriverStatus.inactive;
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        mobileNumber,
        status,
        licenseNumber,
        vehicleInfo,
        aadharCardNumber,
        panCardNumber,
        aadharCardPhoto,
        drivingLicensePhoto,
        panCardPhoto,
        panCardImage,
        rcBook,
        insurance,
        signatureUrl,
        vehicleModel,
        vehicleNumberPlate,
        vehicleYear,
        dob,
        rating,
        walletBalance,
        imageUrl,
        isFraudulent,
        isOnline,
      ];
}
