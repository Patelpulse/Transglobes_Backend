import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ride_type_model.dart';
import '../services/api_service.dart';
import '../core/api_endpoints.dart';

final rideTypesProvider = FutureProvider<List<RideTypeModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getWithFallback(
    RideEndpoints.rideTypes,
    RideEndpoints.rideTypesLegacy,
  );
  
  if (response['success'] == true) {
    final List data = response['data'];
    return data.map((json) => RideTypeModel.fromJson(json)).toList();
  }
  return [];
});
