import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import 'ride_tracking_screen.dart';
import '../widgets/leaflet_map.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/socket_service.dart';
import '../providers/user_provider.dart';
import 'searching_ride_screen.dart';

class RideBookingScreen extends ConsumerStatefulWidget {
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
  ConsumerState<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends ConsumerState<RideBookingScreen> {
  String _selectedVehicle = 'economy';
  String _paymentMode = 'cash'; // New payment state
  bool _isSearching = false;
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  double _routeDistance = 0.0;
  double _routeDurationMin = 0.0;
  StreamSubscription? _socketSubscription;
  StreamSubscription? _connectionSub;
  String? _currentRideId;
  String? _currentOtp;

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    if (_vehicles.isNotEmpty) {
      _selectedVehicle = _vehicles.first['id'];
    }

    final pickupPos = LatLng(
      _parseDouble(widget.pickup['lat']),
      _parseDouble(widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['lat']),
      _parseDouble(widget.dropoff['lng']),
    );

    _routePoints = [pickupPos, dropoffPos];

    _loadRoute();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _fitBounds();
      });
      
      // Connect socket
      final socketService = ref.read(socketServiceProvider);
      final userProfile = ref.read(fullUserProfileProvider).value;
      final userId = userProfile?.id; // This is the MongoDB _id
      final userName = userProfile?.name;
      
      if (userId != null && userId.isNotEmpty) {
        socketService.connect(userId, name: userName);
      } else {
        // Fallback to Firebase UID if MongoDB ID is not available yet
        final firebaseId = ref.read(authServiceProvider).currentUser?.uid;
        if (firebaseId != null) {
          socketService.connect(firebaseId, name: userName);
        }
      }

      _connectionSub?.cancel();
      _connectionSub = socketService.connectionSuccessStream.listen((data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Connected successfully!'),
              backgroundColor: Colors.blueAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    });
  }

  Future<void> _loadRoute() async {
    final pickupPos = LatLng(
      _parseDouble(widget.pickup['lat']),
      _parseDouble(widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['lat']),
      _parseDouble(widget.dropoff['lng']),
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

    try {
      // Validate points before creating bounds to prevent crash if coordinates are invalid
      final validPoints = _routePoints.where((p) => 
        p.latitude >= -90 && p.latitude <= 90 && 
        p.longitude >= -180 && p.longitude <= 180
      ).toList();

      if (validPoints.length < 2) {
        debugPrint("Not enough valid points to fit bounds");
        return;
      }

      final bounds = LatLngBounds.fromPoints(validPoints);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(
            top: 60,
            bottom: 300, 
            left: 30,
            right: 30,
          ),
        ),
      );
    } catch (e) {
      debugPrint("Could not fit bounds: $e");
    }
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
        'id': 'economy',
        'name': 'Transglobe',
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

  Future<void> _startBooking() async {
    setState(() => _isSearching = true);
    
    // Listen for ride acceptance
    _socketSubscription?.cancel();
    _socketSubscription = ref.read(socketServiceProvider).rideAcceptedStream.listen(_handleRideAccepted);

    try {
      final apiService = ref.read(apiServiceProvider);
      
      final response = await apiService.post('/api/ride/ride-request', {
        'locations': {
          'pickup': {
            'title': widget.pickup['name'] ?? 'Pickup',
            'address': widget.pickup['address'] ?? widget.pickup['name'],
            'latitude': widget.pickup['lat'],
            'longitude': widget.pickup['lng'],
          },
          'dropoff': {
            'title': widget.dropoff['name'] ?? 'Dropoff',
            'address': widget.dropoff['address'] ?? widget.dropoff['name'],
            'latitude': widget.dropoff['lat'],
            'longitude': widget.dropoff['lng'],
          }
        },
        'rideMode': _selectedVehicle,
        'paymentMode': _paymentMode,
        'distance': '${_routeDistance.toStringAsFixed(1)} km',
        'fare': num.tryParse(_selectedVehicleData['price'].toString()) ?? 0,
      });

      if (mounted) {
        if (response != null && response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification: Data saved successfully in MongoDB!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _currentRideId = response['data']['_id'];
            _currentOtp = response['data']['otp']?.toString();
            _isSearching = false;
          });

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchingRideScreen(
                  pickup: widget.pickup,
                  dropoff: widget.dropoff,
                  distance: '${_routeDistance.toStringAsFixed(1)} km',
                  rideMode: _selectedVehicleData['name'],
                  price: "₹${_selectedVehicleData['price']}",
                  otp: _currentOtp,
                  rideId: _currentRideId!,
                  vehicle: _selectedVehicleData,
                ),
              ),
            );
          }

        } else {
          setState(() => _isSearching = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to request ride. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking error: $e')),
        );
      }
    }
  }

  void _handleRideAccepted(dynamic data) {
    print("User App Received Acceptance: $data");
    if (mounted && data['rideId'] == _currentRideId) {
      final negotiatedFare = data['fare'];
      Map<String, dynamic> finalVehicle = _selectedVehicleData;
      
      if (negotiatedFare != null) {
        finalVehicle = Map<String, dynamic>.from(_selectedVehicleData);
        finalVehicle['price'] = negotiatedFare;
      }

      _completeBooking(data['rideId'], driverData: data['driver'], otp: _currentOtp, vehicleOverride: finalVehicle);
    }
  }

  void _completeBooking(String rideId, {Map<String, dynamic>? driverData, String? otp, Map<String, dynamic>? vehicleOverride}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideTrackingScreen(
          pickup: widget.pickup,
          dropoff: widget.dropoff,
          vehicle: vehicleOverride ?? _selectedVehicleData,
          rideId: rideId,
          otp: otp,
          driverData: driverData,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _connectionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pickupPos = LatLng(
      _parseDouble(widget.pickup['lat']),
      _parseDouble(widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['lat']),
      _parseDouble(widget.dropoff['lng']),
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
                      'lat': _parseDouble(widget.pickup['lat']),
                      'lng': _parseDouble(widget.pickup['lng']),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Choose a ride",
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Rides we think you'll like",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                        // Promotion
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer, color: Color(0xFF1E8E3E), size: 18),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  "100% off your next 2 rides. Up to ₹300 per ri...",
                                  style: TextStyle(color: Color(0xFF1E8E3E), fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.info_outline, color: Color(0xFF1E8E3E), size: 16),
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
                                onTap: () => setState(() => _selectedVehicle = v['id']),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: isSelected ? Border.all(color: Colors.black, width: 2) : Border.all(color: Colors.transparent, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                    color: isSelected ? Colors.white : Colors.transparent,
                                  ),
                                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(v['icon'] as IconData, size: 48, color: Colors.black87),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                const SizedBox(width: 6),
                                                Icon(Icons.person, size: 14, color: Colors.black.withOpacity(0.6)),
                                                Text(v['capacity'] ?? "1", style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.6), fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              "${v['eta']} • ${v['time'].split('•')[0]}",
                                              style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                            if (v['id'] == 'economy')
                                              const Text("Wait a little for discounted rides", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text("₹${v['price']}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                                          if (v['oldPrice'] != null)
                                            Text("₹${v['oldPrice']}", style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough)),
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
                        InkWell(
                          onTap: _showPaymentPicker,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  _paymentMode == 'cash' 
                                    ? Icons.money 
                                    : _paymentMode == 'upi' 
                                      ? Icons.account_balance_wallet
                                      : Icons.wallet, 
                                  color: Colors.green
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _paymentMode.toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
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
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _isSearching
                                  ? "Searching..."
                                  : "Choose ${_selectedVehicleData['name']}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Removed the embedded _buildSearchingOverlay since we now push a separate page

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLabel(String name, bool isPickup) {
    if (isPickup) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2), width: 1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("2", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                      Text("min", style: TextStyle(color: Colors.white, fontSize: 8)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Text(
                        "From ${name.split(',')[0]}",
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "To ${name.split(',')[0]}",
                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: Colors.black, size: 14),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.rectangle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ],
      );
    }
  }

  void _showPaymentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select Payment Method",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.money, color: Colors.green),
              title: const Text("Cash"),
              trailing: _paymentMode == 'cash' ? const Icon(Icons.check_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _paymentMode = 'cash');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: const Text("UPI"),
              trailing: _paymentMode == 'upi' ? const Icon(Icons.check_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _paymentMode = 'upi');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallet, color: Colors.orange),
              title: const Text("Wallet"),
              trailing: _paymentMode == 'wallet' ? const Icon(Icons.check_circle, color: Colors.black) : null,
              onTap: () {
                setState(() => _paymentMode = 'wallet');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
