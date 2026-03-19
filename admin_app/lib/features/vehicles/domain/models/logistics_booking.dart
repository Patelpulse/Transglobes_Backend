enum LogisticsBookingStatus {
  pending,
  processing,
  inTransit,
  completed,
  cancelled,
  delayed
}

class LogisticsBooking {
  final String id;
  final String userName; // Name of user who booked (e.g. Gaurav)
  final String pickupName;
  final String dropName;
  final String modeOfTravel; // Train, Flight, Sea, etc.
  final double price;
  final LogisticsBookingStatus status;
  final DateTime createdAt;

  LogisticsBooking({
    required this.id,
    required this.userName,
    required this.pickupName,
    required this.dropName,
    required this.modeOfTravel,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory LogisticsBooking.fromJson(Map<String, dynamic> json) {
    return LogisticsBooking(
      id: json['_id'] ?? '',
      userName: json['userName'] ?? 'Unknown User',
      pickupName: json['pickupName'] ?? json['pickupLocation'] ?? '',
      dropName: json['dropName'] ?? json['dropoffLocation'] ?? '',
      modeOfTravel: json['modeOfTravel'] ?? json['vehicleType'] ?? 'Unknown',
      price: (json['price'] as num?)?.toDouble() ?? (json['fare'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(json['status']),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  static LogisticsBookingStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return LogisticsBookingStatus.pending;
      case 'processing': return LogisticsBookingStatus.processing;
      case 'in-transit': return LogisticsBookingStatus.inTransit;
      case 'ongoing': return LogisticsBookingStatus.inTransit;
      case 'completed': return LogisticsBookingStatus.completed;
      case 'cancelled': return LogisticsBookingStatus.cancelled;
      case 'delayed': return LogisticsBookingStatus.delayed;
      default: return LogisticsBookingStatus.pending;
    }
  }
}
