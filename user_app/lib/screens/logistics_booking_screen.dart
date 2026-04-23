import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../widgets/leaflet_map.dart';
import '../providers/logistics_provider.dart';
import '../providers/logistics_vehicle_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../core/config.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'my_logistics_bookings_screen.dart';
import '../providers/user_provider.dart';
import '../core/api_endpoints.dart';
import '../services/network_logger.dart';

// ─── Helper cost per person ─────────────────────────────
const double _helperCostPerPerson = 800.0; // ₹800 per helper

// ─── Single item model (in-memory before save) ──────────
class _ItemEntry {
  String name;
  String type;
  double length;
  double height;
  double width;
  String unit;
  Uint8List? imageBytes;
  String? imageName;
  String? savedImageUrl; // After ImageKit upload

  _ItemEntry({
    required this.name,
    required this.type,
    this.length = 0,
    this.height = 0,
    this.width = 0,
    this.unit = 'cm',
    this.imageBytes,
    this.imageName,
    this.savedImageUrl,
  });
}

class LogisticsBookingScreen extends ConsumerStatefulWidget {
  final String bookingType;

  const LogisticsBookingScreen({
    super.key,
    this.bookingType = 'logistics',
  });

  @override
  ConsumerState<LogisticsBookingScreen> createState() =>
      _LogisticsBookingScreenState();
}

