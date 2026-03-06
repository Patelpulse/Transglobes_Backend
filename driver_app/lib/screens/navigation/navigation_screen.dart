import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';

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
  final LatLng _currentPos = const LatLng(26.8467, 80.9462); // Demo Lucknow center
  
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
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_currentPos, widget.destination],
                    color: AppTheme.neonGreen,
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.navigation, color: AppTheme.neonGreen, size: 30),
                  ),
                  Marker(
                    point: widget.destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on, color: AppTheme.offlineRed, size: 30),
                  ),
                ],
              ),
            ],
          ),
          
          // Header Instructions (Glassmorphism)
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
                        const Text('500m', style: TextStyle(color: AppTheme.neonGreen, fontSize: 24, fontWeight: FontWeight.w900)),
                        Text('Turn right towards ${widget.destinationName}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Stats & Control
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
                      _statItem('DISTANCE', '2.8 km'),
                      _vertDivider(),
                      _statItem('TIME', '12 min'),
                      _vertDivider(),
                      _statItem('SPEED', '45 km/h'),
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
