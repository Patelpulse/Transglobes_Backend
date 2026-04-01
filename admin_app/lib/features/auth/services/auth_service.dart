import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: kIsWeb
        ? '${Uri.base.origin}/api/admin/'
        : 'https://transglobesbackend-production.up.railway.app/api/admin/',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Use Firebase signInWithPopup — works on web without redirect_uri_mismatch
      final UserCredential userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      final String? googleToken = await userCredential.user?.getIdToken();

      if (googleToken == null) return {'success': false, 'message': 'Failed to get auth token'};

      // 3. Sync with backend
      final response = await _dio.post('sync', options: Options(
        headers: {'Authorization': 'Bearer $googleToken'},
      ));

      if (response.statusCode == 200) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('admin_uid', data['admin']['_id'] ?? data['admin']['id']);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Failed to sync with backend'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('admin_uid', data['admin']['id']); // Backend returns 'id' under 'admin'
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'Unknown error occurred'};
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Login failed'};
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('register', data: {
        'name': name,
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Registration failed'};
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Registration failed'};
      }
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null) {
      try {
        await _dio.post('logout', options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ));
      } catch (e) {
        // Ignore failure on logout
      }
    }
    await prefs.remove('token');
    await prefs.remove('admin_uid');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await _dio.get('profile', options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ));
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Failed to fetch profile'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> updateProfilePhoto(List<int> bytes, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      FormData formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(bytes, filename: fileName),
      });
      final response = await _dio.post('profile/photo', data: formData, options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ));
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Upload failed'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? e.message};
    }
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await _dio.post('profile/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }, options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ));
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      }
      return {'success': false, 'message': 'Password change failed'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['message'] ?? e.message};
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('token');
  }
}
