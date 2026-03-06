class RideTypeModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double baseFare;
  final double pricePerKm;
  final String waitingTime;
  final bool status;

  RideTypeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.baseFare,
    required this.pricePerKm,
    required this.waitingTime,
    this.status = true,
  });

  factory RideTypeModel.fromJson(Map<String, dynamic> json) {
    return RideTypeModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      baseFare: (json['baseFare'] as num?)?.toDouble() ?? 0.0,
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble() ?? 0.0,
      waitingTime: json['waitingTime'] ?? '',
      status: json['status'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'baseFare': baseFare,
      'pricePerKm': pricePerKm,
      'waitingTime': waitingTime,
      'status': status,
    };
  }
}
