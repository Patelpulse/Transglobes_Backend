import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../core/config.dart';
import '../services/auth_service.dart';
import '../core/theme.dart';
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
      final userId = authService.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _error = "User not logged in";
          _isLoading = false;
        });
        return;
      }

      final url = Uri.parse('${AppConfig.apiBaseUrl}/api/logistics-bookings/user/$userId');
      final token = await authService.getIdToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status.toUpperCase(), 
                        style: TextStyle(color: _getStatusColor(status), fontSize: 10, fontWeight: FontWeight.bold)),
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
                      child: Icon(Icons.local_shipping_rounded, color: context.theme.primaryColor),
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
                    Text('₹${booking['totalPrice']}', 
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
            onTap: () {
              // Navigate to details or track
            },
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
}
