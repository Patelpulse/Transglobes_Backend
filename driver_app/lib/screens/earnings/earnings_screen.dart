import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/booking_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});
  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> with SingleTickerProviderStateMixin {
  String _period = 'Today';

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    final history = ref.watch(historyBookingsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.darkSurface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.earningsAmber.withValues(alpha: 0.2), AppTheme.darkSurface],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Earnings', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 22)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryCard('Today', '₹2,450', AppTheme.neonGreen),
                            _buildSummaryCard('Week', '₹14,280', AppTheme.cabBlue),
                            _buildSummaryCard('Month', '₹48,650', AppTheme.earningsAmber),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  _buildPeriodSelector(),
                  const SizedBox(height: 20),
                  // Bar chart
                  _buildBarChart(),
                  const SizedBox(height: 20),
                  // Incentive card
                  _buildIncentiveCard(),
                  const SizedBox(height: 20),
                  const Text('Recent Trips', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildTripRow(history[i % history.length]),
              childCount: history.isEmpty ? 1 : 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: ['Today', 'Week', 'Month'].map((p) {
          final sel = _period == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _period = p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: sel ? AppTheme.earningsGradient : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(p, textAlign: TextAlign.center, style: TextStyle(color: sel ? Colors.white : AppTheme.darkTextSecondary, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, fontSize: 13)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    final data = {'M': 0.5, 'T': 0.7, 'W': 0.95, 'T ': 0.6, 'F': 1.0, 'Sa': 0.45, 'Su': 0.3};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly Overview', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
              Text('₹14,280', style: const TextStyle(color: AppTheme.earningsAmber, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.entries.map((e) {
                return Expanded(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween(begin: 0, end: e.value),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 70 * v,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: e.key == 'F' ? [AppTheme.earningsAmber, AppTheme.truckOrange] : [AppTheme.earningsAmber.withValues(alpha: 0.5), AppTheme.earningsAmber.withValues(alpha: 0.2)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(e.key, style: TextStyle(color: e.key == 'F' ? AppTheme.earningsAmber : AppTheme.darkTextSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncentiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.busPurple.withValues(alpha: 0.15), AppTheme.cabBlue.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.busPurple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppTheme.earningsAmber, size: 22),
              const SizedBox(width: 10),
              const Expanded(child: Text('Complete 15 rides, earn ₹1,000 bonus!', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0, end: 12 / 15),
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                backgroundColor: AppTheme.darkDivider,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.earningsAmber),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 of 15 rides completed', style: TextStyle(color: AppTheme.darkTextSecondary, fontSize: 12)),
              Text('3 more to go!', style: TextStyle(color: AppTheme.earningsAmber, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripRow(BookingModel b) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.earningsAmber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.directions_car, color: AppTheme.earningsAmber, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.userName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('${b.distanceKm} km • ${b.subType}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            Text('+₹${b.fare.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.neonGreen, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
