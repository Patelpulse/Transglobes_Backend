import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/driver_model.dart';
import '../core/config.dart';
import '../core/network_logger.dart';

final databaseServiceProvider = Provider((ref) => DatabaseService());

class DatabaseService {
  Map<String, String> _getHeaders(String? token,
      {String? uid, bool isMultipart = false}) {
    final headers = <String, String>{};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }

    final String finalToken = token ?? 'dev-token-bypass';

    headers['Authorization'] = 'Bearer $finalToken';
    if (finalToken == 'dev-token-bypass' && uid != null) {
      headers['x-dev-uid'] = uid;
    }
    return headers;
  }

  Future<bool> saveDriverToBackend(dynamic user, [String? token]) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/sync');
      final requestBody = json.encode({
        'uid': user.uid,
        'email': user.email ?? '',
        'name': user.displayName ?? 'Driver',
      });
      final headers = _getHeaders(token, uid: user.uid);
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: requestBody,
      );
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return (data['isRegistered'] == true) || (data['hasDocs'] == true);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to sync with backend');
      }
    } catch (e) {
      print('Backend sync error: $e');
      rethrow;
    }
  }

  // Save driver profile to Backend
  Future<void> saveDriverProfile(DriverModel driver, [String? token]) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/sync');
      final requestBody = json.encode({
        'uid': driver.firebaseId,
        'name': driver.name,
        'email': driver.email,
        'mobileNumber': driver.phoneNumber,
        'aadharCardNumber': driver.aadharCardNumber,
        'drivingLicenseNumber': driver.drivingLicenseNumber,
        'panCardNumber': driver.panCardNumber,
        'dob': driver.dob,
        'vehicleId': driver.vehicleId,
        'vehicleModel': driver.vehicleModel,
        'vehicleYear': driver.vehicleYear,
        'vehicleNumberPlate': driver.vehicleNumberPlate,
      });
      final headers = _getHeaders(token, uid: driver.firebaseId);
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: requestBody,
      );

      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save profile: ${response.body}');
      }
    } catch (e) {
      print('Error saving driver profile: $e');
      rethrow;
    }
  }

  // Update driver profile in Backend
  Future<void> updateDriverProfile({
    required String token,
    required Map<String, dynamic> updateData,
  }) async {
    try {
      final authProfileUrl = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/profile');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final requestBody = json.encode(updateData);
      NetworkLogger.logRequest(
        method: 'PUT',
        url: authProfileUrl,
        headers: headers,
        body: requestBody,
      );
      var response = await http.put(
        authProfileUrl,
        headers: headers,
        body: requestBody,
      );
      NetworkLogger.logResponse(
        method: 'PUT',
        url: authProfileUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode != 200) {
        final legacyUrl =
            Uri.parse('${AppConfig.apiBaseUrl}/api/driver/profile/update');
        NetworkLogger.logRequest(
          method: 'PUT',
          url: legacyUrl,
          headers: headers,
          body: requestBody,
        );
        response = await http.put(
          legacyUrl,
          headers: headers,
          body: requestBody,
        );
        NetworkLogger.logResponse(
          method: 'PUT',
          url: legacyUrl,
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.body}');
      }
    } catch (e) {
      print('Error updating driver profile: $e');
      rethrow;
    }
  }

  // Upload driver documents to ImageKit via Backend
  Future<void> uploadDriverDocuments({
    required String token,
    XFile? photoFile,
    XFile? aadharFile,
    XFile? licenseFile,
    XFile? signatureFile,
    XFile? panFile,
    XFile? rcBookFile,
    XFile? insuranceFile,
    String? uid,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/upload');
      var request = http.MultipartRequest('POST', url);

      request.headers.addAll(_getHeaders(token, uid: uid, isMultipart: true));
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: request.headers,
        body:
            '{"multipart":true,"photo":${photoFile != null},"aadharCard":${aadharFile != null},"drivingLicense":${licenseFile != null},"signature":${signatureFile != null},"panCard":${panFile != null},"rcBook":${rcBookFile != null},"insurance":${insuranceFile != null}}',
      );

      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'photo',
          bytes,
          filename: photoFile.name,
        ));
      }
      if (aadharFile != null) {
        final bytes = await aadharFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'aadharCard',
          bytes,
          filename: aadharFile.name,
        ));
      }
      if (licenseFile != null) {
        final bytes = await licenseFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'drivingLicense',
          bytes,
          filename: licenseFile.name,
        ));
      }
      if (signatureFile != null) {
        final bytes = await signatureFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'signature',
          bytes,
          filename: signatureFile.name,
        ));
      }
      if (panFile != null) {
        final bytes = await panFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('panCard', bytes,
            filename: panFile.name));
      }
      if (rcBookFile != null) {
        final bytes = await rcBookFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('rcBook', bytes,
            filename: rcBookFile.name));
      }
      if (insuranceFile != null) {
        final bytes = await insuranceFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('insurance', bytes,
            filename: insuranceFile.name));
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamedResponse);
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to upload documents: ${response.body}');
      }
    } catch (e) {
      print('Error uploading documents: $e');
      rethrow;
    }
  }

  // Get driver profile from backend
  Future<DriverModel?> getDriverProfile(String uid, String token) async {
    try {
      final authProfileUrl = Uri.parse('${AppConfig.apiBaseUrl}/api/auth/profile');
      final authHeaders = _getHeaders(token, uid: uid);
      NetworkLogger.logRequest(
        method: 'GET',
        url: authProfileUrl,
        headers: authHeaders,
      );
      var response = await http
          .get(
            authProfileUrl,
            headers: authHeaders,
          )
          .timeout(const Duration(seconds: 15));
      NetworkLogger.logResponse(
        method: 'GET',
        url: authProfileUrl,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      if (response.statusCode != 200) {
        final legacyUrl = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/profile');
        final legacyHeaders = _getHeaders(token, uid: uid);
        NetworkLogger.logRequest(
          method: 'GET',
          url: legacyUrl,
          headers: legacyHeaders,
        );
        response = await http
            .get(
              legacyUrl,
              headers: legacyHeaders,
            )
            .timeout(const Duration(seconds: 15));
        NetworkLogger.logResponse(
          method: 'GET',
          url: legacyUrl,
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profileData = data['driver'] ?? data['user'] ?? data['profile'];
        if (profileData is Map<String, dynamic>) {
          return DriverModel.fromJson(profileData);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching profile: $e');
      return null;
    }
  }

  // Check if onboarding is complete
  Future<bool> isOnboardingComplete(String uid, String token) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/status');
      final headers = _getHeaders(token, uid: uid);
      NetworkLogger.logRequest(method: 'GET', url: url, headers: headers);
      final response = await http
          .get(
            url,
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));
      NetworkLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If they are in the DB (isRegistered), we consider initial registration "complete"
        // so we don't show the multi-step registration flow again.
        return (data['isRegistered'] == true) || (data['hasDocs'] == true);
      }
      return false;
    } catch (e) {
      print('Error checking onboarding: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> sendOTP(String email) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/otp/send');
      final requestBody = json.encode({'email': email});
      final headers = {'Content-Type': 'application/json'};
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: requestBody,
      );
      final response = await http
          .post(
            url,
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to send OTP');
      }
      return json.decode(response.body) as Map<String, dynamic>;
    } catch (e) {
      print('Error sending OTP: $e');
      rethrow;
    }
  }

  Future<bool> verifyOTP(String email, String otp, String token) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/otp/verify');
      final headers = _getHeaders(token);
      final requestBody = json.encode({'email': email, 'otp': otp});
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: requestBody,
      );
      final response = await http
          .post(
            url,
            headers: headers,
            body: requestBody,
          )
          .timeout(const Duration(seconds: 15));
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String password,
    required String aadharCard,
    required String panCard,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/register');
      final headers = {'Content-Type': 'application/json'};
      final requestBody = json.encode({
        'name': name,
        'email': email,
        'password': password,
        'aadharCard': aadharCard,
        'panCard': panCard,
      });
      NetworkLogger.logRequest(
        method: 'POST',
        url: url,
        headers: headers,
        body: requestBody,
      );
      final response = await http.post(
        url,
        headers: headers,
        body: requestBody,
      );
      NetworkLogger.logResponse(
        method: 'POST',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'driver': data['driver']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      final url = Uri.parse(
        '${AppConfig.apiBaseUrl}/api/driver/check-email',
      ).replace(queryParameters: {'email': email.trim()});
      NetworkLogger.logRequest(method: 'GET', url: url);
      final response = await http.get(url);
      NetworkLogger.logResponse(
        method: 'GET',
        url: url,
        statusCode: response.statusCode,
        responseBody: response.body,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }
}
