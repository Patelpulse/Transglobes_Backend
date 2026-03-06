import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import 'ride_tracking_screen.dart';
import '../widgets/leaflet_map.dart';
import '../services/location_service.dart';

class RideBookingScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final String serviceType;

  const RideBookingScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.serviceType,
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  String _selectedVehicle = 'economy';
  bool _isSearching = false;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  double _routeDurationMin = 0.0;

  @override
  void initState() {
    super.initState();
    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.first['id'];
    }

    final pickupPos = LatLng(
      (widget.pickup['lat'] as num).toDouble(),
      (widget.pickup['lng'] as num).toDouble(),
    );
    final dropoffPos = LatLng(
      (widget.dropoff['lat'] as num).toDouble(),
      (widget.dropoff['lng'] as num).toDouble(),
    );

    _routePoints = [pickupPos, dropoffPos];

    _loadRoute();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _fitBounds();
      });
    });
  }

  Future<void> _loadRoute() async {
    final pickupPos = LatLng(
      (widget.pickup['lat'] as num).toDouble(),
      (widget.pickup['lng'] as num).toDouble(),
    );
    final dropoffPos = LatLng(
      (widget.dropoff['lat'] as num).toDouble(),
      (widget.dropoff['lng'] as num).toDouble(),
    );

    final routeData = await LocationService.getRouteData(pickupPos, dropoffPos);
    if (mounted) {
      setState(() {
        _routePoints = routeData['points'];
        _routeDistance = routeData['distance'];
        _routeDurationMin = routeData['duration'];
      });
      // Refit bounds once we have the detailed route
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(_routePoints);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          top: 60,
          bottom: 300, // Balanced padding to allow more zoom while clearing UI
          left: 30,
          right: 30,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _vehicles {
    if (widget.serviceType == 'truck') {
      return [
        {
          'id': 'ace',
          'name': 'Tata Ace',
          'icon': Icons.local_shipping,
          'price': 450,
          'eta': '10 min',
        },
        {
          'id': 'pickup',
          'name': 'Pickup 8ft',
          'icon': Icons.local_shipping,
          'price': 650,
          'eta': '15 min',
        },
        {
          'id': '3wheeler',
          'name': '3 Wheeler',
          'icon': Icons.moped,
          'price': 300,
          'eta': '5 min',
        },
      ];
    }
    final now = DateTime.now();
    final durationRounded = _routeDurationMin.round();
    final arrivalTime = now.add(Duration(minutes: durationRounded));
    final timeStr =
        "${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}";

    // Formatting trip duration for display
    final String tripDurationDisplay = durationRounded > 60
        ? "${(durationRounded / 60).floor()}h ${durationRounded % 60}m"
        : "$durationRounded min";

    return [
      {
        'id': 'bike_saver',
        'name': 'Bike Saver',
        'icon': Icons.two_wheeler,
        'capacity': '1',
        'price': (20 + (_routeDistance * 8)).toStringAsFixed(
          0,
        ), // Rounded to whole number for cleaner look
        'oldPrice': (25 + (_routeDistance * 8)).toStringAsFixed(0),
        'eta': '2 min away',
        'time': "$timeStr • $tripDurationDisplay",
      },
      {
        'id': 'bike',
        'name': 'Bike',
        'icon': Icons.two_wheeler,
        'capacity': '1',
        'price': (25 + (_routeDistance * 10)).toStringAsFixed(0),
        'oldPrice': (30 + (_routeDistance * 10)).toStringAsFixed(0),
        'eta': '1 min away',
        'time': "$timeStr • $tripDurationDisplay",
        'label': 'Faster',
      },
      {
        'id': 'auto',
        'name': 'Auto',
        'icon': Icons.electric_rickshaw,
        'capacity': '3',
        'price': (30 + (_routeDistance * 12)).toStringAsFixed(0),
        'oldPrice': (40 + (_routeDistance * 12)).toStringAsFixed(0),
        'eta': '2 min away',
        'time': "$timeStr • $tripDurationDisplay",
      },
      {
        'id': 'economy',
        'name': 'Transglobal Go',
        'icon': Icons.directions_car,
        'capacity': '4',
        'price': (50 + (_routeDistance * 15)).toStringAsFixed(0),
        'eta': '3 min away',
        'time': "$timeStr • $tripDurationDisplay",
      },
    ];
  }

  Map<String, dynamic> get _selectedVehicleData {
    return _vehicles.firstWhere(
      (v) => v['id'] == _selectedVehicle,
      orElse: () => _vehicles.first,
    );
  }

  void _startBooking() {
    setState(() => _isSearching = true);
    Timer(const Duration(seconds: 4), () {
      if (mounted) _completeBooking();
    });
  }

  void _completeBooking() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideTrackingScreen(
          pickup: widget.pickup,
          dropoff: widget.dropoff,
          vehicle: _selectedVehicleData,
          rideId: 'RIDE${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(
      (widget.pickup['lat'] as num).toDouble(),
      (widget.pickup['lng'] as num).toDouble(),
    );
    final dropoffPos = LatLng(
      (widget.dropoff['lat'] as num).toDouble(),
      (widget.dropoff['lng'] as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: context.colors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      "Fare Estimate",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.info_outline,
                      color: context.colors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: LeafletMap(
                    mapController: _mapController,
                    location: {
                      'lat': (widget.pickup['lat'] as num).toDouble(),
                      'lng': (widget.pickup['lng'] as num).toDouble(),
                    },
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        strokeWidth: 4.0,
                        color: Colors.black,
                        strokeCap: StrokeCap.round,
                      ),
                    ],
                    markers: [
                      Marker(
                        point: pickupPos,
                        width: 200,
                        height: 60,
                        child: _buildMapLabel(
                          widget.pickup['name'] ?? 'Pickup',
                          true,
                        ),
                      ),
                      Marker(
                        point: dropoffPos,
                        width: 200,
                        height: 60,
                        child: _buildMapLabel(
                          widget.dropoff['name'] == 'Current Location' &&
                                  widget.pickup['name'] == 'Current Location'
                              ? 'Destination'
                              : widget.dropoff['name'] ?? 'Dropoff',
                          false,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Promotion
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.local_offer,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "₹2.00 promotion applied",
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                            ],
                          ),
                        ),

                        // Vehicle List
                        SizedBox(
                          height: 300,
                          child: ListView.builder(
                            itemCount: _vehicles.length,
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            itemBuilder: (context, index) {
                              final v = _vehicles[index];
                              final isSelected = _selectedVehicle == v['id'];
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedVehicle = v['id']),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                  ),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        v['icon'] as IconData,
                                        size: 32,
                                        color: Colors.black87,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  v['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.person,
                                                  size: 14,
                                                  color: Colors.black54,
                                                ),
                                                Text(
                                                  v['capacity'] ?? "1",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                                if (v['label'] != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[600],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      v['label'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            Text(
                                              "${v['time']} • ${v['eta']}",
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "₹${v['price']}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (v['oldPrice'] != null)
                                            Text(
                                              "₹${v['oldPrice']}",
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Payment & Footer
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.money, color: Colors.green),
                              const SizedBox(width: 12),
                              const Text(
                                "Cash",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: ElevatedButton(
                            onPressed: _startBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              _isSearching
                                  ? "Searching..."
                                  : "Choose ${_selectedVehicleData['name']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isSearching) _buildSearchingOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLabel(String name, bool isPickup) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  name.split(',')[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.black),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: isPickup ? BoxShape.circle : BoxShape.rectangle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: context.theme.primaryColor),
            const SizedBox(height: 24),
            const Text(
              "Searching for nearby drivers...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Estimated wait time: ${_selectedVehicleData['eta']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () => setState(() => _isSearching = false),
              child: const Text(
                "CANCEL",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
