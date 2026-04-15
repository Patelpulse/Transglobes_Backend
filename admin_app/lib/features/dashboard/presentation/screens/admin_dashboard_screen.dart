import 'package:flutter/material.dart';
import '../../../../shared/widgets/summary_tile.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingLifecycle = [
      const _LifecycleChip(
        label: 'Pending',
        count: '214',
        color: Color(0xFFF59E0B),
      ),
      const _LifecycleChip(
        label: 'Accepted',
        count: '168',
        color: Color(0xFF6366F1),
      ),
      const _LifecycleChip(
        label: 'Assigned',
        count: '156',
        color: Color(0xFF2563EB),
      ),
      const _LifecycleChip(
        label: 'In Transit',
        count: '122',
        color: Color(0xFF0EA5E9),
      ),
      const _LifecycleChip(
        label: 'Completed',
        count: '980',
        color: Color(0xFF16A34A),
      ),
      const _LifecycleChip(
        label: 'Cancelled',
        count: '39',
        color: Color(0xFFEF4444),
      ),
    ];

    final bool largeDesktop = MediaQuery.of(context).size.width > 1300;
    final bool desktop = MediaQuery.of(context).size.width > 900;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transglobe Admin Command Center',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Live overview of booking, logistics, pricing, payouts and security modules.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: largeDesktop ? 4 : (desktop ? 3 : 2),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.45,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: const [
                SummaryTile(
                  icon: Icons.people_alt_outlined,
                  label: 'Active Users',
                  value: '2,421',
                  backgroundColor: Color(0xFF2563EB),
                ),
                SummaryTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Online Drivers',
                  value: '418',
                  backgroundColor: Color(0xFF0EA5E9),
                ),
                SummaryTile(
                  icon: Icons.warehouse_outlined,
                  label: 'Logistics Orders',
                  value: '938',
                  backgroundColor: Color(0xFF7C3AED),
                ),
                SummaryTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Today Revenue',
                  value: 'INR 4.8L',
                  backgroundColor: Color(0xFF16A34A),
                ),
                SummaryTile(
                  icon: Icons.currency_rupee_rounded,
                  label: 'Pending Settlements',
                  value: 'INR 92K',
                  backgroundColor: Color(0xFFF59E0B),
                ),
                SummaryTile(
                  icon: Icons.security_outlined,
                  label: 'Security Alerts',
                  value: '03',
                  backgroundColor: Color(0xFFDC2626),
                ),
                SummaryTile(
                  icon: Icons.discount_outlined,
                  label: 'Active Coupons',
                  value: '14',
                  backgroundColor: Color(0xFFEC4899),
                ),
                SummaryTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Pending Notifications',
                  value: '26',
                  backgroundColor: Color(0xFF1D4ED8),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Lifecycle',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: bookingLifecycle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio:
                  MediaQuery.of(context).size.width > 1100 ? 1.35 : 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                _ModuleStatusCard(
                  title: 'Auth and Security',
                  status: 'In Progress',
                  highlights: [
                    'OTP login enabled for all apps',
                    'RBAC mapped for admin, supervisor, driver and user',
                    'JWT + session timeout hardening pending',
                  ],
                ),
                _ModuleStatusCard(
                  title: 'Booking and Pricing Engine',
                  status: 'Core Ready',
                  highlights: [
                    'Instant + Scheduled + Logistics flows',
                    'Lifecycle states synced across modules',
                    'Dynamic pricing and cancellation controls active',
                  ],
                ),
                _ModuleStatusCard(
                  title: 'Payments and Compliance',
                  status: 'Needs QA',
                  highlights: [
                    'UPI/Card wallet experience connected',
                    'Invoice/refund pipeline available',
                    'GST/legal document checks remaining',
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _ActionPanel(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _LifecycleChip extends StatelessWidget {
  final String label;
  final String count;
  final Color color;

  const _LifecycleChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleStatusCard extends StatelessWidget {
  final String title;
  final String status;
  final List<String> highlights;

  const _ModuleStatusCard({
    required this.title,
    required this.status,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Color(0xFF3730A3),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...highlights.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
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
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Focus (Admin)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '1) Verify supervisor roadmap for high-value logistics orders.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          SizedBox(height: 6),
          Text(
            '2) Review pending driver KYC and settlement exceptions.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          SizedBox(height: 6),
          Text(
            '3) Validate surge pricing + coupon impact before peak hours.',
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
