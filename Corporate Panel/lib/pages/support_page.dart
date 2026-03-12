import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLow,
      appBar: AppBar(
        title: Text('TRANSGLOBE CONCIERGE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildContactHero(),
            const SizedBox(height: 32),
            _buildActionItem(LucideIcons.messageSquare, 'Live Chat Support', 'Estimated wait: < 2 mins', Colors.blue),
            _buildActionItem(LucideIcons.phoneCall, 'Emergency Helpline', '+91 1800 200 4455', Colors.green),
            _buildActionItem(LucideIcons.mail, 'Professional Help', 'priority@transglobe.log', AppTheme.electricBlue),
            _buildActionItem(LucideIcons.shieldAlert, 'Dispute Resolution', 'Open a legal ticket', Colors.red),
            const SizedBox(height: 32),
            _buildFaqSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.lifeBuoy, color: AppTheme.accentOrange, size: 60),
          const SizedBox(height: 24),
          Text('HOW CAN WE HELP?', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Our logistics experts are standing by to assist with your fleet deployments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.glassBorder)),
      child: ListTile(
        onTap: () {},
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(color: AppTheme.slateGray, fontSize: 11)),
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.slateGray),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }

  Widget _buildFaqSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('POPULAR FAQS', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slateGray, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.glassBorder)),
          child: Column(
            children: [
              _buildFaqItem('How do I cancel a multi-leg chain?'),
              const Divider(color: AppTheme.glassBorder),
              _buildFaqItem('What is the wait time for sea transport?'),
              const Divider(color: AppTheme.glassBorder),
              _buildFaqItem('Can I change hub mid-shipment?'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryBlue)),
          const Icon(LucideIcons.helpCircle, size: 16, color: AppTheme.slateGray),
        ],
      ),
    );
  }
}
