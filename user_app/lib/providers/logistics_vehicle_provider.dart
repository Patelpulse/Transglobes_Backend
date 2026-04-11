import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../services/auth_service.dart';

class LogisticsVehicle {
  final String id;
  final String name;
  final String capacity;
  final double basePrice;
  final double pricePerKm;
  final double pricePerPiece;
  final String imageUrl;

  LogisticsVehicle({
    required this.id,
    required this.name,
    required this.capacity,
    required this.basePrice,
    required this.pricePerKm,
    required this.pricePerPiece,
    required this.imageUrl,
  });

  factory LogisticsVehicle.fromJson(Map<String, dynamic> json) {
    return LogisticsVehicle(
      id: json['_id'],
      name: json['name'],
      capacity: json['capacity'],
      basePrice: (json['basePrice'] as num).toDouble(),
      pricePerKm: (json['pricePerKm'] as num?)?.toDouble() ?? 0.0,
      pricePerPiece: (json['pricePerPiece'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'],
    );
  }
}

final logisticsVehiclesProvider = FutureProvider<List<LogisticsVehicle>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final response = await http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/api/logistics-vehicles'),
    headers: await authService.buildAuthHeaders(),
  );
  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((item) => LogisticsVehicle.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load logistics vehicles');
  }
});
