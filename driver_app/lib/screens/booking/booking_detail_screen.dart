import 'package:flutter/material.dart';
import 'package:driver_app/models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/screens/chat/chat_screen.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/booking_provider.dart';
import '../../widgets/delay_reason_sheet.dart';
import '../navigation/navigation_screen.dart';
import 'package:latlong2/latlong.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;

  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = [...ref.watch(pendingBookingsProvider), ...ref.watch(activeBookingsProvider), ...ref.watch(historyBookingsProvider)];
    final booking = bookings.firstWhere((b) => b.id == bookingId);

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
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.neonGreen.withValues(alpha: 0.1),
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
              if (booking.status == 'arrived') {
                _showOTPDialog(context, ref, booking);
              } else {
                String nextStatus = '';
                if (booking.status == 'accepted') nextStatus = 'on_the_way';
                else if (booking.status == 'on_the_way') nextStatus = 'arrived';
                else if (booking.status == 'ongoing') nextStatus = 'completed';
                
                if (nextStatus == 'completed') {
                  _showCompleteTripDialog(context, ref, booking);
                } else if (nextStatus.isNotEmpty) {
                  ref.read(bookingProvider.notifier).updateStatus(booking.id, nextStatus);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonGreen,
              foregroundColor: AppTheme.darkBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _buttonLabel(booking.status),
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
                  LatLng? dest;
                  String destName = '';

                  if (['accepted', 'on_the_way'].contains(booking.status)) {
                    dest = LatLng(booking.pickupLat ?? 26.8467, booking.pickupLng ?? 80.9462);
                    destName = 'Pickup: ${booking.pickupAddress}';
                  } else {
                    dest = LatLng(booking.dropLat ?? 26.8467, booking.dropLng ?? 80.9462);
                    destName = 'Drop: ${booking.dropAddress}';
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(
                        destination: dest!,
                        destinationName: destName,
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

  String _buttonLabel(String status) {
    switch (status) {
      case 'accepted': return 'ON THE WAY';
      case 'on_the_way': return 'I HAVE ARRIVED';
      case 'arrived': return 'VERIFY OTP';
      case 'ongoing': return 'COMPLETE TRIP';
      default: return 'CONTINUE';
    }
  }

  void _showOTPDialog(BuildContext context, WidgetRef ref, BookingModel booking) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Verify User OTP', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter the 4-digit code provided by the passenger:', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.neonGreen, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 20),
              decoration: InputDecoration(
                counterText: '',
                fillColor: AppTheme.darkBg,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.neonGreen)),
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
            onPressed: () async {
              try {
                await ref.read(bookingProvider.notifier).verifyOtp(booking.id, controller.text);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid OTP. Please try again.'), backgroundColor: AppTheme.offlineRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: AppTheme.darkBg),
            child: const Text('VERIFY & START'),
          ),
        ],
      ),
    );
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
