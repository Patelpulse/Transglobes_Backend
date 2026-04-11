import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/logistics_request.dart';
import '../models/corporate_auth_provider.dart';

class JourneySegment {
  String start;
  String end;
  TransportMode mode;
  double distance = 0.0;
  List<LatLng> points = [];

  JourneySegment({required this.start, required this.end, required this.mode});
}

class LogisticsProvider with ChangeNotifier {
  final List<LogisticsRequest> _requests = [];
  List<JourneySegment> _journeySegments = [
    JourneySegment(start: '', end: '', mode: TransportMode.land)
  ];
  bool _isLoading = false;

  static const String googleApiKey = 'AIzaSyC7SGsD3I7EOEKDh8VXchJGSYz6dnLqM4I';
  static String get baseUrl =>
      'https://api.transgloble.com';

  // Web needs backend proxy to avoid CORS. Android/iOS can call Google directly.
  static String get _geocodeBaseUrl {
    if (kIsWeb)
      return '$baseUrl/api/maps/geocode';
    return 'https://maps.googleapis.com/maps/api/geocode/json';
  }

  static String get _directionsBaseUrl {
    if (kIsWeb)
      return '$baseUrl/api/maps/directions';
    return 'https://maps.googleapis.com/maps/api/directions/json';
  }

  static String get _autocompleteBaseUrl {
    if (kIsWeb)
      return '$baseUrl/api/maps/autocomplete';
    return 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  }

  List<LogisticsRequest> get requests => [..._requests];
  List<JourneySegment> get journeySegments => _journeySegments;
  bool get isLoading => _isLoading;

  void addRequest(LogisticsRequest request) {
    _requests.insert(0, request);
    notifyListeners();
  }

