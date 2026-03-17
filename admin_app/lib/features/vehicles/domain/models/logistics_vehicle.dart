class LogisticsVehicle {
  final String id;
  final String name;
  final String capacity;
  final double basePrice;
  final double pricePerKm;
  final String imageUrl;
  final bool isActive;

  LogisticsVehicle({
    required this.id,
    required this.name,
    required this.capacity,
    required this.basePrice,
    required this.pricePerKm,
    required this.imageUrl,
    this.isActive = true,
  });

  factory LogisticsVehicle.fromJson(Map<String, dynamic> json) {
    return LogisticsVehicle(
      id: json['_id'],
      name: json['name'],
      capacity: json['capacity'],
      basePrice: (json['basePrice'] as num).toDouble(),
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'capacity': capacity,
      'basePrice': basePrice,
      'pricePerKm': pricePerKm,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}
