import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/booking_model.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.darkDivider.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVehicleBadge(),
                Text(
                  '₹${booking.fare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.neonGreen,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRouteInfo(),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.darkDivider, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _infoPill(Icons.history, '${booking.distanceKm} km'),
                const SizedBox(width: 8),
                _infoPill(Icons.access_time, '${booking.etaMinutes} min'),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppTheme.darkTextSecondary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleBadge() {
    final color = booking.vehicleType == 'cab' ? AppTheme.cabBlue : 
                  booking.vehicleType == 'truck' ? AppTheme.truckOrange : AppTheme.busPurple;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        booking.subType.toUpperCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.trip_origin, color: AppTheme.neonGreen, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                booking.pickupAddress,
                style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Container(
          height: 16,
          margin: const EdgeInsets.only(left: 7),
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppTheme.darkDivider, width: 2)),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.location_on, color: AppTheme.offlineRed, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                booking.dropAddress,
                style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.darkBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.darkTextSecondary, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
