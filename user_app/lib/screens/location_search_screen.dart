import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../services/location_service.dart';

class LocationSearchScreen extends StatefulWidget {
  final String title;

  const LocationSearchScreen({super.key, required this.title});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _pickupController = TextEditingController(text: 'Current Location');
  final _dropoffController = TextEditingController();
  final _pickupFocusNode = FocusNode();
  final _dropoffFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isPickupFocused = false;

  LatLng? _pickupLatLng = const LatLng(19.0760, 72.8777); // Default Mumbai
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
      'color': AppTheme.gradientStart,
    },
    {
      'name': 'Office',
      'address': '456 Business Park, Mumbai',
      'lat': 19.0176,
      'lng': 72.8561,
      'icon': Icons.work_rounded,
      'color': AppTheme.gradientEnd,
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
    {
      'name': 'Juhu Beach',
      'address': 'Juhu, Mumbai, Maharashtra',
      'lat': 19.0969,
      'lng': 72.8265,
      'icon': Icons.location_on_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchResults = _demoLocations;
    _dropoffFocusNode.requestFocus();
    _pickupFocusNode.addListener(() {
      if (mounted) setState(() => _isPickupFocused = _pickupFocusNode.hasFocus);
    });
    _dropoffFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isPickupFocused = !_dropoffFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
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
      String url =
          'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=10&addressdetails=1&countrycodes=in';

      if (_pickupLatLng != null) {
        final double lat = _pickupLatLng!.latitude;
        final double lng = _pickupLatLng!.longitude;
        final String viewbox = '${lng - 1},${lat + 1},${lng + 1},${lat - 1}';
        url += '&viewbox=$viewbox';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'OLA_UBER_USER_APP',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            String displayName = item['display_name'];
            List<String> parts = displayName.split(',');
            String name = parts[0].trim();
            if (name.length < 3 && parts.length > 1) {
              name = "${parts[0]}, ${parts[1]}".trim();
            }

            return {
              'name': name,
              'address': displayName,
              'lat': double.parse(item['lat']),
              'lng': double.parse(item['lon']),
              'icon': _getIconForType(item['type'] ?? ''),
            };
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'house':
      case 'residential':
      case 'apartments':
        return Icons.home_rounded;
      case 'work':
      case 'office':
      case 'commercial':
        return Icons.work_rounded;
      case 'airport':
        return Icons.flight_rounded;
      case 'station':
      case 'bus_stop':
      case 'railway':
        return Icons.directions_transit_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _selectLocation(Map<String, dynamic> location) {
    final lat = location['lat'] ?? 19.0760;
    final lng = location['lng'] ?? 72.8777;
    final target = LatLng(lat, lng);

    _mapController.move(target, 15.0);

    if (_isPickupFocused) {
      if (mounted) {
        setState(() {
          _pickupController.text = location['name'];
          _pickupLatLng = target;
          _searchResults = []; // Hide popup
          _pickupFocusNode.unfocus();
          _dropoffFocusNode.requestFocus();
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _dropoffController.text = location['name'];
          _dropoffLatLng = target;
          _searchResults = []; // Hide popup
        });
      }

      // Briefly show the line and locations before popping if needed,
      // or just wait for confirm button. The user asked "When user select the pop up location then do not show that location"
      // which I assume means clear search results.
    }
  }

  Future<void> _useCurrentLocation() async {
    if (mounted) setState(() => _isSearching = true);
    final pos = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() => _isSearching = false);
      if (pos != null) {
        final location = {
          'name': 'Current Location',
          'address': 'Using GPS',
          'lat': pos.latitude,
          'lng': pos.longitude,
          'isCurrent': true,
        };
        _selectLocation(location);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fetch current location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Fullscreen Map Background (OpenStreetMap)
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 15.0,
                onPositionChanged: (position, hasGesture) {
                  _mapCenter = position.center;
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.package.olauber',
                ),

                // Connecting Black Line
                if (_pickupLatLng != null && _dropoffLatLng != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_pickupLatLng!, _dropoffLatLng!],
                        color: Colors.black,
                        strokeWidth: 4,
                      ),
                    ],
                  ),

                // Markers for Fixed Locations
                MarkerLayer(
                  markers: [
                    if (_pickupLatLng != null)
                      Marker(
                        point: _pickupLatLng!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.radio_button_checked,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                    if (_dropoffLatLng != null)
                      Marker(
                        point: _dropoffLatLng!,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Custom Center Indicator (Modern Pointer) - Only show when not both points are set or if specifically choosing on map
          if (_pickupLatLng == null || _dropoffLatLng == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.navigation,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black),
              ),
            ),
          ),

          // 4. Bottom Search Interface
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.grey[300],
                          ),
                          const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 18,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PICKUP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                                letterSpacing: 1.2,
                              ),
                            ),
                            _buildSearchField(
                              controller: _pickupController,
                              focusNode: _pickupFocusNode,
                              hint: 'My current location',
                              isPickup: true,
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Text(
                              'DROP-OFF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[500],
                                letterSpacing: 1.2,
                              ),
                            ),
                            _buildSearchField(
                              controller: _dropoffController,
                              focusNode: _dropoffFocusNode,
                              hint: 'Where should we go?',
                              isPickup: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _recentLocations.map((loc) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(loc['name']),
                            avatar: Icon(
                              loc['icon'] as IconData,
                              size: 14,
                              color: Colors.black87,
                            ),
                            backgroundColor: Colors.grey[100],
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onPressed: () => _selectLocation(loc),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_dropoffLatLng != null) {
                          Navigator.pop(context, {
                            'pickup': {
                              'name': _pickupController.text,
                              'lat':
                                  _pickupLatLng?.latitude ??
                                  _mapCenter.latitude,
                              'lng':
                                  _pickupLatLng?.longitude ??
                                  _mapCenter.longitude,
                            },
                            'dropoff': {
                              'name': _dropoffController.text,
                              'lat': _dropoffLatLng!.latitude,
                              'lng': _dropoffLatLng!.longitude,
                            },
                          });
                        } else {
                          // Allow pinning current map center as dropoff if field is empty
                          _selectLocation({
                            'name': 'Pinned Point',
                            'lat': _mapCenter.latitude,
                            'lng': _mapCenter.longitude,
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Current Location Floating Button
          Positioned(
            bottom: 380,
            right: 16,
            child: FloatingActionButton(
              onPressed: _useCurrentLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              heroTag: 'fab_current_loc',
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // 6. Search Results Overlay
          if (_searchResults.isNotEmpty &&
              (_pickupFocusNode.hasFocus || _dropoffFocusNode.hasFocus))
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              bottom: 400,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow,
                ),
                child: _isSearching
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final loc = _searchResults[index];
                          return ListTile(
                            leading: Icon(
                              loc['icon'] as IconData? ?? Icons.location_on,
                              color: Colors.grey,
                            ),
                            title: Text(loc['name']),
                            subtitle: Text(
                              loc['address'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectLocation(loc),
                          );
                        },
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
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: (val) {
        if (mounted) setState(() {}); // Refresh to show clear button
        _onSearch(val);
      },
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        suffixIcon: controller.text.isNotEmpty && focusNode.hasFocus
            ? IconButton(
                icon: const Icon(Icons.cancel, size: 20, color: Colors.grey),
                onPressed: () {
                  controller.clear();
                  if (mounted) setState(() {});
                  _onSearch('');
                },
              )
            : null,
      ),
    );
  }
}
