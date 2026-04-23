import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'deploy_hosts.dart';

String _resolveAdminApiBaseUrl() {
  const String prodUrl = 'http://72.61.172.182:2020/api/';
  if (isVpsDeployedWeb) {
    return '$kVpsApiOrigin/api/';
  }

  return prodUrl;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: _resolveAdminApiBaseUrl(),
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
