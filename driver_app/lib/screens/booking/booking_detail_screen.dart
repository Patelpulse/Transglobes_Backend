import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;

import 'package:driver_app/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/screens/chat/chat_screen.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/delay_reason_sheet.dart';
import '../navigation/navigation_screen.dart';
import 'active_ride_screen.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingBookingsProvider);
    final active = ref.watch(activeBookingsProvider);
    final history = ref.watch(historyBookingsProvider);
    final allBookings = [...pending, ...active, ...history];

    final booking = allBookings.cast<BookingModel?>().firstWhere(
      (b) => b?.id == bookingId,
      orElse: () => null,
    );

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          backgroundColor: AppTheme.darkSurface,
          elevation: 0,
          title: const Text('Trip Details', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: AppTheme.darkTextSecondary, size: 48),
              const SizedBox(height: 16),
              const Text('Trip not found or still loading...', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('GO BACK'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonGreen,
                  foregroundColor: AppTheme.darkBg,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('Trip Details', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(booking),
            const SizedBox(height: 24),
            _buildPassengerCard(context, ref, booking),
            const SizedBox(height: 24),
            _buildRouteCard(booking),
            const SizedBox(height: 24),
            _buildFareBreakdown(booking),
            const SizedBox(height: 40),
            
            if (booking.status != 'completed' && booking.status != 'cancelled')
              _buildActionButtons(context, ref, booking),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.neonGreen.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: AppTheme.neonGreen, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Status', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
                Text(
                  booking.status.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(color: AppTheme.neonGreen, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(BuildContext context, WidgetRef ref, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.cabBlue,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.userName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.earningsAmber, size: 14),
                    const SizedBox(width: 4),
                    const Text('4.8 • 120 Trips', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppTheme.neonGreen),
            onPressed: () async {
              final Uri url = Uri(scheme: 'tel', path: booking.userPhone);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.cabBlue),
            onPressed: () {
              final driverProfile = ref.read(driverProfileProvider).value;
              if (driverProfile != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      receiverId: booking.userId ?? '',
                      receiverName: booking.userName,
                      driverId: driverProfile.id,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.darkDivider),
      ),
      child: Column(
        children: [
          _routeItem(Icons.trip_origin, AppTheme.neonGreen, 'Pickup', booking.pickupAddress),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const SizedBox(width: 11),
                Column(children: List.generate(4, (i) => Container(width: 2, height: 4, margin: const EdgeInsets.symmetric(vertical: 2), color: AppTheme.darkDivider))),
              ],
            ),
          ),
          _routeItem(Icons.location_on, AppTheme.offlineRed, 'Drop-off', booking.dropAddress),
        ],
      ),
    );
  }

  Widget _routeItem(IconData icon, Color color, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
              Text(address, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFareBreakdown(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Est. Fare', style: TextStyle(color: AppTheme.darkTextSecondary)),
              Text('₹${booking.fare.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Distance', style: TextStyle(color: AppTheme.darkTextSecondary)),
              Text('5.4 km', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Type', style: TextStyle(color: AppTheme.darkTextSecondary)),
              Text('Cash', style: TextStyle(color: AppTheme.earningsAmber, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, BookingModel booking) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              // Logic to advance status
              if (['accepted', 'on_the_way', 'arrived'].contains(booking.status)) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActiveRideScreen(booking: booking),
                  ),
                );
              } else {
                String nextStatus = '';
                if (booking.status == 'ongoing') nextStatus = 'completed';
                
                if (nextStatus == 'completed') {
                  if (booking.paymentStatus == 'unpaid') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Waiting for customer payment...'),
                        backgroundColor: Colors.orange,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    _showCompleteTripDialog(context, ref, booking);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: AppTheme.darkBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _buttonLabel(booking.status, booking.paymentStatus),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => DelayReasonSheet(onReasonSelected: (r) {}),
                  );
                },
                icon: const Icon(Icons.report_problem_outlined, size: 20),
                label: const Text('REPORT DELAY'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.truckOrange,
                  side: const BorderSide(color: AppTheme.truckOrange),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  gmaps.LatLng? dest;
                  String destName = '';

                  if (['accepted', 'on_the_way'].contains(booking.status)) {
                    dest = gmaps.LatLng(booking.pickupLat ?? 26.8467, booking.pickupLng ?? 80.9462);
                    destName = 'Pickup: ${booking.pickupAddress}';
                  } else {
                    dest = gmaps.LatLng(booking.dropLat ?? 26.8467, booking.dropLng ?? 80.9462);
                    destName = 'Drop: ${booking.dropAddress}';
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        destination: dest!,
                        destinationName: destName,
                        rideId: booking.id,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_outlined, size: 20),
                label: const Text('NAVIGATE'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.cabBlue,
                  side: const BorderSide(color: AppTheme.cabBlue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _buttonLabel(String status, String paymentStatus) {
    switch (status) {
      case 'accepted': 
      case 'on_the_way': 
      case 'arrived': return 'VERIFY OTP & START';
      case 'ongoing': return paymentStatus == 'paid' ? 'COMPLETE TRIP' : 'WAIT FOR PAYMENT';
      default: return 'CONTINUE';
    }
  }

  void _showCompleteTripDialog(BuildContext context, WidgetRef ref, BookingModel booking) {
    final controller = TextEditingController(text: booking.fare.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Complete Trip', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm final fare amount:', style: TextStyle(color: AppTheme.darkTextSecondary)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.neonGreen, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                prefixStyle: TextStyle(color: AppTheme.neonGreen, fontSize: 24),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.darkDivider)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonGreen)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final fare = double.tryParse(controller.text) ?? booking.fare;
              ref.read(bookingProvider.notifier).completeTrip(booking.id, fare);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to Home
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: AppTheme.darkBg),
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );
  }
}