  double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  LogisticsRequest _requestFromBooking(Map<String, dynamic> booking) {
    final items = (booking['items'] as List?) ?? const [];
    final segments = (booking['segments'] as List?) ?? const [];
    final modes = segments.isNotEmpty
        ? segments
            .map((segment) =>
                _parseMode(segment is Map ? segment['mode']?.toString() : null))
            .toList()
        : [_parseMode(booking['vehicleType']?.toString())];

    final pickup = booking['pickup'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(booking['pickup'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final dropoff = booking['dropoff'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(booking['dropoff'] as Map<String, dynamic>)
        : <String, dynamic>{};

    double totalWeight = 0;
    for (final item in items) {
      if (item is Map) {
        final rawWeight = item['weight'];
        if (rawWeight is num) totalWeight += rawWeight.toDouble();
      }
    }

    return LogisticsRequest(
      id: booking['_id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      pickupLocation: pickup['address']?.toString() ??
          pickup['name']?.toString() ??
          'Pickup',
      destinationLocation: dropoff['address']?.toString() ??
          dropoff['name']?.toString() ??
          'Drop',
      weight: totalWeight > 0 ? totalWeight : 1,
      goodsType: items.isNotEmpty && items.first is Map
          ? (items.first['itemName']?.toString() ?? 'Cargo')
          : 'Cargo',
      modes: modes,
      selectedVehicles: const {},
      estimatedPrice:
          _toDouble(booking['totalPrice'] ?? booking['vehiclePrice'], fallback: 0),
      status: booking['status']?.toString() ?? 'Pending',
      createdAt: DateTime.tryParse(booking['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  TransportMode _parseMode(String? mode) {
    switch ((mode ?? '').toLowerCase()) {
      case 'flight':
      case 'air':
        return TransportMode.air;
      case 'sea cargo':
      case 'water':
      case 'ship':
        return TransportMode.water;
      default:
        return TransportMode.land;
    }
  }

  void updateSegments(List<JourneySegment> newSegments) {
    _journeySegments = newSegments;
    notifyListeners();
  }

  Future<List<double>?> getCoordsFromAddress(String address) async {
    if (address.isEmpty) return null;
    try {
      final url = Uri.parse(
          '$_geocodeBaseUrl?address=${Uri.encodeComponent(address)}&key=$googleApiKey');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['results'][0]['geometry']['location'];
          return [
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble()
          ];
        } else {
          debugPrint("Geocode API status: ${data['status']}");
        }
      }
    } catch (e) {
      debugPrint("Geocode Error: $e");
    }
    return null;
  }

  Future<void> calculateChainRoute() async {
    _isLoading = true;
    notifyListeners();

    try {
      for (var segment in _journeySegments) {
        if (segment.start.isEmpty || segment.end.isEmpty) continue;

        // Step 1: Geocode both addresses to get lat/lng
        final startCoords = await getCoordsFromAddress(segment.start);
        final endCoords = await getCoordsFromAddress(segment.end);

        debugPrint("🗺️ Start: ${segment.start} → $startCoords");
        debugPrint("🗺️ End: ${segment.end} → $endCoords");

        if (startCoords == null || endCoords == null) {
          debugPrint("❌ Could not geocode one or both addresses");
          continue;
        }

        if (segment.mode == TransportMode.land) {
          // Step 2: Use lat/lng for directions
          try {
            final origin = '${startCoords[0]},${startCoords[1]}';
            final dest = '${endCoords[0]},${endCoords[1]}';
            final url = Uri.parse(
                '$_directionsBaseUrl?origin=$origin&destination=$dest&key=$googleApiKey');
            debugPrint("📍 Directions URL: $url");

            final response = await http.get(url);

            if (response.statusCode == 200) {
              final data = json.decode(response.body);
              debugPrint("📍 Directions API status: ${data['status']}");

              if (data['status'] == 'OK' &&
                  data['routes'] != null &&
                  (data['routes'] as List).isNotEmpty) {
                final route = data['routes'][0];
                final polylineStr = route['overview_polyline']?['points'];

                if (polylineStr != null && polylineStr.toString().isNotEmpty) {
                  segment.points = _decodePolyline(polylineStr);
                  debugPrint(
                      "✅ Decoded ${segment.points.length} polyline points");

                  final distVal = route['legs']?[0]?['distance']?['value'];
                  if (distVal != null) {
                    segment.distance = (distVal as num).toDouble() / 1000.0;
                  }
                } else {
                  debugPrint("⚠️ No polyline, using straight line");
                  _fallbackStraightLine(segment, startCoords, endCoords);
                }
              } else {
                debugPrint(
                    "⚠️ Directions error: ${data['status']} - ${data['error_message'] ?? ''}");
                _fallbackStraightLine(segment, startCoords, endCoords);
              }
            } else {
              debugPrint("⚠️ HTTP ${response.statusCode}, using straight line");
              _fallbackStraightLine(segment, startCoords, endCoords);
            }
          } catch (e) {
            debugPrint("⚠️ Directions failed: $e");
            _fallbackStraightLine(segment, startCoords, endCoords);
          }
        } else {
          // Air/Water → straight line
          segment.points = [
            LatLng(startCoords[0], startCoords[1]),
            LatLng(endCoords[0], endCoords[1])
          ];
          segment.distance = 1500.0;
        }
      }
    } catch (e) {
      debugPrint("❌ Chain Calc Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _fallbackStraightLine(JourneySegment segment, List<double> startCoords,
      List<double> endCoords) {
    segment.points = [
      LatLng(startCoords[0], startCoords[1]),
      LatLng(endCoords[0], endCoords[1])
    ];
    final dLat = (endCoords[0] - startCoords[0]).abs();
    final dLng = (endCoords[1] - startCoords[1]).abs();
    segment.distance = (dLat + dLng) * 111.0;
  }

  List<LatLng> _decodePolyline(String encoded) {
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
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }

  double calculatePrice({
    required double weight,
    String goodsType = 'Standard',
  }) {
    double total = 0;
    for (var segment in _journeySegments) {
      if (segment.distance <= 0) continue;

      double basePrice = 500.0;
      double ratePerKm = 15.0;

      if (segment.mode == TransportMode.air) {
        basePrice = 5000.0;
        ratePerKm = 150.0;
      } else if (segment.mode == TransportMode.water) {
        basePrice = 2500.0;
        ratePerKm = 50.0;
      }

      total += basePrice + (segment.distance * ratePerKm);
    }

    total += (weight * 10);
    if (goodsType.toLowerCase().contains('fragile')) total *= 1.25;
    return total;
  }

  Future<bool> submitBooking(
      LogisticsRequest request, CorporateAccount account, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<Map<String, dynamic>> segmentData = _journeySegments
          .map((s) => {
                'start': {
                  'address': s.start,
                  'latitude':
                      s.points.isNotEmpty ? s.points.first.latitude : 0.0,
                  'longitude':
                      s.points.isNotEmpty ? s.points.first.longitude : 0.0,
                },
                'end': {
                  'address': s.end,
                  'latitude':
                      s.points.isNotEmpty ? s.points.last.latitude : 0.0,
                  'longitude':
                      s.points.isNotEmpty ? s.points.last.longitude : 0.0,
                },
                'mode': _getModeString(s.mode),
                'distanceKm': s.distance,
                'status': 'pending',
              })
          .toList();

      final firstSegment = segmentData.isNotEmpty ? segmentData.first : null;
      final lastSegment = segmentData.isNotEmpty ? segmentData.last : null;

      final pickup = firstSegment == null
          ? {
              'name': request.pickupLocation,
              'address': request.pickupLocation,
              'lat': 0.0,
              'lng': 0.0,
            }
          : {
              'name': request.pickupLocation,
              'address': request.pickupLocation,
              'lat': firstSegment['start']['latitude'],
              'lng': firstSegment['start']['longitude'],
            };

      final dropoff = lastSegment == null
          ? {
              'name': request.destinationLocation,
              'address': request.destinationLocation,
              'lat': 0.0,
              'lng': 0.0,
            }
          : {
              'name': request.destinationLocation,
              'address': request.destinationLocation,
              'lat': lastSegment['end']['latitude'],
              'lng': lastSegment['end']['longitude'],
            };

      final vehicleType = segmentData.isNotEmpty
          ? (segmentData.length == 1
              ? segmentData.first['mode']
              : 'Multi-Modal')
          : 'Road';

      final response = await http.post(
        Uri.parse('$baseUrl/api/logistics-bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': account.id,
          'userName': account.companyName,
          'userPhone': account.contactPhone,
          'pickup': pickup,
          'dropoff': dropoff,
          'distanceKm': segmentData.fold<double>(
            0.0,
            (sum, segment) =>
                sum + ((segment['distanceKm'] as num?)?.toDouble() ?? 0.0),
          ),
          'vehicleType': vehicleType,
          'vehiclePrice': request.estimatedPrice,
          'totalPrice': request.estimatedPrice,
          'items': [
            {
              'itemName': request.goodsType,
              'type': request.goodsType,
              'weight': request.weight,
              'quantity': 1,
              'length': 1,
              'width': 1,
              'height': 1,
              'unit': 'cm',
            }
          ],
          'segments': segmentData,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final booking = Map<String, dynamic>.from(data['data'] as Map);
          _requests.insert(0, _requestFromBooking(booking));
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ Submit Error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCorporateBookings(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/corporate/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        final bookings = (data['data'] as List? ?? const [])
            .map((item) =>
                _requestFromBooking(Map<String, dynamic>.from(item as Map)))
            .toList();
        _requests
          ..clear()
          ..addAll(bookings);
      }
    } catch (e) {
      debugPrint("❌ Fetch Corporate Bookings Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getModeString(TransportMode mode) {
    switch (mode) {
      case TransportMode.land:
        return 'Road';
      case TransportMode.air:
        return 'Flight';
      case TransportMode.water:
        return 'Sea Cargo';
    }
  }
}
