import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  Timer? _debounce;

  LatLng? _pickupLatLng = const LatLng(19.0760, 72.8777); 
  LatLng? _dropoffLatLng;

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

  final List<Map<String, dynamic>> _demoLocations = [
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
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = _demoLocations;
    _dropoffFocusNode.requestFocus();
    _pickupFocusNode.addListener(() {
      if (mounted && _pickupFocusNode.hasFocus) {
        setState(() {
          _isPickupFocused = true;
          _searchResults = _demoLocations;
        });
      }
    });
    _dropoffFocusNode.addListener(() {
      if (mounted && _dropoffFocusNode.hasFocus) {
        setState(() {
          _isPickupFocused = false;
          _searchResults = _demoLocations;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = _demoLocations;
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
            'name': item['structured_formatting']['main_text'],
            'address': item['description'],
            'place_id': item['place_id'],
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
    LatLng target;
    String displayAddress = location['address'] ?? location['name'] ?? 'Selected Location';

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

    setState(() {
      if (_isPickupFocused) {
        _pickupController.text = displayAddress;
        _pickupLatLng = target;
        _pickupFocusNode.unfocus();
        _dropoffFocusNode.requestFocus();
      } else {
        _dropoffController.text = displayAddress;
        _dropoffLatLng = target;
        _dropoffFocusNode.unfocus();
      }
      _searchResults = [];
      _isSearching = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 15.0,
                onPositionChanged: (position, _) => _mapCenter = position.center,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                if (_pickupLatLng != null && _dropoffLatLng != null)
                  PolylineLayer(polylines: [
                    Polyline(points: [_pickupLatLng!, _dropoffLatLng!], color: Colors.black, strokeWidth: 4),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20)]),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.more_vert, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildSearchField(controller: _pickupController, focusNode: _pickupFocusNode, hint: 'Pickup', isPickup: true),
                            const Divider(),
                            _buildSearchField(controller: _dropoffController, focusNode: _dropoffFocusNode, hint: 'Drop-off', isPickup: false),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pickupLatLng != null && _dropoffLatLng != null) {
                          Navigator.pop(context, {
                            'pickup': {'name': _pickupController.text, 'lat': _pickupLatLng!.latitude, 'lng': _pickupLatLng!.longitude},
                            'dropoff': {'name': _dropoffController.text, 'lat': _dropoffLatLng!.latitude, 'lng': _dropoffLatLng!.longitude},
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: const Text('Confirm Location'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 300, right: 16,
            child: FloatingActionButton(
              heroTag: 'loc',
              onPressed: _useCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
          if (_searchResults.isNotEmpty && (_pickupFocusNode.hasFocus || _dropoffFocusNode.hasFocus))
            Positioned(
              top: 150, left: 16, right: 16, bottom: 350,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_searchResults[i]['name']),
                    subtitle: Text(_searchResults[i]['address'], maxLines: 1),
                    onTap: () => _selectLocation(_searchResults[i]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField({required TextEditingController controller, required FocusNode focusNode, required String hint, required bool isPickup}) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (val) {
        if (_debounce?.isActive ?? false) _debounce!.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () => _onSearch(val));
      },
      decoration: InputDecoration(hintText: hint, border: InputBorder.none),
    );
  }
}
