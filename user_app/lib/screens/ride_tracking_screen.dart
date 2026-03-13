import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/socket_service.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'dart:async';
import '../core/theme.dart';
import 'rating_screen.dart';
import 'chat_screen.dart';
import '../widgets/leaflet_map.dart';
import '../services/location_service.dart';

class RideTrackingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> dropoff;
  final Map<String, dynamic> vehicle;
  final String rideId;
  final String? otp;
  final String? distance;

  final Map<String, dynamic>? driverData;

  const RideTrackingScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.vehicle,
    required this.rideId,
    this.otp,
    this.driverData,
    this.distance,
  });

  @override
  ConsumerState<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends ConsumerState<RideTrackingScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  String _rideStatus = 'On the way';
  String _rawStatus = 'accepted';
  String _driverETA = '2 mins away';
  List<LatLng> _routePoints = [];
  StreamSubscription? _statusSubscription;
  StreamSubscription? _locationSubscription;
  LatLng? _driverPos;
  double _driverHeading = 0.0;

  late Map<String, dynamic> _driver;

  bool _hasNavigatedToRating = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize driver data
    _driver = {
      'name': widget.driverData?['name'] ?? 'Driver',
      'rating': '4.9',
      'vehicle': widget.driverData?['vehicle_name'] ?? widget.vehicle['name'] ?? 'Car',
      'plate': widget.driverData?['vehicle_number'] ?? widget.driverData?['vichle_number'] ?? 'N/A',
      'phone': widget.driverData?['phone'] ?? '',
      'otp': widget.otp ?? '----',
      'image': widget.driverData?['photo'] != null && widget.driverData!['photo'].toString().isNotEmpty
          ? widget.driverData!['photo']
          : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png', // Premium avatar
    };

    _rawStatus = widget.driverData?['status']?.toString().toLowerCase() ?? 'accepted';
    _rideStatus = _mapStatusLabel(_rawStatus);

    _loadRoute();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProfile = ref.read(fullUserProfileProvider).value;
      final userId = userProfile?.id; // This is the MongoDB _id
      final userName = userProfile?.name;
      
      if (userId != null && userId.isNotEmpty) {
        ref.read(socketServiceProvider).connect(userId, name: userName);
      } else {
        // Fallback to Firebase UID if MongoDB ID is not available yet
        final firebaseId = ref.read(authServiceProvider).currentUser?.uid;
        if (firebaseId != null) {
          ref.read(socketServiceProvider).connect(firebaseId, name: userName);
        }
      }

      // Join the specific ride room
      ref.read(socketServiceProvider).joinRide(widget.rideId);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _fitBounds();
      });

      // Listen for status updates
      _statusSubscription = ref.read(socketServiceProvider).rideStatusStream.listen((data) {
        if (data['rideId'].toString() == widget.rideId.toString()) {
          final newStatus = data['status']?.toString();
          if (newStatus != null) {
            setState(() {
              _rawStatus = newStatus.toLowerCase();
              _rideStatus = _mapStatusLabel(_rawStatus);
              if (data['driver'] != null) {
                _driver['name'] = data['driver']['name'] ?? _driver['name'];
                _driver['plate'] = data['driver']['vehicle_number'] ?? data['driver']['vichle_number'] ?? _driver['plate'];
                _driver['phone'] = data['driver']['phone'] ?? _driver['phone'];
                _driver['vehicle'] = data['driver']['vehicle_name'] ?? _driver['vehicle'];
                if (data['driver']['photo'] != null && data['driver']['photo'].toString().isNotEmpty) {
                   _driver['image'] = data['driver']['photo'];
                }
              }
              // Update OTP visibility based on raw status
              if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
                _driver['otp'] = widget.otp ?? '----';
              } else {
                _driver['otp'] = '----'; 
              }
            });
          }

          // Auto-navigate to rating if completed
          if (newStatus == 'completed' && !_hasNavigatedToRating) {
            _hasNavigatedToRating = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RatingScreen(driver: _driver),
              ),
            );
          }
        }
      });

      // Listen for driver location updates
      _locationSubscription = ref.read(socketServiceProvider).driverLocationStream.listen((data) {
        if (data['rideId'].toString() == widget.rideId.toString()) {
          setState(() {
            _driverPos = LatLng(
              (data['latitude'] as num).toDouble(),
              (data['longitude'] as num).toDouble(),
            );
            _driverHeading = (data['heading'] as num?)?.toDouble() ?? 0.0;
            
            // Calculate dynamic ETA
            final pLat = (widget.pickup['lat'] as num).toDouble();
            final pLng = (widget.pickup['lng'] as num).toDouble();
            final dLat = (widget.dropoff['lat'] as num).toDouble();
            final dLng = (widget.dropoff['lng'] as num).toDouble();

            final destination = ['accepted', 'on_the_way', 'arrived'].contains(_rawStatus) 
                ? LatLng(pLat, pLng) 
                : LatLng(dLat, dLng);
            
            _driverETA = _calculateEstimatedTime(_driverPos!, destination);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _locationSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
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

    try {
      final routeData = await LocationService.getRouteData(pickupPos, dropoffPos);
      if (mounted) {
        setState(() {
          _routePoints = routeData['points'] ?? [];
        });
        _fitBounds();
      }
    } catch (e) {
      if (mounted) _fitBounds(); // Fallback to direct bounds
    }
  }

  void _fitBounds({bool centerOnDriver = false}) {
    if (!mounted) return;

    if (centerOnDriver && _driverPos != null) {
      _animatedMapMove(_driverPos!, 16.0);
      return;
    }
    
    List<LatLng> boundsPoints = _routePoints;
    
    // Fallback bounds if route is empty
    if (boundsPoints.isEmpty || boundsPoints.length < 2) {
      boundsPoints = [
        LatLng((widget.pickup['lat'] as num).toDouble(), (widget.pickup['lng'] as num).toDouble()),
        LatLng((widget.dropoff['lat'] as num).toDouble(), (widget.dropoff['lng'] as num).toDouble()),
      ];
    }
    
    try {
      final validPoints = boundsPoints.where((p) => 
        p.latitude >= -90 && p.latitude <= 90 && 
        p.longitude >= -180 && p.longitude <= 180
      ).toList();

      if (validPoints.length < 2) return;

      final bounds = LatLngBounds.fromPoints(validPoints);
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
    } catch (e) {
      debugPrint("Could not fit bounds: $e");
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    if (!_mapController.camera.center.latitude.isFinite) return;

    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.fastOutSlowIn,
    );

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  String _mapStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Driver Accepted';
      case 'on_the_way':
        return 'Driver on the way';
      case 'arrived':
        return 'Driver has arrived';
      case 'ongoing':
        return 'Trip in progress';
      case 'completed':
        return 'Trip Completed';
      case 'cancelled':
        return 'Ride Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _calculateEstimatedTime(LatLng start, LatLng end) {
    final distanceInMeters = const Distance().as(LengthUnit.Meter, start, end);
    // Assume average speed of 30 km/h in city traffic (500 meters per minute)
    final minutes = (distanceInMeters / 500).ceil();
    
    if (minutes <= 1) {
      if (distanceInMeters < 100) return "Arriving now";
      return "1 min away";
    }
    return "$minutes mins away";
  }

  Future<void> _makeCall(String phone) async {
    if (phone.isEmpty) return;
    final Uri url = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
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
              location: _driverPos != null 
                  ? {'lat': _driverPos!.latitude, 'lng': _driverPos!.longitude}
                  : {'lat': pickupPos.latitude, 'lng': pickupPos.longitude},
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
                if (_driverPos != null)
                  Marker(
                    point: _driverPos!,
                    width: 50,
                    height: 50,
                    child: Transform.rotate(
                      angle: (_driverHeading * (3.14159 / 180)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: context.theme.primaryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Icon(
                            Icons.navigation,
                            color: context.theme.primaryColor,
                            size: 30,
                          ),
                        ],
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
          if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus))
          Flexible(
            child: TextButton(
              onPressed: () => _fitBounds(centerOnDriver: true),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Center on Driver",
                    style: TextStyle(
                      color: context.theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.my_location,
                    size: 14,
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
                    _buildCallButton(_driver['phone']),
                  ],
                ),

                const SizedBox(height: 16),
                
                if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: context.theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.theme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "SHARE OTP TO START RIDE",
                        style: TextStyle(
                          color: context.theme.primaryColor.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ..._driver['otp'].toString().split('').map((char) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              char,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Ask the driver to enter this code",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "ESTIMATED FARE: ",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "₹${widget.vehicle['price']}",
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
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
                        onTap: () {
                          // In a real app, widget.driverData?['uid'] or similar would be needed.
                          // Based on previous fixes, some drivers have 'id' (ObjectId) or 'uid' (Firebase).
                          // Here _driver is local and we'll use whatever ID we can find.
                          final driverId = widget.driverData?['uid'] ?? widget.driverData?['_id'] ?? widget.driverData?['driver_id'];
                          if (driverId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  receiverId: driverId.toString(),
                                  receiverName: _driver['name'],
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Driver information not available for chat')),
                            );
                          }
                        },
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
                        onTap: () => _makeCall(_driver['phone']),
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

  Widget _buildCallButton(String phone) {
    return GestureDetector(
      onTap: () => _makeCall(phone),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.phone, color: context.theme.primaryColor, size: 24),
      ),
    );
  }

  Widget _buildBottomActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
