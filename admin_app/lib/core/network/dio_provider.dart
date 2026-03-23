import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';

final dioProvider = Provider<Dio>((ref) {
  // Synchronized with Backend and other Apps
  const String localUrl = 'http://localhost:8000/api/';
  const String prodUrl = 'https://transglobesbackend-production.up.railway.app/api/';
  
  final dio = Dio(BaseOptions(
    baseUrl: kDebugMode ? localUrl : prodUrl,
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
