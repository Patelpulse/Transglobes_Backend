import 'package:dio/dio.dart';
import '../../domain/models/logistics_booking.dart';

class LogisticsBookingRepository {
  final Dio _dio;
  LogisticsBookingRepository(this._dio);

  Future<List<LogisticsBooking>> getAllBookings() async {
    try {
      // Joins with http://127.0.0.1:8080/api/ to hit /api/logistics-bookings
      final response = await _dio.get('logistics-bookings');
      
      print('>>> Logistics API Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> body = response.data;
        if (body['success'] == true) {
          final List<dynamic> dataList = body['data'];
          print('>>> Fetched ${dataList.length} bookings from MongoDB');
          
          final bookings = dataList.map((json) => LogisticsBooking.fromJson(json)).toList();
          return bookings;
        } else {
          print('>>> API Response error: ${body['message']}');
        }
      }
      return [];
    } catch (e) {
      print('>>> Dio Error fetching logistics bookings: $e');
      return [];
    }
  }

  Future<bool> assignDriver(String bookingId, String driverId) async {
    try {
      final response = await _dio.post('logistics-bookings/$bookingId/assign', data: {'driverId': driverId});
      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning driver: $e');
      return false;
    }
  }
}
