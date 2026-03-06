import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Balance card
                Container(
                  margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.earningsAmber.withValues(alpha: 0.15), AppTheme.darkSurface],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text('Wallet', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 22)),
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFFF8F00), Color(0xFFFFB300)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppTheme.earningsAmber.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 8),
                            Text('₹${wallet.balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildMiniStat('Total Earned', '₹${(wallet.totalEarned / 1000).toStringAsFixed(1)}k'),
                                const SizedBox(width: 24),
                                _buildMiniStat('Total Paid Out', '₹${(wallet.totalPaidOut / 1000).toStringAsFixed(1)}k'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Payout button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(context, AppRouter.payout),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.darkCard,
                            foregroundColor: AppTheme.earningsAmber,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.earningsAmber.withValues(alpha: 0.3))),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.account_balance, size: 20),
                          label: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Stats row
                      Row(
                        children: [
                          _buildStatBox('Today', '₹${wallet.todayEarnings.toStringAsFixed(0)}', AppTheme.neonGreen),
                          const SizedBox(width: 10),
                          _buildStatBox('This Week', '₹${wallet.weekEarnings.toStringAsFixed(0)}', AppTheme.cabBlue),
                          const SizedBox(width: 10),
                          _buildStatBox('This Month', '₹${wallet.monthEarnings.toStringAsFixed(0)}', AppTheme.busPurple),
                        ],
                      ),
                    ],
                  ),
                ),
                // Transactions header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transactions', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, AppRouter.bankAccounts),
                        child: const Text('Manage Banks', style: TextStyle(color: AppTheme.neonGreen, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _TransactionTile(txn: wallet.transactions[i]),
              childCount: wallet.transactions.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.04)]), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.15))),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isCredit = txn.isCredit;
    final icon = switch(txn.type) {
      'ride' => Icons.directions_car,
      'payout' => Icons.account_balance,
      'bonus' => Icons.emoji_events,
      'commission' => Icons.percent,
      _ => Icons.attach_money,
    };
    final color = switch(txn.type) {
      'ride' => AppTheme.neonGreen,
      'payout' => AppTheme.cabBlue,
      'bonus' => AppTheme.earningsAmber,
      'commission' => AppTheme.offlineRed,
      _ => AppTheme.darkTextSecondary,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.description, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 3),
                  Text(_formatTime(txn.time), style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
                ],
              ),
            ),
            Text('${isCredit ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}', style: TextStyle(color: isCredit ? AppTheme.neonGreen : AppTheme.offlineRed, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}
