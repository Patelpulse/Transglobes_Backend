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
      
      final url = kIsWeb
          ? Uri.parse('$baseUrl/api/maps/geocode?latlng=$lat,$lng&key=$apiKey')
          : Uri.parse('https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey');
          
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
      
      final origin = "${start.latitude},${start.longitude}";
      final dest = "${end.latitude},${end.longitude}";
      
      final url = kIsWeb
          ? Uri.parse('$baseUrl/api/maps/directions?origin=$origin&destination=$dest&key=$apiKey')
          : Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey');
          
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          String encodedPolyline = route['overview_polyline']['points'];
          final List<LatLng> points = decodePolyline(encodedPolyline);
          
          return {
            'points': points,
            'distance': (leg['distance']['value'] as num).toDouble() / 1000,
            'duration': (leg['duration']['value'] as num).toDouble() / 60,
          };
        } else {
          debugPrint('Directions API Status: ${data['status']}');
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

  // Consolidated Polyline decoder with strict safety
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double latVal = lat / 100000.0;
      double lngVal = lng / 100000.0;
      
      // Strict clamping to valid geographic ranges
      if (latVal > 90.0) latVal = 90.0;
      if (latVal < -90.0) latVal = -90.0;
      if (lngVal > 180.0) lngVal = 180.0;
      if (lngVal < -180.0) lngVal = -180.0;

      polyline.add(LatLng(latVal, lngVal));
    }
    return polyline;
  }
}
