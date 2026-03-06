import 'package:dio/dio.dart';
import '../../domain/models/driver_model.dart';

class DriverRepository {
  final Dio _dio;
  DriverRepository(this._dio);

  Future<List<Driver>> getDrivers() async {
    try {
      final response = await _dio.get('/drivers');
      if (response.statusCode == 200) {
        final List<dynamic> driversData = response.data['drivers'];
        return driversData.map((json) => Driver.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching drivers: $e');
      return [];
    }
  }

  Future<bool> updateDriverStatus(String driverId, DriverStatus status) async {
    try {
      final response = await _dio.put(
        '/drivers/$driverId/status',
        data: {'status': status.name},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating driver status: $e');
      return false;
    }
  }

  Future<bool> deleteDriver(String driverId) async {
    try {
      final response = await _dio.delete('/drivers/$driverId');
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting driver: $e');
      return false;
    }
  }

  Future<bool> warnDriver(String driverId, String reason) async {
    try {
      final response = await _dio.put(
        '/drivers/$driverId/warn',
        data: {'reason': reason},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error warning driver: $e');
      return false;
    }
  }
}
