import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';

class LeafletMap extends StatefulWidget {
  final Map<String, dynamic>? location;
  final Function(Map<String, double>)? onRegionChangeComplete;
  final List<Marker>? markers;
  final List<Polyline>? polylines;
  final MapController? mapController;

  const LeafletMap({
    super.key,
    this.location,
    this.onRegionChangeComplete,
    this.markers,
    this.polylines,
    this.mapController,
  });

  @override
  State<LeafletMap> createState() => _LeafletMapState();
}

class _LeafletMapState extends State<LeafletMap> with TickerProviderStateMixin {
  late final MapController _mapController;
  // Use Mumbai as default center
  final LatLng _defaultLocation = const LatLng(19.0760, 72.8777);

  @override
  void initState() {
    super.initState();
    _mapController = widget.mapController ?? MapController();
  }

  @override
  void didUpdateWidget(LeafletMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.location != oldWidget.location && widget.location != null) {
      final lat = widget.location!['lat'];
      final lng = widget.location!['lng'];
      if (lat != null && lng != null) {
        // Safe null check before animation
        if (_mapController.camera.center.latitude.isFinite) {
          _animatedMapMove(LatLng(lat, lng), 15.0);
        }
      }
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
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    LatLng initialCenter = _defaultLocation;
    if (widget.location != null) {
      final lat = widget.location!['lat'];
      final lng = widget.location!['lng'];
      if (lat != null && lng != null) {
        initialCenter = LatLng(lat, lng);
      }
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onPositionChanged: (position, hasGesture) {
          if (hasGesture && widget.onRegionChangeComplete != null) {
            widget.onRegionChangeComplete!({
              'latitude': position.center.latitude,
              'longitude': position.center.longitude,
              'latitudeDelta': 0.01,
              'longitudeDelta': 0.01,
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: Theme.of(context).brightness == Brightness.dark
              ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png'
              : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.transglobal.user_app',
          retinaMode: true,
        ),
        if (widget.polylines != null)
          PolylineLayer(polylines: widget.polylines!),
        MarkerLayer(
          markers: [
            if (widget.location != null)
              Marker(
                point: LatLng(widget.location!['lat'], widget.location!['lng']),
                width: 60,
                height: 60,
                child: _buildPulsingMarker(),
              ),
            if (widget.markers != null) ...widget.markers!,
          ],
        ),
      ],
    );
  }

  Widget _buildPulsingMarker() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.primaryColor.withOpacity(0.2),
          ),
        ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.primaryColor.withOpacity(0.4),
          ),
        ),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.theme.primaryColor,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
