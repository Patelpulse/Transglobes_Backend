/// Mirrors backend `LogisticsBooking.status` (see `backend/models/LogisticsBooking.js`).
enum LogisticsBookingStatus {
  pending('pending', 'Pending'),
  pendingForDriver('pending_for_driver', 'Awaiting driver'),
  confirmed('confirmed', 'Confirmed'),
  processing('processing', 'Processing'),
  inTransit('in_transit', 'In transit'),
  delivered('delivered', 'Delivered'),
  cancelled('cancelled', 'Cancelled'),
  delayed('delayed', 'Delayed');

  const LogisticsBookingStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static LogisticsBookingStatus fromApi(dynamic raw) {
    if (raw == null) return LogisticsBookingStatus.pending;
    final s = raw.toString().toLowerCase().trim().replaceAll('-', '_');
    for (final v in LogisticsBookingStatus.values) {
      if (v.apiValue == s) return v;
    }
    if (s == 'intransit') return LogisticsBookingStatus.inTransit;
    if (s == 'completed') return LogisticsBookingStatus.delivered;
    if (s == 'ongoing') return LogisticsBookingStatus.inTransit;
    return LogisticsBookingStatus.pending;
  }

  /// Billing, roadmap builder, and dispatch locked once execution has started or finished.
  bool get locksSupervisorEditing =>
      this == LogisticsBookingStatus.processing ||
      this == LogisticsBookingStatus.inTransit ||
      this == LogisticsBookingStatus.delivered ||
      this == LogisticsBookingStatus.cancelled;

  bool get canSearchDriver =>
      this == LogisticsBookingStatus.pending ||
      this == LogisticsBookingStatus.pendingForDriver ||
      this == LogisticsBookingStatus.confirmed;

  /// Supervisor "ACTIVE" tab: orders past initial intake but not yet delivered/cancelled.
  bool get isActivePipeline =>
      this == LogisticsBookingStatus.pendingForDriver ||
      this == LogisticsBookingStatus.confirmed ||
      this == LogisticsBookingStatus.processing ||
      this == LogisticsBookingStatus.inTransit;

  /// Sidebar "Active / Processing" bucket (pre–in-transit work).
  bool get isSidebarPreTransitActive =>
      this == LogisticsBookingStatus.pendingForDriver ||
      this == LogisticsBookingStatus.confirmed ||
      this == LogisticsBookingStatus.processing;
}

class LogisticsSegment {
  final String id;
  final Map<String, dynamic> start;
  final Map<String, dynamic> end;
  final String mode; // Road, Train, Flight, Sea Cargo
  final double distanceKm;
  final String? driverId;
  final String? transportName;
  final String? transportNumber;
  final String? estimatedTime;
  final String? estimatedDate;
  final String status;
  final double price;

  LogisticsSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.mode,
    this.distanceKm = 0.0,
    this.driverId,
    this.transportName,
    this.transportNumber,
    this.estimatedTime,
    this.estimatedDate,
    required this.status,
    this.price = 0.0,
  });

  factory LogisticsSegment.fromJson(Map<String, dynamic> json) {
    return LogisticsSegment(
      id: json['_id'] ?? '',
      start: json['start'] ?? {},
      end: json['end'] ?? {},
      mode: json['mode'] ?? 'Road',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      driverId: json['driverId'],
      transportName: json['transportName'],
      transportNumber: json['transportNumber'],
      estimatedTime: json['estimatedTime'],
      estimatedDate: json['estimatedDate'],
      status: json['status'] ?? 'pending',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'mode': mode,
      'distanceKm': distanceKm,
      'driverId': driverId,
      'transportName': transportName,
      'transportNumber': transportNumber,
      'estimatedTime': estimatedTime,
      'estimatedDate': estimatedDate,
      'status': status,
      'price': price,
    };
  }
}

class LogisticsBooking {
  final String id;
  final String userId; // Unique user ID
  final String userName; // Name of user who booked (e.g. Gaurav)
  final String userPhone; // Phone of user who booked
  final String pickupName;
  final String dropName;
  final String modeOfTravel; // Train, Flight, Sea, etc.
  final double price;
  final LogisticsBookingStatus status;
  final DateTime createdAt;
  final double distanceKm;
  final double vehiclePrice;
  final double helperCost;
  final double additionalCharges;
  final double discountAmount;
  final int helperCount;
  final List<dynamic> items;
  final Map<String, dynamic>? pickupAddressDetails;
  final Map<String, dynamic>? receivedAddressDetails;
  final String? railwayStation;
  final String? transportName;
  final String? transportNumber;
  final String? estimatedTime;
  final String? estimatedDate;
  final List<LogisticsSegment> segments;

  LogisticsBooking({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone = '',
    required this.pickupName,
    required this.dropName,
    required this.modeOfTravel,
    required this.price,
    required this.status,
    required this.createdAt,
    this.distanceKm = 0.0,
    this.vehiclePrice = 0.0,
    this.helperCost = 0.0,
    this.additionalCharges = 0.0,
    this.discountAmount = 0.0,
    this.helperCount = 0,
    this.items = const [],
    this.pickupAddressDetails,
    this.receivedAddressDetails,
    this.railwayStation,
    this.transportName,
    this.transportNumber,
    this.estimatedTime,
    this.estimatedDate,
    this.segments = const [],
  });

  factory LogisticsBooking.fromJson(Map<String, dynamic> json) {
    // Helper to extract nested address names
    String? getAddressName(dynamic location) {
      if (location == null) return null;
      if (location is String) return location;
      if (location is Map) {
        return location['name'] ??
            location['address'] ??
            location['fullAddress'] ??
            location['label'];
      }
      return null;
    }

    return LogisticsBooking(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? json['userId'] ?? 'Unknown User',
      userPhone: json['userPhone'] ?? json['mobileNumber'] ?? '',
      pickupName: getAddressName(json['pickup']) ??
          getAddressName(json['pickupAddress']) ??
          json['pickupLocation'] ??
          '',
      dropName: getAddressName(json['dropoff']) ??
          getAddressName(json['receivedAddress']) ??
          json['dropName'] ??
          json['dropoffLocation'] ??
          '',
      modeOfTravel: json['modeOfTravel'] ?? json['vehicleType'] ?? 'Unknown',
      price: (json['totalPrice'] as num?)?.toDouble() ??
          (json['price'] as num?)?.toDouble() ??
          (json['fare'] as num?)?.toDouble() ??
          0.0,
      status: LogisticsBookingStatus.fromApi(json['status']),
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      vehiclePrice: (json['vehiclePrice'] as num?)?.toDouble() ?? 0.0,
      helperCost: (json['helperCost'] as num?)?.toDouble() ?? 0.0,
      additionalCharges: (json['additionalCharges'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      helperCount: json['helperCount'] ?? 0,
      items: json['items'] ?? [],
      pickupAddressDetails:
          json['pickupAddress'] is Map ? json['pickupAddress'] : null,
      receivedAddressDetails:
          json['receivedAddress'] is Map ? json['receivedAddress'] : null,
      railwayStation: json['railwayStation'],
      transportName: json['transportName'],
      transportNumber: json['transportNumber'],
      estimatedTime: json['estimatedTime']?.toString(),
      estimatedDate: json['estimatedDate']?.toString(),
      segments: (json['segments'] as List?)
              ?.map((s) => LogisticsSegment.fromJson(s))
              .toList() ??
          [],
    );
  }
}
