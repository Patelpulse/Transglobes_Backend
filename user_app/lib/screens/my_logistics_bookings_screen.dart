import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';
import '../providers/user_provider.dart';
import 'ride_tracking_screen.dart';

class MyLogisticsBookingsScreen extends ConsumerStatefulWidget {
  const MyLogisticsBookingsScreen({super.key});

  @override
  ConsumerState<MyLogisticsBookingsScreen> createState() => _MyLogisticsBookingsScreenState();
}

class _MyLogisticsBookingsScreenState extends ConsumerState<MyLogisticsBookingsScreen> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final authService = ref.read(authServiceProvider);
      // Ensure web session is restored before reading currentUser
      await authService.waitForSession();

      String? userId = authService.currentUser?.uid as String?;

      if (userId == null) {
        // Fallback: try backend profile
        try {
          final profile = await ref.read(fullUserProfileProvider.future);
          userId = profile?.firebaseId;
        } catch (_) {}
      }

      if (userId == null) {
        setState(() {
          _error = "Please log in to view your bookings";
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/logistics-bookings/user/$userId');
      final headers = await authService.buildAuthHeaders(includeContentType: false);
      final response = await http.get(
        url,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _bookings = data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Failed to load bookings: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('My Logistics Bookings', 
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _bookings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookings.length,
                        itemBuilder: (ctx, index) {
                          final booking = _bookings[index];
                          return _buildBookingCard(booking);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No bookings found', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textSecondary)),
          const SizedBox(height: 8),
          Text('Your recently booked logistics will appear here', 
            style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(dynamic booking) {
    final status = booking['status'] ?? 'pending';
    final vehicle = booking['vehicleType'] ?? 'Logistics';
    final items = booking['items'] as List? ?? [];
    final pickup = booking['pickupAddress']?['label'] ?? booking['pickup']?['name'] ?? 'Pickup';
    final drop = booking['receivedAddress']?['label'] ?? booking['dropoff']?['name'] ?? 'Delivery';
    final date = DateTime.parse(booking['createdAt']).toLocal();
    
    final otp = booking['otp']?.toString();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status.toUpperCase(), 
                            style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        if (otp != null && (status == 'confirmed' || status == 'processing')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.theme.primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.theme.primaryColor.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Text('OTP: ', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(otp, style: TextStyle(color: context.theme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text('${date.day}/${date.month}/${date.year}', 
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getVehicleIcon(vehicle), color: context.theme.primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('${items.length} Item${items.length > 1 ? 's' : ''}', 
                            style: TextStyle(color: context.colors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${(double.tryParse(booking['totalPrice'].toString()) ?? 0.0).toStringAsFixed(2)}', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.theme.primaryColor)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildLocationRow(Icons.circle, Colors.green, pickup),
                const SizedBox(height: 8),
                _buildLocationRow(Icons.location_on, Colors.red, drop),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showBookingDetails(booking),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.theme.primaryColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('View Details', 
                    style: TextStyle(color: context.theme.primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.theme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, 
            style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'in_transit': return Colors.orange;
      default: return Colors.blue;
    }
  }

  IconData _getVehicleIcon(String vehicle) {
    final v = vehicle.toLowerCase();
    if (v.contains('flight')) return Icons.flight_takeoff_rounded;
    if (v.contains('train')) return Icons.train_rounded;
    if (v.contains('sea')) return Icons.directions_boat_rounded;
    return Icons.local_shipping_rounded;
  }

  void _showBookingDetails(dynamic booking) {
    final status = booking['status'] ?? 'pending';
    final vehicle = booking['vehicleType'] ?? 'Logistics';
    final items = booking['items'] as List? ?? [];
    final pAddr = booking['pickupAddress'];
    final rAddr = booking['receivedAddress'];
    final pLoc  = booking['pickup'];
    final dLoc  = booking['dropoff'];
    final date = DateTime.parse(booking['createdAt']).toLocal();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            Text('Booked on ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2,'0')}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(status.toUpperCase(), 
                            style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Addresses
                    _sectionHeader('Addresses'),
                    _detailLocationCard(
                      title: 'Pickup',
                      label: pAddr?['label'] ?? pLoc?['name'] ?? 'Pickup',
                      fullAddress: pAddr?['fullAddress'] ?? pLoc?['address'] ?? '',
                      icon: Icons.circle,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _detailLocationCard(
                      title: 'Delivery',
                      label: rAddr?['label'] ?? dLoc?['name'] ?? 'Drop-off',
                      fullAddress: rAddr?['fullAddress'] ?? dLoc?['address'] ?? '',
                      icon: Icons.location_on,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 24),

                    // Items
                    _sectionHeader('Items (${items.length})'),
                    if (items.isEmpty)
                      const Text('No items specified', style: TextStyle(color: Colors.grey))
                    else
                      ...items.map((it) => _itemCard(it)),

                    const SizedBox(height: 24),

                    // Amount
                    _sectionHeader('Price Breakdown'),
                    _priceRow('Vehicle Price', booking['vehiclePrice'] ?? 0),
                    if ((booking['helperCost'] ?? 0) > 0)
                      _priceRow('Helper Cost', booking['helperCost']),
                    if ((booking['discountAmount'] ?? 0) > 0)
                      _priceRow('Discount', -(booking['discountAmount'] ?? 0), isDiscount: true),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                    _priceRow('Total Amount', booking['totalPrice'] ?? 0, isTotal: true),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
    );
  }

  Widget _detailLocationCard({
    required String title,
    required String label,
    required String fullAddress,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(fullAddress, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(dynamic it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: context.theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.inventory_2_outlined, color: context.theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it['itemName'] ?? 'Item', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(it['type'] ?? 'General', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          if (it['length'] != null)
            Text('${it['length']}x${it['height']}x${it['width']} ${it['unit'] ?? 'cm'}', 
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _priceRow(String label, dynamic amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 18 : 14, 
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? context.colors.textPrimary : context.colors.textSecondary
          )),
          Text('₹${(double.tryParse(amount.toString()) ?? 0.0).toStringAsFixed(2)}', style: TextStyle(
            fontSize: isTotal ? 22 : 14, 
            fontWeight: FontWeight.bold,
            color: isDiscount ? Colors.green : (isTotal ? context.theme.primaryColor : context.colors.textPrimary)
          )),
        ],
      ),
    );
  }
}