class _LogisticsBookingScreenState
    extends ConsumerState<LogisticsBookingScreen> {
  String get _resolvedBookingType {
    final raw = widget.bookingType.trim();
    if (raw.isEmpty) return 'logistics';
    return raw.toLowerCase();
  }

  // Vehicle
  String? _selectedVehicle;
  LogisticsVehicle? _selectedVehicleData;
  String _selectedMode = 'Road';
  final List<String> _transportModes = const ['Road', 'Train', 'Air'];

  // Goods type
  String? _selectedGoodType;

  // Added items list
  final List<_ItemEntry> _addedItems = [];
  String _selectedUnit = 'cm';
  final List<String> _units = ['cm', 'm', 'feet', 'inch'];

  // Current item form fields
  final _itemNameController = TextEditingController();
  final _lengthController = TextEditingController();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  Uint8List? _currentImageBytes;
  String? _currentImageName;
  bool _isAddingItem = false; // loader for "Add Item" button

  // Helpers
  int _helperCount = 0; // 0 = no helper, 1/2/3

  // Location + route
  Map<String, dynamic>? _pickup;
  Map<String, dynamic>? _dropoff;
  List<LatLng> _routePoints = [];
  double _distance = 0.0;
  bool _isFareLoading = false;
  String? _fareError;
  double? _apiFare;

  // Coupon
  String? _appliedCoupon;
  double _discountAmount = 0.0;

  // Selected addresses from address book

  // Booking loader
  bool _isSavingGood = false;

  // In-page search state
  final _pickupSearchController = TextEditingController();
  final _dropoffSearchController = TextEditingController();
  final _pickupFocusNode = FocusNode();
  final _dropoffFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;
  Timer? _fareDebounce;
  bool _showSuggestions = false;
  bool _activeSearchingPickup = true;

  @override
  void initState() {
    super.initState();
    _pickupFocusNode.addListener(_onFocusChanged);
    _dropoffFocusNode.addListener(_onFocusChanged);
    _itemNameController.addListener(_scheduleFareRecalculation);
    _lengthController.addListener(_scheduleFareRecalculation);
    _heightController.addListener(_scheduleFareRecalculation);
    _widthController.addListener(_scheduleFareRecalculation);
  }

  void _scheduleFareRecalculation() {
    _fareDebounce?.cancel();
    _fareDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      unawaited(_calculateFareFromApi());
    });
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {
      if (_pickupFocusNode.hasFocus) {
        _activeSearchingPickup = true;
        _showSuggestions = true;
      } else if (_dropoffFocusNode.hasFocus) {
        _activeSearchingPickup = false;
        _showSuggestions = true;
      } else {
        // Delay hiding suggestions to allow tap events to fire
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted &&
              !_pickupFocusNode.hasFocus &&
              !_dropoffFocusNode.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fareDebounce?.cancel();
    _itemNameController.removeListener(_scheduleFareRecalculation);
    _lengthController.removeListener(_scheduleFareRecalculation);
    _heightController.removeListener(_scheduleFareRecalculation);
    _widthController.removeListener(_scheduleFareRecalculation);
    _pickupSearchController.dispose();
    _dropoffSearchController.dispose();
    _pickupFocusNode.removeListener(_onFocusChanged);
    _dropoffFocusNode.removeListener(_onFocusChanged);
    _pickupFocusNode.dispose();
    _dropoffFocusNode.dispose();
    _itemNameController.dispose();
    _lengthController.dispose();
    _heightController.dispose();
    _widthController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _authHeaders({bool includeContentType = true}) {
    return ref.read(authServiceProvider).buildAuthHeaders(
          includeContentType: includeContentType,
        );
  }

  // ─── Suggestions & Selection ────────────────────────────
  Future<void> _fetchSuggestions(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
        });
      }
      return;
    }

    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get(
        MapsEndpoints.autocomplete(input: query, apiKey: apiKey),
      );

      if (mounted) {
        final List predictions =
            (response as Map<String, dynamic>)['predictions'] ?? [];
        setState(() {
          _searchResults = predictions
              .map((item) => {
                    'name':
                        item['structured_formatting']['main_text'] as String,
                    'address': item['description'] as String,
                    'place_id': item['place_id'] as String,
                  })
              .toList();
        });
      }
    } catch (e) {
      // Keep suggestion list unchanged on API failures.
    }
  }

  Future<void> _selectSuggestion(
      Map<String, dynamic> suggestion, bool isPickup) async {
    try {
      final apiKey = AppConfig.googleMapsApiKey;
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get(
        MapsEndpoints.details(
          placeId: suggestion['place_id'],
          apiKey: apiKey,
        ),
      );
      final loc =
          (response as Map<String, dynamic>)['result']['geometry']['location'];
      final lat = loc['lat'] as double;
      final lng = loc['lng'] as double;

      final result = {
        'name': suggestion['name'],
        'address': suggestion['address'],
        'lat': lat,
        'lng': lng,
      };

      if (mounted) {
        setState(() {
          _showSuggestions = false;
          if (isPickup) {
            _pickup = result;
            _pickupSearchController.text =
                "${suggestion['name']}, ${suggestion['address']}";
            _pickupFocusNode.unfocus();
          } else {
            _dropoff = result;
            _dropoffSearchController.text =
                "${suggestion['name']}, ${suggestion['address']}";
            _dropoffFocusNode.unfocus();
          }
          _searchResults = [];
        });
        unawaited(_calculateFareFromApi());
        _fetchRoute();
      }
    } catch (e) {
      // Keep current selection state on API failures.
    }
  }

  // ─── Price ──────────────────────────────────────────────
  double get _vehiclePrice {
    if (_selectedVehicleData == null) return 0.0;
    // Return base price even if locations aren't selected yet
    double total = _selectedVehicleData!.basePrice;
    if (_pickup != null && _dropoff != null) {
      total += _selectedVehicleData!.pricePerKm * _distance;
    }
    // Add cost per piece
    total += _selectedVehicleData!.pricePerPiece * _addedItems.length;
    return total;
  }

  double get _helperCost => _helperCount * _helperCostPerPerson;

  double get _calculatedWeightKg {
    final draftLength = double.tryParse(_lengthController.text.trim()) ?? 0;
    final draftHeight = double.tryParse(_heightController.text.trim()) ?? 0;
    final draftWidth = double.tryParse(_widthController.text.trim()) ?? 0;
    final draftVolume = draftLength > 0 && draftHeight > 0 && draftWidth > 0
        ? (draftLength * draftHeight * draftWidth)
        : 0.0;

    if (_addedItems.isEmpty && draftVolume <= 0) return 50.0;
    final totalVolume = _addedItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.length * item.height * item.width),
    );
    final approxWeight = (totalVolume + draftVolume) / 5000.0;
    return approxWeight <= 0 ? 50.0 : approxWeight;
  }

  Future<void> _calculateFareFromApi() async {
    if (_pickup == null || _dropoff == null) {
      if (mounted) {
        setState(() {
          _apiFare = null;
          _fareError = null;
        });
      }
      return;
    }

    try {
      final requestDistanceKm = _distance > 0
          ? _distance
          : _estimateDistanceKmFromSelectedLocations();
      if (requestDistanceKm <= 0) {
        if (mounted) {
          setState(() {
            _isFareLoading = false;
            _fareError = 'Distance unavailable for fare calculation.';
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isFareLoading = true;
          _fareError = null;
        });
      }
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post(
        LogisticsEndpoints.calculateFare,
        {
          'distanceKm': requestDistanceKm,
          'mode': _selectedMode,
          'weightKg': _calculatedWeightKg,
          'helperCount': _helperCount,
          'bookingType': _resolvedBookingType,
        },
      );
      final fare = _extractFareFromResponse(response);
      if (mounted) {
        setState(() {
          _apiFare = fare;
          _isFareLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFareLoading = false;
          _fareError = 'Live fare unavailable. Showing estimated price.';
        });
      }
    }
  }

  double _estimateDistanceKmFromSelectedLocations() {
    if (_pickup == null || _dropoff == null) return 0;
    final lat1 = _parseDouble(_pickup!['lat']);
    final lon1 = _parseDouble(_pickup!['lng']);
    final lat2 = _parseDouble(_dropoff!['lat']);
    final lon2 = _parseDouble(_dropoff!['lng']);
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) return 0;

    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degree) => degree * (math.pi / 180.0);

  double? _extractFareFromResponse(dynamic response) {
    if (response is! Map<String, dynamic>) return null;
    final data = response['data'];
    final values = <dynamic>[
      response['fare'],
      response['price'],
      response['totalPrice'],
      response['totalFare'],
      response['estimatedFare'],
      if (data is Map<String, dynamic>) data['fare'],
      if (data is Map<String, dynamic>) data['price'],
      if (data is Map<String, dynamic>) data['totalPrice'],
      if (data is Map<String, dynamic>) data['totalFare'],
      if (data is Map<String, dynamic>) data['estimatedFare'],
      if (data is Map<String, dynamic>) data['subtotal'],
    ];

    for (final value in values) {
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  double get _totalPrice =>
      ((_apiFare ?? (_vehiclePrice + _helperCost)) - _discountAmount)
          .clamp(0.0, double.infinity);

  // ─── Route & distance ───────────────────────────────────
  Future<void> _fetchRoute() async {
    if (_pickup == null || _dropoff == null) return;
    final pLat = _parseDouble(_pickup!['lat']);
    final pLng = _parseDouble(_pickup!['lng']);
    final dLat = _parseDouble(_dropoff!['lat']);
    final dLng = _parseDouble(_dropoff!['lng']);
    if (pLat == 0 || dLat == 0) return;

    final url =
        'https://router.project-osrm.org/route/v1/driving/$pLng,$pLat;$dLng,$dLat?overview=full&geometries=geojson';
    try {
      final uri = Uri.parse(url);
      NetworkLogger.logRequest(method: 'GET', url: uri);
      final response = await http.get(uri);
      NetworkLogger.logResponse(method: 'GET', url: uri, response: response);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];
          final geometry = route['geometry']['coordinates'] as List;
          final distance = (route['distance'] as num).toDouble() / 1000.0;
          if (mounted) {
            setState(() {
              _distance = distance;
              _routePoints = geometry
                  .map((coord) =>
                      LatLng(coord[1].toDouble(), coord[0].toDouble()))
                  .toList();
            });
            unawaited(_calculateFareFromApi());
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
  }

  String? _validateItemInputs() {
    final name = _itemNameController.text.trim();
    final length = double.tryParse(_lengthController.text.trim()) ?? 0;
    final height = double.tryParse(_heightController.text.trim()) ?? 0;
    final width = double.tryParse(_widthController.text.trim()) ?? 0;

    if (_selectedGoodType == null) {
      return 'Please select a goods type before adding an item';
    }
    if (name.length < 2) {
      return 'Item name must be at least 2 characters';
    }
    if (length <= 0 || height <= 0 || width <= 0) {
      return 'Length, height, and width must all be greater than 0';
    }

    return null;
  }

  String? _validateBookingInputs() {
    if (_selectedVehicleData == null) {
      return 'Please select a vehicle before booking';
    }
    if (_pickup == null || _dropoff == null) {
      return 'Please select both pickup and drop locations on the map';
    }
    if ((_pickup?['address']?.toString().trim().toLowerCase() ?? '') ==
        (_dropoff?['address']?.toString().trim().toLowerCase() ?? '')) {
      return 'Pickup and drop locations must be different';
    }
    if (_addedItems.isEmpty) {
      return 'Please add at least one item with complete details';
    }
    return null;
  }

  // ─── Add item to list ────────────────────────────────────
  Future<void> _addItemToList() async {
    final validationError = _validateItemInputs();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    final name = _itemNameController.text.trim();

    String goodTypeName = 'General';
    ref.read(typeGoodsProvider).whenData((goods) {
      if (_selectedGoodType != null) {
        final sel = goods.where((g) => g.id == _selectedGoodType).toList();
        if (sel.isNotEmpty) goodTypeName = sel.first.name;
      }
    });

    setState(() => _isAddingItem = true);

    try {
      // Upload image to ImageKit via backend
      String? uploadedUrl;
      if (_currentImageBytes != null && _currentImageName != null) {
        uploadedUrl = await _uploadImageToImageKit(
          _currentImageBytes!,
          _currentImageName!,
        );
      }

      final item = _ItemEntry(
        name: name,
        type: goodTypeName,
        length: double.tryParse(_lengthController.text.trim()) ?? 0,
        height: double.tryParse(_heightController.text.trim()) ?? 0,
        width: double.tryParse(_widthController.text.trim()) ?? 0,
        unit: _selectedUnit,
        imageBytes: _currentImageBytes,
        imageName: _currentImageName,
        savedImageUrl: uploadedUrl,
      );

      setState(() {
        _addedItems.add(item);
        // Reset form for next item
        _itemNameController.clear();
        _lengthController.clear();
        _heightController.clear();
        _widthController.clear();
        _currentImageBytes = null;
        _currentImageName = null;
      });
      unawaited(_calculateFareFromApi());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ "${item.name}" added! Add more or Book Now.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAddingItem = false);
    }
  }

  // ─── Upload image to ImageKit via backend ────────────────
  Future<String?> _uploadImageToImageKit(
      Uint8List bytes, String fileName) async {
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    final userId = authService.currentUser?.uid as String? ?? 'guest';

    final uri = Uri.parse(
      '${AppConfig.apiBaseUrl}${LogisticsEndpoints.goodsUploadImage}',
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(await _authHeaders(includeContentType: false));
    request.fields['userId'] = userId;
    request.files
        .add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));
    NetworkLogger.logRequest(
      method: 'POST',
      url: uri,
      headers: request.headers,
      formFields: request.fields,
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    NetworkLogger.logResponse(method: 'POST', url: uri, response: response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['url'] as String?;
    }
    debugPrint('ImageKit upload failed: ${response.body}');
    return null;
  }

  // ─── Save all items to DB + book ride ───────────────────
  Future<void> _saveAllItemsAndBook(String goodTypeName) async {
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    final userId = authService.currentUser?.uid as String? ?? 'guest';
    final headers = await _authHeaders(includeContentType: false);

    for (final item in _addedItems) {
      try {
        final uri = Uri.parse(
          '${AppConfig.apiBaseUrl}${LogisticsEndpoints.goods}',
        );
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(headers);
        request.fields['userId'] = userId;
        request.fields['itemName'] = item.name;
        request.fields['type'] = item.type;
        request.fields['length'] = item.length.toString();
        request.fields['height'] = item.height.toString();
        request.fields['width'] = item.width.toString();
        request.fields['unit'] = item.unit;
        if (item.savedImageUrl != null) {
          request.fields['imageUrl'] = item.savedImageUrl!;
        }
        NetworkLogger.logRequest(
          method: 'POST',
          url: uri,
          headers: request.headers,
          formFields: request.fields,
        );
        final streamed = await request.send();
        final resp = await http.Response.fromStream(streamed);
        NetworkLogger.logResponse(method: 'POST', url: uri, response: resp);
        debugPrint('Saved item "${item.name}": ${resp.statusCode}');
      } catch (e) {
        debugPrint('Error saving item "${item.name}": $e');
      }
    }
  }

  // ─── POST full logistics booking to MongoDB ───────────
  Future<String> _saveLogisticsBooking({
    required String goodTypeName,
  }) async {
    final authService = ref.read(authServiceProvider);
    await authService.waitForSession();
    final user = authService.currentUser;
    final userId = user?.uid as String? ?? 'guest';
    final userPhone =
        (user is MockUser) ? user.phoneNumber ?? '' : user?.phoneNumber ?? '';

    // Attempt to get name from the provider first (most reliable Mongo data)
    String userName = ref.read(userProfileProvider).value ?? '';
    if (userName.isEmpty || userName == 'Transglobal User') {
      userName = (user is MockUser)
          ? user.displayName ?? 'User'
          : user?.displayName ?? 'User';
    }

    final apiService = ref.read(apiServiceProvider);
    final payload = {
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'pickup': {
        'name': _pickup!['name'],
        'address': _pickup!['address'],
        'lat': _parseDouble(_pickup!['lat']),
        'lng': _parseDouble(_pickup!['lng']),
      },
      'dropoff': {
        'name': _dropoff!['name'],
        'address': _dropoff!['address'],
        'lat': _parseDouble(_dropoff!['lat']),
        'lng': _parseDouble(_dropoff!['lng']),
      },
      'distanceKm': _distance,
      'vehicleType': _selectedMode,
      'mode': _selectedMode,
      'selectedVehicle': _selectedVehicle,
      'bookingType': _resolvedBookingType,
      'vehiclePrice': _vehiclePrice,
      'items': _addedItems
          .map((item) => {
                'itemName': item.name,
                'type': item.type,
                'length': item.length,
                'height': item.height,
                'width': item.width,
                'unit': item.unit,
              })
          .toList(),
      'helperCount': _helperCount,
      'helperCost': _helperCost,
      'discountAmount': _discountAmount,
      'totalPrice': _apiFare ?? _totalPrice,
      'appliedCoupon': _appliedCoupon,
    };
    final data = await apiService.postWithFallback(
      LogisticsEndpoints.book,
      LogisticsEndpoints.bookingsLegacy,
      payload,
    );

    if (data['success'] == true) {
      debugPrint('Logistics booking saved: ${data['bookingId']}');
      return data['bookingId'] as String? ?? '';
    } else {
      throw Exception('Failed to save booking: ${data['message']}');
    }
  }

  // ─── Build ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final typeGoodsAsync = ref.watch(typeGoodsProvider);
    final vehiclesAsync = ref.watch(logisticsVehiclesProvider);

    // No auto-selection to keep initial cost zero

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios,
              size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Book Logistics',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary)),
        centerTitle: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Map ──────────────────────────────────────────────
                  SizedBox(
                    height: 250,
                    width: double.infinity,
                    child: LeafletMap(
                      location: _pickup ?? _dropoff,
                      polylines: [
                        if (_routePoints.isNotEmpty)
                          Polyline(
                            points: _routePoints,
                            color: context.theme.primaryColor,
                            strokeWidth: 5,
                          ),
                      ],
                      markers: [
                        if (_pickup != null)
                          Marker(
                            point: LatLng(_parseDouble(_pickup!['lat']),
                                _parseDouble(_pickup!['lng'])),
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.circle,
                                color: Colors.green, size: 24),
                          ),
                        if (_dropoff != null)
                          Marker(
                            point: LatLng(_parseDouble(_dropoff!['lat']),
                                _parseDouble(_dropoff!['lng'])),
                            width: 60,
                            height: 60,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                      ],
                    ),
                  ),

                  // ── Location Input ───────────────────────────────────
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildSearchField(
                          controller: _pickupSearchController,
                          focusNode: _pickupFocusNode,
                          icon: Icons.circle,
                          iconColor: Colors.green,
                          label: 'Pickup Location',
                          hint: 'Search Pickup Location',
                          isPickup: true,
                        ),
                        if (_showSuggestions &&
                            _activeSearchingPickup &&
                            _searchResults.isNotEmpty)
                          _buildSuggestionsList(true),
                        const SizedBox(height: 16),
                        _buildSearchField(
                          controller: _dropoffSearchController,
                          focusNode: _dropoffFocusNode,
                          icon: Icons.circle,
                          iconColor: Colors.red,
                          label: 'Drop Location',
                          hint: 'Search Drop Location',
                          isPickup: false,
                        ),
                        if (_showSuggestions &&
                            !_activeSearchingPickup &&
                            _searchResults.isNotEmpty)
                          _buildSuggestionsList(false),
                      ],
                    ),
                  ),

                  // ── Transport Mode ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text(
                      'Select Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _transportModes.map((mode) {
                        final isSelected = _selectedMode == mode;
                        return ChoiceChip(
                          label: Text(mode),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedMode = mode);
                            unawaited(_calculateFareFromApi());
                          },
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Vehicle Type ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Text('Select Vehicle Type',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: vehiclesAsync.when(
                      data: (vehicles) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: vehicles.map((vehicle) {
                            final isSelected = _selectedVehicle == vehicle.name;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedVehicle = vehicle.name;
                                  _selectedVehicleData = vehicle;
                                });
                                unawaited(_calculateFareFromApi());
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.theme.primaryColor.withAlpha(38)
                                      : context.theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? context.theme.primaryColor
                                        : context.theme.dividerColor
                                            .withAlpha(25),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        vehicle.imageUrl,
                                        height: 50,
                                        width: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image,
                                                size: 50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(vehicle.name,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.textPrimary),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                    Text(vehicle.capacity,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                context.colors.textSecondary)),
                                    const SizedBox(height: 6),
                                    Text(
                                        '₹${vehicle.basePrice.toInt()} + ₹${vehicle.pricePerKm.toInt()}/km + ₹${vehicle.pricePerPiece.toInt()}/pc',
                                        style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: context.theme.primaryColor)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  ),

                  // ── Type of Goods ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Text('Type of Goods',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: typeGoodsAsync.when(
                      data: (goods) => Column(
                        children: goods.map((good) {
                          return RadioListTile<String>(
                            title: Text(good.name),
                            value: good.id,
                            groupValue: _selectedGoodType,
                            onChanged: (val) {
                              setState(() => _selectedGoodType = val);
                              _scheduleFareRecalculation();
                            },
                            contentPadding: EdgeInsets.zero,
                            activeColor: context.theme.primaryColor,
                          );
                        }).toList(),
                      ),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error loading goods: $err'),
                    ),
                  ),

                  // ── ITEM DETAILS FORM ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Item Details',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary)),
                        if (_addedItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.theme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_addedItems.length} item${_addedItems.length > 1 ? 's' : ''} added',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Added items chips
                  if (_addedItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: _addedItems.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.theme.primaryColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      context.theme.primaryColor.withAlpha(50)),
                            ),
                            child: Row(
                              children: [
                                if (item.imageBytes != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(item.imageBytes!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover),
                                  )
                                else
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: context.theme.primaryColor
                                          .withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.inventory_2,
                                        color: context.theme.primaryColor),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  context.colors.textPrimary)),
                                      Text(
                                          '${item.type} · ${item.length}×${item.height}×${item.width} ${item.unit}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: context
                                                  .colors.textSecondary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setState(() => _addedItems.removeAt(idx));
                                    unawaited(_calculateFareFromApi());
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Item form card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item Name
                          TextField(
                            controller: _itemNameController,
                            decoration: InputDecoration(
                              labelText: 'Item Name',
                              prefixIcon:
                                  const Icon(Icons.inventory_2_outlined),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              filled: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dimensions Row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _lengthController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Length (${_selectedUnit})',
                                    prefixIcon: const Icon(Icons.straighten),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _heightController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Height (${_selectedUnit})',
                                    prefixIcon: const Icon(Icons.height),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _widthController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}')),
                                  ],
                                  decoration: InputDecoration(
                                    labelText: 'Width (${_selectedUnit})',
                                    prefixIcon: const Icon(Icons.width_normal),
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    filled: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Unit Selection
                          const Text('Dimension Unit',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: _units.map((unit) {
                              final isSelected = _selectedUnit == unit;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(unit),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedUnit = unit);
                                      _scheduleFareRecalculation();
                                    }
                                  },
                                  selectedColor:
                                      context.theme.primaryColor.withAlpha(50),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? context.theme.primaryColor
                                        : context.colors.textSecondary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          // Add Item Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isAddingItem ? null : _addItemToList,
                              icon: _isAddingItem
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: context.theme.primaryColor))
                                  : Icon(Icons.add_circle_outline,
                                      color: context.theme.primaryColor),
                              label: Text(
                                _isAddingItem ? 'Saving…' : 'Add Item',
                                style: TextStyle(
                                    color: context.theme.primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color: context.theme.primaryColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── HELPER SECTION ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                    child: Text('Need Helpers?',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹${_helperCostPerPerson.toInt()} per helper · Loading & unloading assistance',
                            style: TextStyle(
                                fontSize: 13,
                                color: context.colors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Number of Helpers',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.textPrimary),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      context.theme.primaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: context.theme.primaryColor
                                          .withAlpha(50)),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _helperCount > 0
                                          ? () {
                                              setState(() => _helperCount--);
                                              unawaited(
                                                  _calculateFareFromApi());
                                            }
                                          : null,
                                      icon: const Icon(Icons.remove),
                                      color: _helperCount > 0
                                          ? context.theme.primaryColor
                                          : Colors.grey,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      constraints: const BoxConstraints(),
                                    ),
                                    Text(
                                      '$_helperCount',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.textPrimary),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() => _helperCount++);
                                        unawaited(_calculateFareFromApi());
                                      },
                                      icon: const Icon(Icons.add),
                                      color: context.theme.primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_helperCount > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline,
                                      color: Colors.orange, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_helperCount helper${_helperCount > 1 ? 's' : ''} × ₹${_helperCostPerPerson.toInt()} = ₹${_helperCost.toInt()}',
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // ── Footer ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.theme.cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(77),
                  blurRadius: 25,
                  offset: const Offset(0, -10),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estimated Total',
                              style: TextStyle(
                                  color: context.colors.textSecondary,
                                  fontSize: 12)),
                          if (_distance > 0)
                            Text('Distance: ${_distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 12)),
                          Text('₹${_totalPrice.toInt()}',
                              style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary)),
                          if (_isFareLoading)
                            const Text(
                              'Calculating live fare...',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.orange),
                            )
                          else if (_apiFare != null)
                            const Text(
                              'Live API fare applied',
                              style:
                                  TextStyle(fontSize: 11, color: Colors.green),
                            )
                          else if (_fareError != null)
                            Text(
                              _fareError!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.redAccent,
                              ),
                            ),
                          // Breakdown
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedVehicleData != null)
                                Text(
                                    'Vehicle: ₹${(_selectedVehicleData!.basePrice + _selectedVehicleData!.pricePerKm * _distance).toInt()}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.colors.textSecondary)),
                              if (_addedItems.isNotEmpty &&
                                  _selectedVehicleData != null)
                                Text(
                                    'Items (${_addedItems.length}): +₹${(_selectedVehicleData!.pricePerPiece * _addedItems.length).toInt()}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.blueAccent)),
                              if (_helperCount > 0)
                                Text(
                                    'Helpers (${_helperCount}): +₹${_helperCost.toInt()}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.orange)),
                              if (_discountAmount > 0)
                                Text('Discount: -₹${_discountAmount.toInt()}',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_appliedCoupon != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Coupon: $_appliedCoupon (-₹${_discountAmount.toInt()})',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: _showCouponBottomSheet,
                            icon: Icon(
                              _appliedCoupon != null
                                  ? Icons.check_circle
                                  : Icons.confirmation_num_outlined,
                              color: _appliedCoupon != null
                                  ? Colors.green
                                  : context.theme.primaryColor,
                              size: 18,
                            ),
                            label: Text(
                              _appliedCoupon != null
                                  ? 'Change Coupon'
                                  : 'Apply Coupon',
                              style: TextStyle(
                                color: _appliedCoupon != null
                                    ? Colors.green
                                    : context.theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: (_pickup != null &&
                            _dropoff != null &&
                            _addedItems.isNotEmpty)
                        ? () async {
                            final bookingValidationError =
                                _validateBookingInputs();
                            if (bookingValidationError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(bookingValidationError)),
                              );
                              return;
                            }

                            String goodTypeName = 'General';
                            ref.read(typeGoodsProvider).whenData((goods) {
                              final sel = goods
                                  .where((g) => g.id == _selectedGoodType)
                                  .toList();
                              if (sel.isNotEmpty) goodTypeName = sel.first.name;
                            });

                            try {
                              await _calculateFareFromApi();
                              if (_apiFare == null) {
                                throw Exception(
                                  'Unable to fetch fare from API. Please check details and try again.',
                                );
                              }
                              setState(() => _isSavingGood = true);
                              if (!mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => const Center(
                                    child: CircularProgressIndicator()),
                              );

                              await _saveAllItemsAndBook(goodTypeName);

                              // Save the full booking to MongoDB
                              await _saveLogisticsBooking(
                                goodTypeName: goodTypeName,
                              );

                              if (mounted) {
                                Navigator.pop(
                                    context); // Close the loading dialog

                                // Show success snackbar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        '🎉 Logistics booking successful! Redirecting to your bookings...'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 3),
                                  ),
                                );

                                // Wait for 3 seconds as requested
                                await Future.delayed(
                                    const Duration(seconds: 3));

                                if (mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MyLogisticsBookingsScreen(),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Booking failed: $e')),
                                );
                              }
                            } finally {
                              if (mounted)
                                setState(() => _isSavingGood = false);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSavingGood
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _addedItems.isEmpty
                                ? 'Add at least 1 item to book'
                                : 'Book ${_selectedVehicle ?? ''} · ${_addedItems.length} item${_addedItems.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────
  double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String hint,
    required bool isPickup,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 12),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: context.colors.textSecondary ?? Colors.grey)),
                  TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (val) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 500),
                          () => _fetchSuggestions(val));
                    },
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(
                          fontSize: 14,
                          color: (context.colors.textSecondary ?? Colors.grey)
                              .withAlpha(100)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary ?? Colors.black),
                  ),
                ],
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () {
                  controller.clear();
                  if (isPickup) {
                    _pickup = null;
                  } else {
                    _dropoff = null;
                  }
                  setState(() {
                    _searchResults = [];
                    _routePoints = [];
                    _distance = 0.0;
                    _apiFare = null;
                  });
                },
              )
            else
              Icon(Icons.chevron_right,
                  color: context.colors.textSecondary, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionsList(bool isPickup) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _searchResults.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = _searchResults[index];
          return ListTile(
            leading: const Icon(Icons.location_on_outlined, size: 20),
            title: Text(suggestion['name'],
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(suggestion['address'],
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            onTap: () => _selectSuggestion(suggestion, isPickup),
          );
        },
      ),
    );
  }

  void _showCouponBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Available Coupons',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary)),
                if (_appliedCoupon != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _appliedCoupon = null;
                        _discountAmount = 0.0;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Remove',
                        style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCouponItem('FIRST50', 'Flat 50% OFF (Up to ₹150)', 150),
            _buildCouponItem('LOGIS20', '20% Discount on Logistics', 100),
            _buildCouponItem('SAVE50', 'Save ₹50 on this booking', 50),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponItem(String code, String desc, double discount) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.theme.primaryColor.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child:
            Icon(Icons.confirmation_number, color: context.theme.primaryColor),
      ),
      title: Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
      trailing: ElevatedButton(
        onPressed: () {
          setState(() {
            _appliedCoupon = code;
            _discountAmount = discount;
          });
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Apply'),
      ),
    );
  }
}
