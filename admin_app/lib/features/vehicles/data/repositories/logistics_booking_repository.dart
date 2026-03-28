import 'package:dio/dio.dart';
import '../../domain/models/logistics_booking.dart';

class LogisticsBookingRepository {
  final Dio _dio;
  LogisticsBookingRepository(this._dio);

  Future<List<LogisticsBooking>> getAllBookings() async {
    try {
      // Hits Railway production endpoint /api/logistics-bookings
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

  Future<bool> assignDriver(String bookingId, String driverId, {String? transportName, String? transportNumber, String? estimatedTime, String? estimatedDate}) async {
    try {
      final url = driverId == 'all' ? 'send-order-to-drivers' : 'logistics-bookings/$bookingId/assign';
      print('>>> Dispatch API URL: $url');
      print('>>> Body: {bookingId: $bookingId, driverId: $driverId, transportName: $transportName, transportNumber: $transportNumber, estimatedTime: $estimatedTime, estimatedDate: $estimatedDate}');
      
      final response = await _dio.post(url, data: {
        'bookingId': bookingId,
        'driverId': driverId,
        'transportName': transportName,
        'transportNumber': transportNumber,
        'estimatedTime': estimatedTime,
        'estimatedDate': estimatedDate,
      });
      
      print('>>> Response Status: ${response.statusCode}');
      print('>>> Response Data: ${response.data}');
      
      return response.statusCode == 200;
    } catch (e) {
      if (e is DioException) {
        print('>>> Dio Error assigning driver: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        print('>>> Error assigning driver: $e');
      }
      return false;
    }
  }

  Future<bool> updateRailwayStation(String bookingId, String stationName) async {
    try {
      final response = await _dio.patch('logistics-bookings/$bookingId/railway-station', data: {'stationName': stationName});
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating railway station: $e');
      return false;
    }
  }

  Future<bool> updateBilling({
    required String bookingId,
    required double vehiclePrice,
    required double helperCost,
    required double additionalCharges,
    required double discountAmount,
    required double totalPrice,
  }) async {
    try {
      final response = await _dio.patch('logistics-bookings/$bookingId/billing', data: {
        'vehiclePrice': vehiclePrice,
        'helperCost': helperCost,
        'additionalCharges': additionalCharges,
        'discountAmount': discountAmount,
        'totalPrice': totalPrice,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating billing: $e');
      return false;
    }
  }

  Future<bool> updateRoadmap(String bookingId, List<LogisticsSegment> segments) async {
    try {
      final response = await _dio.patch('logistics-bookings/$bookingId/roadmap', data: {
        'segments': segments.map((s) => s.toJson()).toList(),
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating roadmap: $e');
      return false;
    }
  }

  Future<bool> assignSegmentDriver(String bookingId, String segmentId, String driverId) async {
    try {
      final response = await _dio.post('logistics-bookings/$bookingId/segment/$segmentId/assign', data: {
        'driverId': driverId,
      });
      return response.statusCode == 200;
    } catch (e) {
      print('Error assigning segment driver: $e');
      return false;
    }
  }
}
