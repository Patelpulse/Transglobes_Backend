import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';
import '../core/api_endpoints.dart';
import '../services/auth_service.dart';
import '../services/network_logger.dart';

class TypeGood {
  final String id;
  final String name;
  final String icon;

  TypeGood({required this.id, required this.name, required this.icon});

  factory TypeGood.fromJson(Map<String, dynamic> json) {
    return TypeGood(
      id: json['_id'],
      name: json['name'],
      icon: json['icon'] ?? 'inventory',
    );
  }
}

final typeGoodsProvider = FutureProvider<List<TypeGood>>((ref) async {
  final authService = ref.read(authServiceProvider);
  final url = Uri.parse('${AppConfig.apiBaseUrl}${LogisticsEndpoints.typeGood}');
  final headers = await authService.buildAuthHeaders();
  NetworkLogger.logRequest(method: 'GET', url: url, headers: headers);
  final response = await http.get(
    url,
    headers: headers,
  );
  NetworkLogger.logResponse(method: 'GET', url: url, response: response);
  if (response.statusCode == 200) {
    final List data = json.decode(response.body);
    return data.map((item) => TypeGood.fromJson(item)).toList();
  } else {
    throw Exception('Failed to load type goods');
  }
});
