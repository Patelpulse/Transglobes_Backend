import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/driver_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/network_avatar.dart';

class AdminDriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback onViewProfile;

  const AdminDriverCard({
    super.key,
    required this.driver,
    required this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top Image Section
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: NetworkAvatarBox(
                imageUrl: driver.imageUrl.isNotEmpty ? driver.imageUrl : null,
                name: driver.name,
                size: 300,
                shape: BoxShape.rectangle,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        driver.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF101828),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (driver.status == DriverStatus.suspended)
                      _buildBadge('SUSPENDED', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                    if (driver.isFraudulent) ...[
                      if (driver.status == DriverStatus.suspended) const SizedBox(width: 8),
                      _buildBadge(
                        'FRAUDULENT',
                        const Color(0xFFFFEDD5),
                        const Color(0xFF9A3412),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                    if (driver.status == DriverStatus.active && !driver.isFraudulent)
                       _buildBadge('ACTIVE', const Color(0xFFDCFCE7), const Color(0xFF166534)),
                    if (driver.status == DriverStatus.pending)
                       _buildBadge('PENDING', const Color(0xFFE0F2FE), const Color(0xFF075985)),
                  ],
                ),

                const SizedBox(height: 24),

                // Details
                _buildDetailItem(
                  Icons.badge_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.licenseNumber ?? 'No license info',
                        style: const TextStyle(color: Color(0xFF101828), fontWeight: FontWeight.bold),
                      ),
                      if (driver.aadharCardNumber != null)
                        Text(
                          "Aadhar: ${driver.aadharCardNumber}",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                      if (driver.panCardNumber != null)
                        Text(
                          "PAN: ${driver.panCardNumber}",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  Icons.directions_car_outlined,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.vehicleInfo ?? 'No vehicle info',
                        style: const TextStyle(color: Color(0xFF101828), fontWeight: FontWeight.bold),
                      ),
                      if (driver.vehicleYear != null)
                        Text(
                          "Mfg: ${driver.vehicleYear}",
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  Icons.phone_outlined,
                  Text(
                    driver.mobileNumber ?? 'Not provided',
                    style: const TextStyle(color: Color(0xFF101828), fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 24),

                // Earnings Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TOTAL EARNINGS',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        formatCurrency.format(driver.walletBalance),
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // View Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bgColor, Color textColor, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, Widget content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(child: content),
      ],
    );
  }
}
