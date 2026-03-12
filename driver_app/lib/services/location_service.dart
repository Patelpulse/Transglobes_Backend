import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/config.dart';

class LocationService {
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
          
          // Decode polyline using the google_polyline_algorithm logic
          String encodedPolyline = route['overview_polyline']['points'];
          final decodedCoords = decodePolyline(encodedPolyline);
          
          final List<LatLng> points = decodedCoords
              .map((coord) => LatLng(coord[0].toDouble(), coord[1].toDouble()))
              .toList();
          
          return {
            'points': points,
            'distance': (leg['distance']['value'] as num).toDouble() / 1000, // km
            'duration': (leg['duration']['value'] as num).toDouble() / 60,   // mins
          };
        }
      }
    } catch (e) {
      debugPrint('Error fetching route for driver: $e');
    }
    return {
      'points': [start, end],
      'distance': 0.0,
      'duration': 0.0,
    };
  }
}

// Utility to decode polyline strings
List<List<num>> decodePolyline(String encoded) {
  List<int> poly = encoded.codeUnits;
  int index = 0;
  int len = encoded.length;
  int lat = 0;
  int lng = 0;
  List<List<num>> decoded = [];

  while (index < len) {
    int b;
    int shift = 0;
    int result = 0;
    do {
      b = poly[index++] - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = poly[index++] - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    decoded.add([lat / 1E5, lng / 1E5]);
  }

  return decoded;
}
