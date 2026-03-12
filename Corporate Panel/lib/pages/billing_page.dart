import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class BillingPage extends StatelessWidget {
  const BillingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    return Scaffold(
      backgroundColor: AppTheme.bgLow,
      appBar: AppBar(
        title: Text('BILLING & INVOICES', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildBalanceCard(currencyFormat),
            const SizedBox(height: 32),
            _buildSectionHeader('RECENT INVOICES'),
            const SizedBox(height: 16),
            _buildInvoiceItem('INV-98210', 'Mar 08, 2026', 15200.0, 'Paid', currencyFormat),
            _buildInvoiceItem('INV-98209', 'Mar 01, 2026', 8400.0, 'Paid', currencyFormat),
            _buildInvoiceItem('INV-98208', 'Feb 24, 2026', 22100.0, 'Pending', currencyFormat),
            const SizedBox(height: 32),
            _buildPaymentMethods(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(NumberFormat format) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OUTSTANDING BALANCE', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 16),
          Text(format.format(22100.0), style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slateGray, letterSpacing: 1.5)),
        TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12))),
      ],
    );
  }

  Widget _buildInvoiceItem(String id, String date, double amount, String status, NumberFormat format) {
    bool isPending = status == 'Pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.glassBorder)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.bgLow, borderRadius: BorderRadius.circular(10)), child: const Icon(LucideIcons.fileText, color: AppTheme.electricBlue, size: 18)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                Text(date, style: const TextStyle(fontSize: 11, color: AppTheme.slateGray)),
              ]),
            ],
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(format.format(amount), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
            Text(status, style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PAYMENT METHODS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slateGray, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.glassBorder)),
          child: Row(
            children: [
              const Icon(LucideIcons.creditCard, color: AppTheme.primaryBlue, size: 24),
              const SizedBox(width: 16),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Corporate Visa **** 9911', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Expires 09/27', style: TextStyle(fontSize: 11, color: AppTheme.slateGray)),
              ])),
              const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.slateGray),
            ],
          ),
        ),
      ],
    );
  }
}
