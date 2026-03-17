import 'package:dio/dio.dart';
import '../../domain/models/logistics_vehicle.dart';

class LogisticsVehicleRepository {
  final Dio _dio;
  LogisticsVehicleRepository(this._dio);

  Future<List<LogisticsVehicle>> getLogisticsVehicles() async {
    try {
      final response = await _dio.get('/logistics-vehicles/all');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => LogisticsVehicle.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching logistics vehicles: $e');
      return [];
    }
  }

  Future<void> addLogisticsVehicle(LogisticsVehicle vehicle) async {
    await _dio.post('/logistics-vehicles', data: vehicle.toJson());
  }

  Future<void> updateLogisticsVehicle(String id, Map<String, dynamic> data) async {
    await _dio.put('/logistics-vehicles/$id', data: data);
  }

  Future<void> deleteLogisticsVehicle(String id) async {
    await _dio.delete('/logistics-vehicles/$id');
  }
}
