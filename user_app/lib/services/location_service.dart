import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

  static LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  static Future<Map<String, dynamic>> getRouteData(
    LatLng start,
    LatLng end,
  ) async {
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List<dynamic> coordinates = route['geometry']['coordinates'];
          return {
            'points': coordinates
                .map(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                )
                .toList(),
            'distance':
                (route['distance'] as num).toDouble() / 1000, // meters to km
            'duration':
                (route['duration'] as num).toDouble() /
                60, // seconds to minutes
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
