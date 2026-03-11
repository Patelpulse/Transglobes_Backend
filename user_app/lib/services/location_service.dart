import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../core/config.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final baseUrl = AppConfig.apiBaseUrl;
      final url = Uri.parse(
        '$baseUrl/api/maps/geocode?latlng=$lat,$lng&key=$apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] ?? 'Unknown Location';
        }
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
    return 'Unknown Location';
  }

  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  static Future<Map<String, dynamic>> getRouteData(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final baseUrl = AppConfig.apiBaseUrl;
      final url = Uri.parse(
        '$baseUrl/api/maps/directions?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Decode polyline (this is simple but for high fidelity you'd use a polyline decoder)
          // For now, we'll just use the overview_polyline points or stick to start/end if decoding is too complex
          // but Google Directions returns overview_polyline which is encoded.
          // Let's use a simple approach for now or stick to start/end if we don't have a decoder.
          
          return {
            'points': [start, end], // Fallback to direct line if decoding isn't implemented
            'distance': (leg['distance']['value'] as num).toDouble() / 1000,
            'duration': (leg['duration']['value'] as num).toDouble() / 60,
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
    return {
      'points': [start, end],
      'distance': 0.0,
      'duration': 0.0,
    };
  }
}
