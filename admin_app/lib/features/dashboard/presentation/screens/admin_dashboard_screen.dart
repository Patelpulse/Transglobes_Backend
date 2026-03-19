import 'package:flutter/material.dart';
import '../../../../shared/widgets/summary_tile.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : (MediaQuery.of(context).size.width > 800 ? 3 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                const SummaryTile(
                  icon: Icons.phone,
                  label: 'Country Code',
                  value: '239',
                  backgroundColor: Color(0xFF4C86FF),
                ),
                const SummaryTile(
                  icon: Icons.pages,
                  label: 'Extra Pages',
                  value: '3',
                  backgroundColor: Color(0xFFA832FF),
                ),
                const SummaryTile(
                  icon: Icons.help_outline,
                  label: 'FAQ',
                  value: '9',
                  backgroundColor: Color(0xFFFF8126),
                ),
                const SummaryTile(
                  icon: Icons.local_shipping,
                  label: 'Vehicle',
                  value: '4',
                  backgroundColor: Color(0xFF45D076),
                ),
                const SummaryTile(
                  icon: Icons.card_giftcard,
                  label: 'Coupon Code',
                  value: '2',
                  backgroundColor: Color(0xFFFF3266),
                ),
                const SummaryTile(
                  icon: Icons.people_outline,
                  label: 'Vehicle Partner',
                  value: '4',
                  backgroundColor: Color(0xFFFF8126),
                ),
                const SummaryTile(
                  icon: Icons.person_add_alt_1,
                  label: 'Approved Vehicle Partner',
                  value: '3',
                  backgroundColor: Color(0xFF45D076),
                ),
                const SummaryTile(
                  icon: Icons.person_add_alt,
                  label: 'Pending Vehicle Partner',
                  value: '1',
                  backgroundColor: Color(0xFFA832FF),
                ),
                const SummaryTile(
                  icon: Icons.credit_card,
                  label: 'Payment Gateway',
                  value: '9',
                  backgroundColor: Color(0xFFA832FF),
                ),
                const SummaryTile(
                  icon: Icons.group,
                  label: 'Users',
                  value: '584',
                  backgroundColor: Color(0xFFFF3266),
                ),
                const SummaryTile(
                  icon: Icons.bolt,
                  label: 'Pending Trips',
                  value: '978',
                  backgroundColor: Color(0xFF4C86FF),
                ),
                const SummaryTile(
                  icon: Icons.bolt,
                  label: 'Accepted Trips',
                  value: '0',
                  backgroundColor: Color(0xFFFF3266),
                ),
                const SummaryTile(
                  icon: Icons.bolt,
                  label: 'Reach Location Trips',
                  value: '0',
                  backgroundColor: Color(0xFFFF8126),
                ),
                const SummaryTile(
                  icon: Icons.bolt,
                  label: 'Ride Start Trips',
                  value: '0',
                  backgroundColor: Color(0xFFA832FF),
                ),
                const SummaryTile(
                  icon: Icons.bolt,
                  label: 'Completed Trips',
                  value: '2',
                  backgroundColor: Color(0xFF45D076),
                ),
                const SummaryTile(
                  icon: Icons.bolt,
                  label: 'Cancelled Trips',
                  value: '0',
                  backgroundColor: Color(0xFFFF3266),
                ),
                const SummaryTile(
                  icon: Icons.account_balance_wallet,
                  label: 'Completed Payout',
                  value: '0\$',
                  backgroundColor: Color(0xFF45D076),
                ),
                const SummaryTile(
                  icon: Icons.account_balance_wallet,
                  label: 'Pending Payout',
                  value: '10\$',
                  backgroundColor: Color(0xFFA832FF),
                ),
                const SummaryTile(
                  icon: Icons.account_balance_wallet,
                  label: 'Total Payout',
                  value: '10\$',
                  backgroundColor: Color(0xFFFF8126),
                ),
                const SummaryTile(
                  icon: Icons.savings,
                  label: 'Total Earning',
                  value: '150\$',
                  backgroundColor: Color(0xFFA832FF),
                ),
                const SummaryTile(
                  icon: Icons.savings,
                  label: 'Your Earning',
                  value: '21\$',
                  backgroundColor: Color(0xFFFF3266),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
