import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/logistics_booking_provider.dart';
import '../../domain/models/logistics_booking.dart';
import '../../../../core/theme/app_theme.dart';

class LogisticsBookingScreen extends ConsumerWidget {
  final LogisticsBookingStatus? filterStatus;

  const LogisticsBookingScreen({super.key, this.filterStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(filteredLogisticsBookingsProvider(filterStatus));
    final statusLabel = _getStatusLabel(filterStatus);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        title: Text(statusLabel, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bookings.isEmpty
          ? Center(
              child: Text('No shipments found', 
                style: TextStyle(color: AppTheme.textMutedLight)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return _buildSimpleShipmentCard(booking);
              },
            ),
    );
  }

  Widget _buildSimpleShipmentCard(LogisticsBooking booking) {
    final statusColor = _getStatusColor(booking.status);
    final dateStr = DateFormat('MMM dd, hh:mm a').format(booking.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BOOKED BY: ${booking.userName.toUpperCase()}',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusLabel(booking.status).toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRow('PICKUP:', booking.pickupName, Icons.location_on_outlined, const Color(0xFF4ADE80)),
          const SizedBox(height: 12),
          _buildRow('DROP:', booking.dropName, Icons.flag_outlined, const Color(0xFFF43F5E)),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderDark, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MODE OF TRAVEL', style: TextStyle(color: AppTheme.textMutedLight, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _getModeIcon(booking.modeOfTravel),
                      const SizedBox(width: 6),
                      Text(booking.modeOfTravel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PRICE', style: TextStyle(color: AppTheme.textMutedLight, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('₹${booking.price.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Ordered on: $dateStr', 
            style: TextStyle(color: AppTheme.textMutedLight, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, IconData icon, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textMutedLight, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getModeIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'flight': return const Icon(Icons.airplanemode_active, size: 16, color: Colors.blueAccent);
      case 'sea': return const Icon(Icons.directions_boat, size: 16, color: Colors.cyanAccent);
      case 'train': return const Icon(Icons.train, size: 16, color: Colors.orangeAccent);
      default: return const Icon(Icons.local_shipping, size: 16, color: AppTheme.primaryColor);
    }
  }

  Color _getStatusColor(LogisticsBookingStatus status) {
    switch (status) {
      case LogisticsBookingStatus.pending: return const Color(0xFFFBBF24);
      case LogisticsBookingStatus.processing: return const Color(0xFF60A5FA);
      case LogisticsBookingStatus.inTransit: return const Color(0xFF818CF8);
      case LogisticsBookingStatus.completed: return const Color(0xFF34D399);
      case LogisticsBookingStatus.cancelled: return const Color(0xFF94A3B8);
      case LogisticsBookingStatus.delayed: return const Color(0xFFF43F5E);
    }
  }

  String _getStatusLabel(LogisticsBookingStatus? status) {
    if (status == null) return "All Bookings";
    switch (status) {
      case LogisticsBookingStatus.pending: return "Pending";
      case LogisticsBookingStatus.processing: return "Processing";
      case LogisticsBookingStatus.inTransit: return "In-Transit";
      case LogisticsBookingStatus.completed: return "Completed";
      case LogisticsBookingStatus.cancelled: return "Cancelled";
      case LogisticsBookingStatus.delayed: return "Delayed";
    }
  }
}
