import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';

class NavigationScreen extends StatefulWidget {
  final LatLng destination;
  final String destinationName;

  const NavigationScreen({
    super.key,
    required this.destination,
    required this.destinationName,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final MapController _mapController = MapController();
  LatLng _currentPos = const LatLng(26.8467, 80.9462); // Fallback Lucknow
  List<LatLng> _routePoints = [];
  bool _isLoading = true;
  double _distance = 0.0;
  double _duration = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initNavigation();
  }

  Future<void> _initNavigation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPos = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
    
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    setState(() => _isLoading = true);
    final routeData = await LocationService.getRouteData(_currentPos, widget.destination);
    
    if (mounted) {
      setState(() {
        _routePoints = routeData['points'];
        _distance = routeData['distance'];
        _duration = routeData['duration'];
        _isLoading = false;
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
        padding: const EdgeInsets.all(50),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPos,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppTheme.neonGreen,
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPos,
                    width: 50,
                    height: 50,
                    child: _buildCurrentLocationMarker(),
                  ),
                  Marker(
                    point: widget.destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppTheme.offlineRed, size: 36),
                  ),
                ],
              ),
            ],
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.neonGreen)),

          // Header Instructions
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.5)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 20)],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.turn_right_outlined, color: AppTheme.neonGreen, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _distance < 1.0 
                            ? '${(_distance * 1000).toInt()}m' 
                            : '${_distance.toStringAsFixed(1)}km', 
                          style: const TextStyle(color: AppTheme.neonGreen, fontSize: 24, fontWeight: FontWeight.w900)
                        ),
                        Text('Navigate towards ${widget.destinationName}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Stats
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statItem('DISTANCE', '${_distance.toStringAsFixed(1)} km'),
                      _vertDivider(),
                      _statItem('TIME', '${_duration.toInt()} min'),
                      _vertDivider(),
                      _statItem('SPEED', '0 km/h'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.offlineRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: AppTheme.offlineRed.withOpacity(0.4),
                    ),
                    child: const Text('EXIT NAVIGATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.neonGreen.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        const Icon(Icons.navigation, color: AppTheme.neonGreen, size: 28),
      ],
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _vertDivider() {
    return Container(width: 1, height: 30, color: AppTheme.darkDivider);
  }
}
