import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/corporate_auth_provider.dart';
import '../models/logistics_provider.dart';
import '../models/logistics_request.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestFormPage extends StatefulWidget {
  const RequestFormPage({super.key});

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Dynamic Segment Controllers
  final List<TextEditingController> _locationControllers = [
    TextEditingController(), // Start
    TextEditingController(), // End
  ];
  final List<FocusNode> _focusNodes = [
    FocusNode(),
    FocusNode(),
  ];

  final _weightController = TextEditingController();
  final _goodsTypeController = TextEditingController();

  // Modes for each segment (there are n-1 segments for n locations)
  final List<TransportMode> _segmentModes = [TransportMode.road];

  double _estimatedPrice = 0;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onFormChanged);
    _goodsTypeController.addListener(_onFormChanged);
    for (var controller in _locationControllers) {
      controller.addListener(_onLocationChanged);
    }
  }

  @override
  void dispose() {
    for (var c in _locationControllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    _weightController.dispose();
    _goodsTypeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _addSegment() {
    setState(() {
      _locationControllers
          .add(TextEditingController()..addListener(_onLocationChanged));
      _focusNodes.add(FocusNode());
      _segmentModes.add(TransportMode.road);
    });
  }

  void _removeSegment(int index) {
    if (_locationControllers.length <= 2) return;
    setState(() {
      _locationControllers[index].dispose();
      _locationControllers.removeAt(index);
      _focusNodes[index].dispose();
      _focusNodes.removeAt(index);
      _segmentModes.removeAt(
          index < _segmentModes.length ? index : _segmentModes.length - 1);
      _onLocationChanged();
    });
  }

  void _onLocationChanged() {
    final provider = Provider.of<LogisticsProvider>(context, listen: false);
    NS_Debouncer.run(() async {
      List<JourneySegment> segments = [];
      for (int i = 0; i < _locationControllers.length - 1; i++) {
        segments.add(JourneySegment(
          start: _locationControllers[i].text,
          end: _locationControllers[i + 1].text,
          mode: _segmentModes[i],
        ));
      }
      provider.updateSegments(segments);
      await provider.calculateChainRoute();
      _onFormChanged();
    });
  }

  void _onFormChanged() {
    if (!mounted) return;
    final weight = double.tryParse(_weightController.text) ?? 1.0;
    final provider = Provider.of<LogisticsProvider>(context, listen: false);
    setState(() {
      _estimatedPrice = provider.calculatePrice(
        weight: weight,
        goodsType: _goodsTypeController.text,
      );
    });
    _updateMapBounds(provider);
  }

  void _updateMapBounds(LogisticsProvider provider) {
    if (_mapController == null) return;
    List<LatLng> allPoints = [];
    for (var s in provider.journeySegments) allPoints.addAll(s.points);
    if (allPoints.isEmpty) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var p in allPoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(
          southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng)),
      70,
    ));
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_locationControllers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter pickup and destination.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final provider = Provider.of<LogisticsProvider>(context, listen: false);
    final authProvider =
        Provider.of<CorporateAuthProvider>(context, listen: false);
    final account = authProvider.account;
    final token = authProvider.token;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final parsedWeight = double.tryParse(_weightController.text.trim());

    if (account == null || token == null) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Please sign in again to submit shipments.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (parsedWeight == null || parsedWeight <= 0) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Please enter a valid weight greater than 0.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final newRequest = LogisticsRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pickupLocation: _locationControllers.first.text,
      destinationLocation: _locationControllers.last.text,
      weight: parsedWeight,
      goodsType: _goodsTypeController.text.trim().isEmpty
          ? 'Goods'
          : _goodsTypeController.text.trim(),
      modes: _segmentModes,
      selectedVehicles: {},
      estimatedPrice: _estimatedPrice,
      createdAt: DateTime.now(),
    );

    bool success = false;
    try {
      success = await provider.submitBooking(newRequest, account, token);
    } catch (e, st) {
      debugPrint('Submit booking failed: $e');
      debugPrintStack(stackTrace: st);
      success = false;
    }
    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Shipment deployed to backend'),
        backgroundColor: Colors.green,
      ));
      if (navigator.canPop()) {
        navigator.pop();
      }
    } else {
      messenger.showSnackBar(const SnackBar(
        content: Text('Failed to deploy shipment. Check your connection.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      backgroundColor: AppTheme.bgLow,
      appBar: AppBar(
        title: Text('JOURNEY BUILDER',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('GLOBAL SHIPMENT CHAIN', LucideIcons.map),
                  const SizedBox(height: 16),
                  _buildMapContainer(),
                  const SizedBox(height: 24),
                  _buildJourneyTimeline(),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _addSegment,
                      icon: const Icon(LucideIcons.plusCircle, size: 18),
                      label: Text('ADD TRIP SEGMENT',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.electricBlue),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader('CARGO DETAILS', LucideIcons.package2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStyledField(
                          controller: _weightController,
                          hint: 'Weight (kg)',
                          icon: LucideIcons.scale,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStyledField(
                          controller: _goodsTypeController,
                          hint: 'Goods Type',
                          icon: LucideIcons.box,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  _buildPremiumEstimateCard(currencyFormat, isDesktop),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                      backgroundColor: AppTheme.electricBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                    ),
                    child: Text('CONFIRM FULL CHAIN',
                        style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapContainer() {
    final provider = Provider.of<LogisticsProvider>(context);
    final Set<Marker> markers = {};
    final Set<Polyline> polylines = {};

    if (kIsWeb) {
      // Avoid Google Maps JS issues on web; show a lightweight placeholder.
      return Container(
        height: 280,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Center(
          child: Text('Route preview not shown on web',
              style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
        ),
      );
    }

    for (int i = 0; i < provider.journeySegments.length; i++) {
      final s = provider.journeySegments[i];
      if (s.points.isNotEmpty) {
        markers.add(Marker(
            markerId: MarkerId('m_$i'),
            position: s.points.first,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure)));
        if (i == provider.journeySegments.length - 1) {
          markers.add(Marker(
              markerId: const MarkerId('m_last'),
              position: s.points.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange)));
        }

        polylines.add(Polyline(
          polylineId: PolylineId('p_$i'),
          points: s.points,
          color: s.mode == TransportMode.road
              ? AppTheme.electricBlue
              : (s.mode == TransportMode.air
                  ? AppTheme.accentOrange
                  : Colors.teal),
          width: 6,
          jointType: JointType.round,
        ));
      }
    }

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                const CameraPosition(target: LatLng(20.5937, 78.9629), zoom: 4),
            onMapCreated: (controller) => _mapController = controller,
            markers: markers,
            polylines: polylines,
            zoomControlsEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
          ),
          if (provider.isLoading)
            Container(
                color: Colors.white60,
                child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.electricBlue))),
        ],
      ),
    );
  }

  Widget _buildJourneyTimeline() {
    return Column(
      children: [
        for (int i = 0; i < _locationControllers.length; i++) ...[
          _buildLocationNode(i),
          if (i < _locationControllers.length - 1) _buildTransportSegment(i),
        ],
      ],
    );
  }

  Widget _buildLocationNode(int index) {
    bool isFirst = index == 0;
    bool isLast = index == _locationControllers.length - 1;
    String label = isFirst
        ? 'STARTING POINT'
        : (isLast ? 'FINAL DESTINATION' : 'TRANSIT HUB ${index}');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
              isFirst
                  ? LucideIcons.circleDot
                  : (isLast ? LucideIcons.mapPin : LucideIcons.refreshCw),
              size: 18,
              color: isFirst
                  ? AppTheme.accentOrange
                  : (isLast ? AppTheme.electricBlue : AppTheme.slateGray)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildAutocompleteField(_locationControllers[index],
                  _focusNodes[index], label, index)),
          if (!isFirst && !isLast)
            IconButton(
                icon: const Icon(LucideIcons.trash2,
                    size: 16, color: AppTheme.errorRed),
                onPressed: () => _removeSegment(index)),
        ],
      ),
    );
  }

  Widget _buildTransportSegment(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Container(width: 2, height: 40, color: AppTheme.glassBorder),
          const SizedBox(width: 24),
          Expanded(
            child: Row(
              children: [
                _buildMiniMode(index, TransportMode.road, LucideIcons.truck),
                const SizedBox(width: 8),
                _buildMiniMode(index, TransportMode.air, LucideIcons.plane),
                const SizedBox(width: 8),
                _buildMiniMode(index, TransportMode.water, LucideIcons.ship),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMode(int segmentIndex, TransportMode mode, IconData icon) {
    bool isSelected = _segmentModes[segmentIndex] == mode;
    return InkWell(
      onTap: () {
        setState(() {
          _segmentModes[segmentIndex] = mode;
          _onLocationChanged();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.electricBlue : AppTheme.bgLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(mode.name.toUpperCase(),
                style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.primaryBlue)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.electricBlue),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.slateGray,
                letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildStyledField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppTheme.slateGray)),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildAutocompleteField(TextEditingController controller,
      FocusNode focusNode, String hint, int index) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty)
          return const Iterable<String>.empty();
        try {
          // On Web: uses backend proxy. On Android: calls Google directly.
          final baseUrl = kIsWeb
              ? '${LogisticsProvider.baseUrl}/api/maps/autocomplete'
              : 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
          final url = Uri.parse(
              '$baseUrl?input=${Uri.encodeComponent(textEditingValue.text)}&key=${LogisticsProvider.googleApiKey}&components=country:in');
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data['status'] == 'OK')
              return (data['predictions'] as List)
                  .map((p) => p['description'] as String);
          }
        } catch (_) {}
        return const Iterable<String>.empty();
      },
      onSelected: (String selection) {
        controller.text = selection;
        FocusScope.of(context).unfocus();
        _onLocationChanged();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintStyle: const TextStyle(fontSize: 14)),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
                width: 300,
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) => ListTile(
                        title: Text(options.elementAt(index),
                            style: const TextStyle(fontSize: 12)),
                        onTap: () => onSelected(options.elementAt(index))))),
          ),
        );
      },
    );
  }

  Widget _buildPremiumEstimateCard(NumberFormat format, bool isDesktop) {
    final provider = Provider.of<LogisticsProvider>(context);
    double totalKm = 0;
    for (var s in provider.journeySegments) totalKm += s.distance;

    return Container(
      decoration: BoxDecoration(
          color: AppTheme.primaryBlue,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: AppTheme.electricBlue.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20))
          ]),
      padding: EdgeInsets.all(isDesktop ? 40.0 : 28.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHAIN DEPLOYMENT COST',
                      style: GoogleFonts.outfit(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Text(format.format(_estimatedPrice),
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: isDesktop ? 42 : 32,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(LucideIcons.zap,
                  color: AppTheme.accentOrange, size: isDesktop ? 32 : 24),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Distance:',
                  style: TextStyle(color: Colors.white60, fontSize: 11)),
              Text(
                  '${totalKm.toInt()} KM Across ${provider.journeySegments.length} Segments',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class NS_Debouncer {
  static Timer? _timer;
  static void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), action);
  }
}
