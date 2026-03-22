import 'package:dio/dio.dart';
import '../../domain/models/vehicle.dart';

class VehicleRepository {
  final Dio _dio;
  VehicleRepository(this._dio);

  Future<List<Vehicle>> getVehicles() async {
    try {
      final response = await _dio.get('admin/vehicles');
      if (response.statusCode == 200) {
        final List<dynamic> vehiclesData = response.data['vehicles'];
        return vehiclesData.map((json) => Vehicle.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }
}
