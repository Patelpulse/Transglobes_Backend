import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import '../services/socket_service.dart';
import '../services/location_service.dart';
import '../widgets/leaflet_map.dart';
import 'ride_tracking_screen.dart';
import '../services/ride_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';

class SearchingRideScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final String distance;
  final String rideMode;
  final String price;
  final String? otp;
  final String rideId;
  final Map<String, dynamic> vehicle;

  const SearchingRideScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.rideMode,
    required this.price,
    this.otp,
    required this.rideId,
    required this.vehicle,
  });

  @override
  ConsumerState<SearchingRideScreen> createState() => _SearchingRideScreenState();
}

class _SearchingRideScreenState extends ConsumerState<SearchingRideScreen> {
  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();
  StreamSubscription? _acceptedSubscription;
  StreamSubscription? _statusSubscription;
  late double _currentPrice;

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _currentPrice = double.tryParse(widget.price.replaceAll('₹', '')) ?? 0.0;
    _loadRoute();
    
    // Listen for ride acceptance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Connect to socket to join user room
      final userProfile = ref.read(fullUserProfileProvider).value;
      final userId = userProfile?.id;
      final userName = userProfile?.name;
      
      if (userId != null && userId.isNotEmpty) {
        ref.read(socketServiceProvider).connect(userId, name: userName);
      } else {
        final firebaseId = ref.read(authServiceProvider).currentUser?.uid;
        if (firebaseId != null) {
          ref.read(socketServiceProvider).connect(firebaseId, name: userName);
        }
      }

      // Join the specific ride room to receive updates for this ride
      ref.read(socketServiceProvider).joinRide(widget.rideId);

      _acceptedSubscription = ref.read(socketServiceProvider).rideAcceptedStream.listen((data) {
        if (mounted && data['rideId'].toString() == widget.rideId.toString()) {
          _navigateToTracking(data);
        }
      });

