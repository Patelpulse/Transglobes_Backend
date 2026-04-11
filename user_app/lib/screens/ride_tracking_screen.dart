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
import '../services/ride_service.dart';
import '../services/api_service.dart';
import '../models/ride_model.dart';

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
  double _currentFare = 0.0;
  String _paymentStatus = 'unpaid';
  StreamSubscription? _fareSubscription;
  StreamSubscription? _roadmapSubscription;
  List<LogisticsSegment> _segments = [];

  late Map<String, dynamic> _driver;

  bool _hasNavigatedToRating = false;

  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize driver data with Fallbacks
    _driver = {
      'id': widget.driverData?['_id'] ?? widget.driverData?['driver_id'] ?? widget.driverData?['uid'],
      'name': widget.driverData?['name']?.toString() ??'Driver',
      'rating': '4.9',
      'vehicle': (widget.driverData?['vehicle_name'] ?? widget.driverData?['vehicle_model'] ?? widget.vehicle['name'] ?? 'Car').toString(),
      'plate': (widget.driverData?['vehicle_number'] ?? widget.driverData?['vichle_number'] ?? widget.driverData?['plate'] ?? 'N/A').toString(),
      'phone': widget.driverData?['phone']?.toString() ?? '',
      'otp': widget.otp ?? '----',
      'image': widget.driverData?['photo'] != null && widget.driverData!['photo'].toString().isNotEmpty
          ? widget.driverData!['photo'].toString()
          : 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
    };

    _currentFare = _parseDouble(widget.vehicle['price']);

    _rawStatus = widget.driverData?['status']?.toString().toLowerCase() ?? 'accepted';
    _rideStatus = _mapStatusLabel(_rawStatus);

    _loadRoute();
    _fetchRideDetails();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authService = ref.read(authServiceProvider);
      await authService.waitForSession();
      if (!mounted) return;

      final userProfile = ref.read(fullUserProfileProvider).value;
      final userId = userProfile?.id; // This is the MongoDB _id
      final userName = userProfile?.name;
      
      if (userId != null && userId.isNotEmpty) {
        ref.read(socketServiceProvider).connect(userId, name: userName);
      } else {
        // Fallback to Firebase UID if MongoDB ID is not available yet
        final firebaseId = authService.currentUser?.uid;
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
          final newStatus = data['status']?.toString() ?? _rawStatus;
          if (mounted) {
            setState(() {
              _rawStatus = newStatus.toLowerCase();
              _rideStatus = _mapStatusLabel(_rawStatus);
              if (data['driver'] != null) {
                final d = data['driver'];
                _driver['id'] = d['driver_id'] ?? d['_id'] ?? d['uid'] ?? _driver['id'];
                _driver['name'] = d['name']?.toString() ?? _driver['name'];
                _driver['plate'] = (d['vehicle_number'] ?? d['vichle_number'] ?? d['plate'] ?? _driver['plate']).toString();
                _driver['phone'] = d['phone']?.toString() ?? _driver['phone'];
                _driver['vehicle'] = (d['vehicle_name'] ?? d['vehicle_model'] ?? _driver['vehicle']).toString();
                if (d['photo'] != null && d['photo'].toString().isNotEmpty) {
                   _driver['image'] = d['photo'].toString();
                }
              }
              if (data['paymentStatus'] != null) {
                _paymentStatus = data['paymentStatus'].toString();
              }
              // Update OTP visibility based on raw status
              if (['accepted', 'on_the_way', 'arrived'].contains(_rawStatus)) {
                _driver['otp'] = widget.otp ?? '----';
              } else {
                _driver['otp'] = '----'; 
              }
            });

            if (_rawStatus == 'completed' && !_hasNavigatedToRating) {
               _hasNavigatedToRating = true;
               Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => RatingScreen(driver: _driver, bookingId: widget.rideId),
                ),
              );
            }
          }
        }
      });

      // Listen for driver location updates
      _locationSubscription = ref.read(socketServiceProvider).driverLocationStream.listen((data) {
        if (data['rideId'].toString() == widget.rideId.toString()) {
          setState(() {
            _driverPos = LatLng(
              _parseDouble(data['latitude']),
              _parseDouble(data['longitude']),
            );
            _driverHeading = _parseDouble(data['heading']);
            
            // Calculate dynamic ETA
            final pLat = _parseDouble(widget.pickup['lat']);
            final pLng = _parseDouble(widget.pickup['lng']);
            final dLat = _parseDouble(widget.dropoff['lat']);
            final dLng = _parseDouble(widget.dropoff['lng']);

            final destination = ['accepted', 'on_the_way', 'arrived'].contains(_rawStatus) 
                ? LatLng(pLat, pLng) 
                : LatLng(dLat, dLng);
            
            _driverETA = _calculateEstimatedTime(_driverPos!, destination);
          });
        }
      });
      // Listen for fare increase
      _fareSubscription = ref.read(socketServiceProvider).fareIncreasedStream.listen((data) {
        if (data['rideId'].toString() == widget.rideId.toString()) {
          final amount = data['amount'];
          final newFareVal = data['newFare'];
          double newFareDouble = 0.0;
          if (newFareVal is num) {
            newFareDouble = newFareVal.toDouble();
          } else if (newFareVal is String) {
            newFareDouble = double.tryParse(newFareVal) ?? 0.0;
          }
          
          if (mounted) {
            setState(() {
              _currentFare = newFareDouble;
            });
            _showFareIncreaseDialog(amount, newFareDouble);
          }
        }
      });

      _roadmapSubscription = ref.read(socketServiceProvider).roadmapUpdatedStream.listen((data) {
        if (data['rideId']?.toString() == widget.rideId.toString() && mounted) {
           final List segmentsList = data['segments'] ?? [];
           setState(() {
              _segments = segmentsList.map((s) => LogisticsSegment.fromJson(s)).toList();
           });
        }
      });
    });
  }

  Future<void> _fetchRideDetails() async {
    try {
      final ride = await ref.read(rideServiceProvider).getRideById(widget.rideId);
      if (ride != null && mounted) {
        setState(() {
          _segments = ride.segments;
        });
      }
    } catch (e) {
      debugPrint("Error fetching ride details: $e");
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _locationSubscription?.cancel();
    _fareSubscription?.cancel();
    _roadmapSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
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
        LatLng(_parseDouble(widget.pickup['lat']), _parseDouble(widget.pickup['lng'])),
        LatLng(_parseDouble(widget.dropoff['lat']), _parseDouble(widget.dropoff['lng'])),
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

  void _showFareIncreaseDialog(dynamic amount, double newFare) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text("Fare Increased", style: TextStyle(color: context.colors.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Driver has increased the fare by ₹$amount.",
              style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              "New Estimated Fare: ₹${newFare.toStringAsFixed(0)}",
              style: TextStyle(
                color: context.theme.primaryColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRide() async {
    try {
      await ref.read(rideServiceProvider).cancelRide(widget.rideId);
      if (mounted) {
        setState(() {
          _rawStatus = 'cancelled';
          _rideStatus = _mapStatusLabel(_rawStatus);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride cancelled successfully.')),
        );
        // Optionally navigate back or to a different screen
        Navigator.pop(context); // Pop the tracking screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel ride: $e')),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text("Cancel Ride?", style: TextStyle(color: context.colors.textPrimary)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel this ride? This action cannot be undone.",
          style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("No", style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _cancelRide();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                  color: Colors.black,
                  strokeCap: StrokeCap.round,
                ),
              ],
              markers: [
                Marker(
                  point: pickupPos,
                  width: 220,
                  height: 80,
                  child: _buildMapLabel(widget.pickup['name'] ?? 'Pickup', true),
                ),
                Marker(
                  point: dropoffPos,
                  width: 220,
                  height: 80,
                  child: _buildMapLabel(widget.dropoff['name'] ?? 'Drop-off', false),
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
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(_driver['image']),
                          backgroundColor: context.theme.primaryColor.withOpacity(0.1),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          ),
                        ),
                      ],
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _driver['vehicle'],
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _driver['plate'],
                            style: TextStyle(
                              color: context.theme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _driver['phone'],
                            style: TextStyle(
                              color: context.colors.textSecondary?.withOpacity(0.7) ?? Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildCallButton(_driver['phone']),
                        const SizedBox(width: 8),
                        _buildChatButton(),
                      ],
                    ),
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
                      "₹${_currentFare.toStringAsFixed(0)}",
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
                  onPressed: () async {
                    if (_paymentStatus == 'unpaid') {
                      // Perform payment
                      try {
                        await ref.read(rideServiceProvider).updateRideStatus(widget.rideId, _rawStatus); 
                        // In a real app we'd call the payRide API
                        await ref.read(apiServiceProvider).put('/api/ride/rides/${widget.rideId}/pay', {});
                        if (mounted) {
                          setState(() {
                            _paymentStatus = 'paid';
                          });
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful!')));
                          
                          // FeedBack/Rating logic
                          Future.delayed(const Duration(seconds: 1), () {
                            if (mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RatingScreen(driver: _driver, bookingId: widget.rideId),
                                ),
                              );
                            }
                          });
                        }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment Failed: $e')));
                      }
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RatingScreen(driver: _driver, bookingId: widget.rideId),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentStatus == 'unpaid' ? context.theme.primaryColor : Colors.green.withOpacity(0.1),
                    foregroundColor: _paymentStatus == 'unpaid' ? Colors.white : Colors.green,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _paymentStatus == 'unpaid' ? 8 : 0,
                    shadowColor: context.theme.primaryColor.withOpacity(0.4),
                  ),
                  child: Text(
                    _paymentStatus == 'unpaid' ? "Pay ₹${_currentFare.toStringAsFixed(0)}" : "Ride Completed",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                
                if (_rawStatus == 'accepted' || _rawStatus == 'on_the_way' || _rawStatus == 'arrived')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => _showCancelDialog(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Cancel Ride",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: context.theme.dividerColor.withOpacity(0.1)),
                const SizedBox(height: 16),

                if (_segments.isNotEmpty) ...[
                  _buildRoadmapTimeline(),
                  const Divider(height: 48),
                ],

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
          color: context.theme.primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.phone, color: context.theme.primaryColor, size: 24),
      ),
    );
  }

  Widget _buildChatButton() {
    return GestureDetector(
      onTap: () {
        // Preference: Use the ID we have in _driver first, then fallback to widget data
        final driverId = _driver['id'] ?? widget.driverData?['_id'] ?? widget.driverData?['driver_id'] ?? widget.driverData?['uid'];
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
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.chat_outlined, color: Colors.blue, size: 24),
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

  Widget _buildMapLabel(String name, bool isPickup) {
    String cleanName = name.contains(',') ? name.split(',')[0] : name;
    if (isPickup) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border(right: BorderSide(color: Colors.white.withOpacity(0.2))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("2", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("min", style: TextStyle(color: Colors.white, fontSize: 8)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          cleanName, 
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
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
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    cleanName, 
                    style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.black, size: 14),
              ],
            ),
          ),
          Container(width: 2, height: 6, color: Colors.black),
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: Colors.black, shape: BoxShape.rectangle, border: Border.all(color: Colors.white, width: 2)),
          ),
        ],
      );
    }
  }

  Widget _buildRoadmapTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SHIPMENT ROADMAP",
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${_segments.length} SEGMENTS",
                style: TextStyle(
                  color: context.theme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _segments.length,
          itemBuilder: (context, index) {
            final segment = _segments[index];
            final isCompleted = segment.status == 'completed';
            final isCurrent = segment.status == 'ongoing';
            final isLast = index == _segments.length - 1;

            return IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : (isCurrent ? context.theme.primaryColor : Colors.grey[800]),
                          shape: BoxShape.circle,
                          border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : _getSegmentIcon(segment.mode),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: isCompleted ? Colors.green : Colors.grey[800],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                segment.mode.toUpperCase(),
                                style: TextStyle(
                                  color: isCurrent ? context.theme.primaryColor : context.colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(segment.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  segment.status.toUpperCase(),
                                  style: TextStyle(
                                    color: _getStatusColor(segment.status),
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${segment.start['name']} → ${segment.end['name']}",
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (segment.transportName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "${segment.transportName} ${segment.transportNumber ?? ''}",
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _getSegmentIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'road': return Icons.local_shipping;
      case 'train': return Icons.train;
      case 'flight': return Icons.flight;
      case 'sea': return Icons.directions_boat;
      default: return Icons.local_shipping;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green;
      case 'ongoing': return Colors.blue;
      case 'pending': return Colors.amber;
      default: return Colors.grey;
    }
  }
}
