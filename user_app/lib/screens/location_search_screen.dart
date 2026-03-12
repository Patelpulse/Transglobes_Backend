import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import '../core/config.dart';

class LocationSearchScreen extends ConsumerStatefulWidget {
  final String title;

  const LocationSearchScreen({super.key, required this.title});

  @override
  ConsumerState<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends ConsumerState<LocationSearchScreen> {
  final _pickupController = TextEditingController(text: 'Current Location');
  final _dropoffController = TextEditingController();
  final _pickupFocusNode = FocusNode();
  final _dropoffFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isPickupFocused = false;
  bool _showSuggestions = false;
  Timer? _debounce;

  LatLng? _pickupLatLng = const LatLng(19.0760, 72.8777); 
  LatLng? _dropoffLatLng;
  List<LatLng> _routePoints = [];

  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(19.0760, 72.8777);

  final List<Map<String, dynamic>> _recentLocations = [
    {
      'name': 'Home',
      'address': '123 Main Street, Mumbai',
      'lat': 19.0760,
      'lng': 72.8777,
      'icon': Icons.home_rounded,
    },
    {
      'name': 'Office',
      'address': '456 Business Park, Mumbai',
      'lat': 19.0176,
      'lng': 72.8561,
      'icon': Icons.work_rounded,
    },
  ];

  final List<Map<String, dynamic>> _popularLocations = [
    {
      'name': 'Gateway of India',
      'address': 'Apollo Bandar, Colaba, Mumbai',
      'lat': 18.9220,
      'lng': 72.8347,
      'icon': Icons.location_on_rounded,
    },
    {
      'name': 'Marine Drive',
      'address': 'Netaji Subhash Chandra Bose Road, Mumbai',
      'lat': 18.9432,
      'lng': 72.8235,
      'icon': Icons.location_on_rounded,
    },
    {
      'name': 'Mumbai Central',
      'address': 'Mumbai Central Station, Mumbai',
      'lat': 18.9712,
      'lng': 72.8197,
      'icon': Icons.train_rounded,
    },
    {
      'name': 'Chhatrapati Shivaji Terminus',
      'address': 'Fort, Mumbai, Maharashtra',
      'lat': 18.9398,
      'lng': 72.8355,
      'icon': Icons.train_rounded,
    },
    {
      'name': 'Bandra Kurla Complex',
      'address': 'BKC, Bandra East, Mumbai',
      'lat': 19.0596,
      'lng': 72.8656,
      'icon': Icons.business_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _dropoffFocusNode.requestFocus();
    _pickupFocusNode.addListener(_onFocusChanged);
    _dropoffFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    final hasFocus = _pickupFocusNode.hasFocus || _dropoffFocusNode.hasFocus;
    
    // Only update _isPickupFocused when a field GAINS focus
    if (_pickupFocusNode.hasFocus) _isPickupFocused = true;
    if (_dropoffFocusNode.hasFocus) _isPickupFocused = false;
    
    if (hasFocus) {
      // Show suggestions immediately when a field gains focus
      setState(() {
        _showSuggestions = true;
        final controller = _isPickupFocused ? _pickupController : _dropoffController;
        if (controller.text.isEmpty || controller.text == 'Current Location') {
          _searchResults = [..._recentLocations, ..._popularLocations];
        }
      });
    } else {
      // DELAY hiding suggestions so tap events on the list items
      // have time to fire before the widget is removed from the tree
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted && !_pickupFocusNode.hasFocus && !_dropoffFocusNode.hasFocus) {
          setState(() => _showSuggestions = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.removeListener(_onFocusChanged);
    _dropoffFocusNode.removeListener(_onFocusChanged);
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty || query == 'Current Location') {
      if (mounted) {
        setState(() {
          _searchResults = [..._recentLocations, ..._popularLocations];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isSearching = true);

    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final baseUrl = AppConfig.apiBaseUrl;
      final url = '$baseUrl/api/maps/autocomplete?input=${Uri.encodeComponent(query)}&key=$apiKey&components=country:in';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body);
        final List predictions = data['predictions'] ?? [];
        setState(() {
          _searchResults = predictions.map((item) => {
            'name': item['structured_formatting']['main_text'] as String,
            'address': item['description'] as String,
            'place_id': item['place_id'] as String,
            'icon': Icons.location_on_rounded,
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _selectLocation(Map<String, dynamic> location) async {
    // Save which field was focused BEFORE any async work
    final fillingPickup = _isPickupFocused;
    
    LatLng target;
    // Use the full address for input display
    String displayName = location['address'] ?? location['name'] ?? 'Selected Location';

    if (location.containsKey('lat') && location.containsKey('lng')) {
      target = LatLng(location['lat'], location['lng']);
    } else if (location.containsKey('place_id')) {
      if (mounted) setState(() => _isSearching = true);
      try {
        final apiKey = AppConfig.googleMapsApiKey;
        final baseUrl = AppConfig.apiBaseUrl;
        final url = '$baseUrl/api/maps/details?place_id=${location['place_id']}&key=$apiKey&fields=geometry';
        final response = await http.get(Uri.parse(url));
        final data = json.decode(response.body);
        final loc = data['result']['geometry']['location'];
        target = LatLng(loc['lat'], loc['lng']);
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
        return;
      }
    } else {
      return;
    }

    _mapController.move(target, 15.0);

    if (!mounted) return;
    setState(() {
      if (fillingPickup) {
        _pickupController.text = displayName;
        _pickupLatLng = target;
        _pickupFocusNode.unfocus();
      } else {
        _dropoffController.text = displayName;
        _dropoffLatLng = target;
        _dropoffFocusNode.unfocus();
      }
      _showSuggestions = false;
      _searchResults = [];
      _isSearching = false;
    });

    if (_pickupLatLng != null && _dropoffLatLng != null) {
      _fetchRoute();
    }
    
    // Auto-focus next field after a short delay
    if (fillingPickup && _dropoffController.text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _dropoffFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (mounted) setState(() => _isSearching = true);
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      if (pos != null) {
        final address = await LocationService.getAddressFromLatLng(pos.latitude, pos.longitude);
        setState(() => _isSearching = false);
        _selectLocation({
          'name': address.split(',')[0],
          'address': address,
          'lat': pos.latitude,
          'lng': pos.longitude,
        });
      } else {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not fetch location')));
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;
    
    setState(() => _isSearching = true);
    try {
      final origin = "${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}";
      final dest = "${_dropoffLatLng!.latitude},${_dropoffLatLng!.longitude}";
      final apiKey = AppConfig.googleMapsApiKey;
      final baseUrl = AppConfig.apiBaseUrl;
      
      // Use proxy on Web, direct on Mobile
      final url = kIsWeb 
          ? "$baseUrl/api/maps/directions?origin=$origin&destination=$dest&key=$apiKey"
          : "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&key=$apiKey";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final points = data['routes'][0]['overview_polyline']['points'];
          setState(() {
            _routePoints = _decodePolyline(points);
          });
          
          // Fit map to route
          if (_routePoints.isNotEmpty) {
            final bounds = LatLngBounds.fromPoints(_routePoints);
            _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
          }
        }
      }
    } catch (e) {
      debugPrint("Route error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lat += dlat;
      shift = 0; result = 0;
      do { b = encoded.codeUnitAt(index++) - 63; result |= (b & 0x1f) << shift; shift += 5; } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1)); lng += dlng;
      
      double latVal = lat / 100000.0;
      double lngVal = lng / 100000.0;
      if (latVal > 90) latVal = 90;
      if (latVal < -90) latVal = -90;
      if (lngVal > 180) lngVal = 180;
      if (lngVal < -180) lngVal = -180;
      polyline.add(LatLng(latVal, lngVal));
    }
    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 15.0,
                onPositionChanged: (position, _) => _mapCenter = position.center,
                onTap: (_, __) {
                  // Dismiss suggestions when tapping map
                  _pickupFocusNode.unfocus();
                  _dropoffFocusNode.unfocus();
                  setState(() => _showSuggestions = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                if (_routePoints.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(points: _routePoints, color: Colors.blue[600]!, strokeWidth: 5),
                  ])
                else if (_pickupLatLng != null && _dropoffLatLng != null)
                  PolylineLayer(polylines: [
                    Polyline(points: [_pickupLatLng!, _dropoffLatLng!], color: Colors.black26, strokeWidth: 3),
                  ]),
                MarkerLayer(markers: [
                  if (_pickupLatLng != null)
                    Marker(point: _pickupLatLng!, child: const Icon(Icons.radio_button_checked, color: Colors.blue, size: 20)),
                  if (_dropoffLatLng != null)
                    Marker(point: _dropoffLatLng!, child: const Icon(Icons.location_on, color: Colors.red, size: 30)),
                ]),
              ],
            ),
          ),

          // Center pin (when no location is selected)
          if (_pickupLatLng == null || _dropoffLatLng == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)),
                  child: const Icon(Icons.navigation, color: Colors.white, size: 24),
                ),
              ),
            ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'back',
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.white,
              child: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),

          // My Location button
          Positioned(
            bottom: _showSuggestions ? 60 : 220,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'loc',
              onPressed: _useCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // ─── Bottom Panel: Input fields + suggestions ───
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loading indicator
                    if (_isSearching)
                      const LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        minHeight: 2,
                      ),

                    // Input fields
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dots connector
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Column(
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                ),
                                Container(width: 2, height: 30, color: Colors.grey[300]),
                                Container(
                                  width: 10, height: 10,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text fields
                          Expanded(
                            child: Column(
                              children: [
                                _buildSearchField(
                                  controller: _pickupController,
                                  focusNode: _pickupFocusNode,
                                  hint: 'Pick Location',
                                  isPickup: true,
                                ),
                                Divider(height: 1, color: Colors.grey[200]),
                                _buildSearchField(
                                  controller: _dropoffController,
                                  focusNode: _dropoffFocusNode,
                                  hint: 'Drop Location',
                                  isPickup: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Suggestions List ───
                    if (_showSuggestions && _searchResults.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1, indent: 56, color: Colors.grey[100]),
                          itemBuilder: (context, i) {
                            final result = _searchResults[i];
                            return InkWell(
                              onTap: () => _selectLocation(result),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        result['icon'] ?? Icons.location_on_rounded,
                                        color: Colors.grey[700],
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result['name'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            result['address'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.north_west_rounded, size: 16, color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // ─── No Suggestions: Current Location option ───
                    if (_showSuggestions && _searchResults.isEmpty && !_isSearching)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: InkWell(
                          onTap: _useCurrentLocation,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.my_location, color: Colors.blue[600], size: 20),
                                const SizedBox(width: 12),
                                const Text('Use Current Location', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // ─── Confirm Button (only when not showing suggestions) ───
                    if (!_showSuggestions)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (_pickupLatLng != null && _dropoffLatLng != null)
                                ? () {
                                    Navigator.pop(context, {
                                      'pickup': {'name': _pickupController.text, 'lat': _pickupLatLng!.latitude, 'lng': _pickupLatLng!.longitude},
                                      'dropoff': {'name': _dropoffController.text, 'lat': _dropoffLatLng!.latitude, 'lng': _dropoffLatLng!.longitude},
                                    });
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool isPickup,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onTap: () {
              // Show suggestions immediately on tap
              setState(() {
                _isPickupFocused = isPickup;
                _showSuggestions = true;
                if (controller.text.isEmpty || controller.text == 'Current Location') {
                  _searchResults = [..._recentLocations, ..._popularLocations];
                }
              });
            },
            onChanged: (val) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () => _onSearch(val));
            },
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        if (controller.text.isNotEmpty && controller.text != 'Current Location')
          GestureDetector(
            onTap: () {
              controller.clear();
              if (isPickup) {
                _pickupLatLng = null;
              } else {
                _dropoffLatLng = null;
              }
              setState(() {
                _searchResults = [..._recentLocations, ..._popularLocations];
                _showSuggestions = true;
              });
              focusNode.requestFocus();
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.close, size: 18, color: Colors.grey[400]),
            ),
          ),
      ],
    );
  }
}
