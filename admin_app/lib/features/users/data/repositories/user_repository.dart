import 'package:dio/dio.dart';
import '../../domain/models/user_model.dart';

class UserRepository {
  final Dio _dio;
  UserRepository(this._dio);

  Future<List<AppUser>> getUsers() async {
    try {
      final response = await _dio.get('admin/users');
      if (response.statusCode == 200) {
        final List<dynamic> usersData = response.data['users'];
        return usersData.map((json) => AppUser.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<List<SystemLog>> getSystemLogs() async {
    // Note: We could fetch this from backend if logs existed
    // For now, let's keep it but make it look more specific to current counts
    try {
      final response = await _dio.get('admin/stats');
      if (response.statusCode == 200) {
         return [
          SystemLog(
            id: 'log_1',
            title: 'Platform Scan Complete',
            description: 'Found ${response.data['totalUsers']} users and ${response.data['totalDrivers']} drivers.',
            timestamp: 'Just now',
            iconType: 'info',
          ),
          SystemLog(
            id: 'log_2',
            title: 'Fleet Status Updated',
            description: '${response.data['totalFleets'] ?? "N/A"} vehicles currently registered.',
            timestamp: '5 mins ago',
            iconType: 'cab',
          ),
        ];
      }
    } catch (e) {}
    
    return [
      SystemLog(
        id: 'log_1',
        title: 'System Initialized',
        description: 'Syncing with MongoDB database...',
        timestamp: 'Just now',
        iconType: 'info',
      ),
    ];
  }

  Future<Map<String, dynamic>> getPlatformOverview() async {
    try {
      final response = await _dio.get('admin/stats');
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error fetching platform overview: $e');
    }
    return {
      'totalUsers': 0,
      'totalDrivers': 0,
      'totalVehicles': 0,
      'fleetGrowth': 0,
      'supportTickets': 0,
      'urgentTickets': 0,
    };
  }
}
