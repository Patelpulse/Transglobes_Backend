import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';
import 'rating_screen.dart';
import '../widgets/leaflet_map.dart';
import '../services/location_service.dart';

class RideTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final Map<String, dynamic> vehicle;
  final String rideId;

  const RideTrackingScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.vehicle,
    required this.rideId,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final MapController _mapController = MapController();
  String _rideStatus = 'On the way';
  String _driverETA = '2 mins away';
  List<LatLng> _routePoints = [];

  final Map<String, dynamic> _driver = {
    'name': 'John Doe',
    'rating': '4.9',
    'vehicle': 'Toyota Camry',
    'plate': 'ABC-1234',
    'otp': '4821',
    'image':
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDJYv3F4UhjvGfqNIe7wYrpy9Ne1IGp-py8rBlt8GJVbtIXq4uVXkw9bHzbJd394nwKIe4kvfAtLnA4q9Wuw-QrfIB-8yv6ofEe3900dLT2ExAaejywLyI2ACN37lR55Uwtcd2MVshT8__Zsk8fhbdkPS8DDjUTnTbe6ceI1A7MxcAVpJeEAFEUarUO4YeS-Y8UEAjuLFTRBquUUl7MaLK15bVUMCldIvY4eCUYAodELV-MX_LcV95tjVS9OPqlQ59JVav9i-DHZJ4',
  };

  @override
  void initState() {
    super.initState();
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
      });
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
          top: 150,
          bottom: 450,
          left: 50,
          right: 50,
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
      body: Stack(
        children: [
          // Map Background
          Positioned.fill(
            child: LeafletMap(
              mapController: _mapController,
              location: {'lat': pickupPos.latitude, 'lng': pickupPos.longitude},
              polylines: [
                Polyline(
                  points: _routePoints,
                  strokeWidth: 4.0,
                  color: context.theme.primaryColor,
                  strokeCap: StrokeCap.round,
                ),
              ],
              markers: [
                Marker(
                  point: pickupPos,
                  width: 12,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.theme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                Marker(
                  point: dropoffPos,
                  width: 12,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.rectangle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Top App Bar Area
          SafeArea(
            child: Column(children: [_buildTopAppBar(), _buildStatusBanner()]),
          ),

          // Search Destination Floating Overlay
          Positioned(
            bottom: 340,
            left: 16,
            right: 16,
            child: _buildMapOverlaySearch(),
          ),

          // Map Controls
          Positioned(right: 16, bottom: 420, child: _buildMapControls()),

          // Bottom Sheet (Persistent)
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildDriverBottomSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.transparent,
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
              "Ride Tracking",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.theme.dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Ride Status: $_rideStatus",
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _driverETA,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Flexible(
            child: TextButton(
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "View Route",
                    style: TextStyle(
                      color: context.theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: context.theme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapOverlaySearch() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.search, color: context.colors.textSecondary),
          ),
          Expanded(
            child: Text(
              "Search destination...",
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: IconButton(
            icon: Icon(Icons.add, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            border: Border(
              top: BorderSide(
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: IconButton(
            icon: Icon(Icons.remove, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Icon(Icons.near_me, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildDriverBottomSheet() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: context.theme.dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Driver Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(_driver['image']),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driver['name'],
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.yellow,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  "${_driver['rating']} • ${_driver['vehicle']}",
                                  style: const TextStyle(
                                    color: Color(0xFF9DA6B9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _driver['plate'],
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "START OTP",
                            style: TextStyle(
                              color: context.theme.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _driver['otp'],
                            style: TextStyle(
                              color: context.theme.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildBottomActionButton(
                        label: "Message",
                        icon: Icons.chat_bubble_outline,
                        color: context.theme.cardColor,
                        textColor: context.colors.textPrimary ?? Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildBottomActionButton(
                        label: "Call Driver",
                        icon: Icons.call,
                        color: context.theme.primaryColor,
                        textColor: Colors.white,
                        isPrimary: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RatingScreen(driver: _driver),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Finish Ride",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: context.theme.dividerColor.withOpacity(0.1)),
                const SizedBox(height: 16),

                // Pickup/Dropoff
                _buildLocationDetail(
                  type: "PICKUP",
                  address:
                      widget.pickup['address'] ?? "245 E 23rd St, New York, NY",
                  color: context.theme.primaryColor,
                  isFirst: true,
                ),
                const SizedBox(height: 8),
                _buildLocationDetail(
                  type: "DROPOFF",
                  address:
                      widget.dropoff['address'] ?? "Grand Central Terminal, NY",
                  color: Colors.red,
                  isFirst: false,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    bool isPrimary = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDetail({
    required String type,
    required String address,
    required Color color,
    required bool isFirst,
  }) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            if (isFirst)
              Container(
                width: 2,
                height: 24,
                color: context.theme.dividerColor.withOpacity(0.1),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                address,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
