import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dioProvider = Provider<Dio>((ref) {
  // Point to the root API directory for consistency across all repositories
  const String localUrl = 'http://127.0.0.1:8080/api/';
  const String prodUrl = 'https://transglobesbackend-production.up.railway.app/api/';
  
  final dio = Dio(BaseOptions(
    baseUrl: localUrl, 
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) {
      if (e.response?.statusCode == 401) {
        // Handle unauthenticated state?
      }
      return handler.next(e);
    },
  ));

  return dio;
});