      _statusSubscription = ref.read(socketServiceProvider).rideStatusStream.listen((data) {
        // If a status update comes as 'accepted', treat it as a trigger to navigate
        if (mounted && 
            data['rideId'].toString() == widget.rideId.toString() && 
            data['status']?.toString().toLowerCase() == 'accepted') {
          _navigateToTracking(data);
        }
      });
    });
  }

  void _navigateToTracking(Map<String, dynamic> data) {
    final negotiatedFare = data['fare'];
    Map<String, dynamic> finalVehicle = widget.vehicle;
    
    if (negotiatedFare != null) {
      finalVehicle = Map<String, dynamic>.from(widget.vehicle);
      finalVehicle['price'] = negotiatedFare;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideTrackingScreen(
          pickup: widget.pickup,
          dropoff: widget.dropoff,
          vehicle: finalVehicle,
          rideId: widget.rideId,
          otp: widget.otp,
          distance: widget.distance,
          driverData: data['driver'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _acceptedSubscription?.cancel();
    _statusSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    final pickupPos = LatLng(
      _parseDouble(widget.pickup['latitude'] ?? widget.pickup['lat']),
      _parseDouble(widget.pickup['longitude'] ?? widget.pickup['lng']),
    );
    final dropoffPos = LatLng(
      _parseDouble(widget.dropoff['latitude'] ?? widget.dropoff['lat']),
      _parseDouble(widget.dropoff['longitude'] ?? widget.dropoff['lng']),
    );

    try {
      final routeData = await LocationService.getRouteData(pickupPos, dropoffPos);
      if (mounted) {
        setState(() {
          final List<dynamic> rawPoints = routeData['points'] ?? [];
          _routePoints = rawPoints.map((p) => LatLng(p[0], p[1])).toList();
        });
        _fitBounds();
      }
    } catch (e) {
      debugPrint("Error loading route: $e");
    }
  }

  void _fitBounds() {
    if (_routePoints.isEmpty) return;
    try {
      final validPoints = _routePoints.where((p) => 
        p.latitude >= -90 && p.latitude <= 90 && 
        p.longitude >= -180 && p.longitude <= 180
      ).toList();

      if (validPoints.length < 2) return;

      final bounds = LatLngBounds.fromPoints(validPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 40, bottom: 200, left: 40, right: 40),
        ),
      );
    } catch (e) {
      debugPrint("Could not fit bounds: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickupLat = _parseDouble(widget.pickup['latitude'] ?? widget.pickup['lat']);
    final pickupLng = _parseDouble(widget.pickup['longitude'] ?? widget.pickup['lng']);
    final dropoffLat = _parseDouble(widget.dropoff['latitude'] ?? widget.dropoff['lat']);
    final dropoffLng = _parseDouble(widget.dropoff['longitude'] ?? widget.dropoff['lng']);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background - Dynamic Road Map
          Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: LeafletMap(
                mapController: _mapController,
                location: {'lat': pickupLat, 'lng': pickupLng},
                polylines: [
                  if (_routePoints.isNotEmpty)
                    Polyline(
                      points: _routePoints,
                      color: context.theme.primaryColor,
                      strokeWidth: 4,
                    ),
                ],
                markers: [
                  Marker(
                    point: LatLng(pickupLat, pickupLng),
                    width: 12, height: 12,
                    child: Container(decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  ),
                  Marker(
                    point: LatLng(dropoffLat, dropoffLng),
                    width: 12, height: 12,
                    child: Container(decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
                  ),
                ],
              ),
            ),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "Booking Request",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildStatusSection(),
                        const SizedBox(height: 48),
                        _buildTripSummaryCard(),
                        const SizedBox(height: 32),
                        if (widget.otp != null) _buildOtpSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return Column(
      children: [
        SizedBox(
          height: 80, width: 80,
          child: CircularProgressIndicator(color: context.theme.primaryColor, strokeWidth: 6),
        ),
        const SizedBox(height: 32),
        const Text(
          "Finding your ride...",
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Connecting with nearby drivers",
          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTripSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationRow(Icons.my_location, "Pickup", widget.pickup['name'] ?? widget.pickup['address'] ?? ""),
          const Padding(
            padding: EdgeInsets.only(left: 11, top: 4, bottom: 4),
            child: SizedBox(height: 20, child: VerticalDivider(color: Colors.white24, thickness: 1)),
          ),
          _buildLocationRow(Icons.location_on, "Dropoff", widget.dropoff['name'] ?? widget.dropoff['address'] ?? ""),
          const Divider(color: Colors.white10, height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem("Distance", widget.distance),
              _buildDetailItem("Ride Mode", widget.rideMode),
              _buildDetailItem("Price", "₹${_currentPrice.toStringAsFixed(0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 22),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("RIDE OTP", style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(widget.otp!, style: const TextStyle(color: Colors.black, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 12)),
          const SizedBox(height: 8),
          const Text("Share with driver to start ride", style: TextStyle(color: Colors.black38, fontSize: 11)),
        ],
      ),
    );
  }


  Widget _buildFareAdjustmentSection() {
    return Column(
      children: [
        const Text(
          "Increase fare to find a driver faster",
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAdjustmentButton(10),
            _buildAdjustmentButton(20),
            _buildAdjustmentButton(30),
          ],
        ),
      ],
    );
  }

  Widget _buildAdjustmentButton(int amount) {
    return InkWell(
      onTap: () => _increaseFare(amount),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Text(
          "+$amount",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  Future<void> _increaseFare(int amount) async {
    try {
      final res = await ref.read(rideServiceProvider).updateFare(widget.rideId, amount);
      if (res['success'] == true) {
        setState(() {
          _currentPrice += amount;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fare increased to ₹${_currentPrice.toStringAsFixed(0)}"),
            backgroundColor: context.theme.primaryColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error increasing fare: $e");
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFareAdjustmentSection(),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.white.withOpacity(0.2))),
            ),
            child: const Text("CANCEL REQUEST", style: TextStyle(color: Colors.white60, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
