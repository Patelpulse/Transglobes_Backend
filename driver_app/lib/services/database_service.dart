import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // Keep for location streaming if needed
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../models/driver_model.dart';
import '../core/config.dart';
final databaseServiceProvider = Provider((ref) => DatabaseService());

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  Future<bool> saveDriverToBackend(dynamic user) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/sync');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': user.uid,
          'email': user.email ?? '',
          'name': user.displayName ?? 'Driver',
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['hasDocs'] ?? false;
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
  Future<void> saveDriverProfile(DriverModel driver) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/sync');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
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
        }),
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
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/profile/update');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(updateData),
      );

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
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/upload');
      var request = http.MultipartRequest('POST', url);
      
      request.headers['Authorization'] = 'Bearer $token';

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

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/profile');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DriverModel.fromJson(data['driver']);
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
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['hasDocs'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking onboarding: $e');
      return false;
    }
  }

  Future<void> sendOTP(String email) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/otp/send');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('Error sending OTP: $e');
      rethrow;
    }
  }

  Future<bool> verifyOTP(String email, String otp, String token) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/driver/otp/verify');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'email': email, 'otp': otp}),
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
}
