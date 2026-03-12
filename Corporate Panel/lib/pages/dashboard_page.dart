import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/logistics_provider.dart';
import '../models/logistics_request.dart';
import 'request_form_page.dart';
import 'shipments_page.dart';
import 'tracking_page.dart';
import 'profile_page.dart';
import 'billing_page.dart';
import 'support_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _HomeView(onTabChange: _onTabChange),
      const ShipmentsPage(),
      const SizedBox.shrink(), // Placeholder for center button
      const TrackingPage(),
      const ProfilePage(),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Scaffold(
      drawer: isDesktop ? null : _buildModernDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildPermanentSidebar(context),
          Expanded(
            child: pages[_selectedIndex == 2 ? 0 : _selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomNav(),
      floatingActionButton: isDesktop ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const RequestFormPage()),
          );
        },
        backgroundColor: AppTheme.electricBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(LucideIcons.plus),
        label: Text('NEW SHIPMENT', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.glassBorder, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) { // New Request center button
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RequestFormPage()));
          } else {
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.electricBlue,
        unselectedItemColor: AppTheme.slateGray,
        selectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.outfit(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.layoutDashboard, size: 20), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.ship, size: 20), label: 'Order'),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.electricBlue,
              child: Icon(LucideIcons.plus, color: Colors.white, size: 20),
            ),
            label: '',
          ),
          BottomNavigationBarItem(icon: Icon(LucideIcons.map, size: 20), label: 'Track'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user, size: 20), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPermanentSidebar(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 0)),
        ],
      ),
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.primaryBlue,
      child: _buildDrawerContent(context),
    );
  }

  Widget _buildDrawerContent(BuildContext context) {
    return Column(
      children: [
        DrawerHeader(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: AppTheme.primaryBlue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.electricBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.package2, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'TRANSGLOBE',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Enterprise Dashboard',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const Text(
                'Transglobe Logistics',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        _buildDrawerItem(LucideIcons.layoutDashboard, 'Overview', _selectedIndex == 0, () => setState(() => _selectedIndex = 0)),
        _buildDrawerItem(LucideIcons.ship, 'My Shipments', _selectedIndex == 1, () => setState(() => _selectedIndex = 1)),
        _buildDrawerItem(LucideIcons.map, 'Track Maps', _selectedIndex == 3, () => setState(() => _selectedIndex = 3)),
        _buildDrawerItem(LucideIcons.user, 'Profile', _selectedIndex == 4, () => setState(() => _selectedIndex = 4)),
        const Spacer(),
        const Divider(color: Colors.white10),
        _buildDrawerItem(LucideIcons.settings, 'Settings', false, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings Coming Soon')));
        }),
        _buildDrawerItem(LucideIcons.logOut, 'Sign Out', false, () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: selected ? Colors.white : Colors.white54,
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: AppTheme.electricBlue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
    );
  }
}

class _HomeView extends StatelessWidget {
  final Function(int) onTabChange;
  const _HomeView({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LogisticsProvider>(context);
    final requests = provider.requests;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    return Container(
      color: AppTheme.bgLow,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: CustomScrollView(
            slivers: [
              _SliverHeader(isMobile: !isDesktop, onTabChange: onTabChange),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 60 : 20,
                    vertical: isDesktop ? 40 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroBanner(isDesktop: isDesktop),
                      const SizedBox(height: 40),
                      _SectionLabel('QUICK ACTIONS'),
                      const SizedBox(height: 20),
                      _QuickActionsGrid(isDesktop: isDesktop, onTabChange: onTabChange),
                      const SizedBox(height: 48),
                      _SectionLabel('ANALYTICS SUMMARY'),
                      const SizedBox(height: 20),
                      _AnalyticsRow(requests: requests, isDesktop: isDesktop),
                      const SizedBox(height: 48),
                      _SectionLabel('LATEST ACTIVITY'),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              requests.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(isDesktop: isDesktop),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _RequestCard(req: requests[index]),
                          childCount: requests.length,
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverHeader extends StatelessWidget {
  final bool isMobile;
  final Function(int) onTabChange;
  const _SliverHeader({required this.isMobile, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      centerTitle: isMobile,
      automaticallyImplyLeading: false, 
      backgroundColor: AppTheme.bgLow.withOpacity(0.8),
      elevation: 0,
      title: Text(
        isMobile ? 'TRANSGLOBE' : 'CONTROL CENTER',
        style: GoogleFonts.outfit(
          fontSize: 16, 
          fontWeight: FontWeight.bold, 
          letterSpacing: isMobile ? 4 : 2,
          color: AppTheme.primaryBlue,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.bell, size: 20, color: AppTheme.primaryBlue), 
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
          }
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => onTabChange(4),
          borderRadius: BorderRadius.circular(20),
          child: _UserAvatar(),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.electricBlue.withOpacity(0.3), width: 2),
      ),
      child: const CircleAvatar(
        radius: 14,
        backgroundColor: AppTheme.electricBlue,
        child: Icon(LucideIcons.user, color: Colors.white, size: 16),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  final bool isDesktop;
  const _HeroBanner({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isDesktop ? 350 : 230, 
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(32),
        image: const DecorationImage(
          image: AssetImage('assets/hero.png'),
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 64 : 24,
          vertical: isDesktop ? 64 : 32,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.primaryBlue.withOpacity(0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: AppTheme.electricBlue, borderRadius: BorderRadius.circular(30)),
              child: Text(
                'PREMIUM ENTERPRISE',
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome back,\nTransglobe Client',
              style: GoogleFonts.outfit(
                color: Colors.white, 
                fontSize: isDesktop ? 48 : 24, 
                fontWeight: FontWeight.bold, 
                height: 1.1,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your logistics pipeline is operating normally.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7), 
                fontSize: isDesktop ? 18 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: AppTheme.slateGray,
        letterSpacing: 2,
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final bool isDesktop;
  final Function(int) onTabChange;
  const _QuickActionsGrid({required this.isDesktop, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = isDesktop ? (screenWidth > 1400 ? 4 : 3) : 2;
    double spacing = isDesktop ? 24 : 16;

    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _ActionCard(icon: LucideIcons.plusCircle, title: 'New Order', sub: 'Shipment startup', color: AppTheme.electricBlue, width: cardWidth, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RequestFormPage()))),
          _ActionCard(icon: LucideIcons.mapPin, title: 'Track Live', sub: 'GPS pipeline', color: AppTheme.accentOrange, width: cardWidth, onTap: () => onTabChange(3)),
          _ActionCard(icon: LucideIcons.fileText, title: 'Billing', sub: 'Invoices & Tax', color: Colors.teal, width: cardWidth, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BillingPage()))),
          _ActionCard(icon: LucideIcons.lifeBuoy, title: 'Support', sub: 'Concierge', color: Colors.purple, width: cardWidth, onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SupportPage()))),
        ],
      );
    });
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String sub;
  final Color color;
  final double width;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.sub, required this.color, required this.width, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 20),
            Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryBlue)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppTheme.slateGray)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final List<LogisticsRequest> requests;
  final bool isDesktop;
  const _AnalyticsRow({required this.requests, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int count = isDesktop ? (screenWidth > 1400 ? 4 : 3) : 2;
    double spacing = isDesktop ? 24 : 16;

    return LayoutBuilder(builder: (context, constraints) {
      final double cardWidth = (constraints.maxWidth - (count - 1) * spacing) / count;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          _StatCard(label: 'Total Orders', value: requests.length.toString(), icon: LucideIcons.package2, color: AppTheme.electricBlue, width: cardWidth),
          _StatCard(label: 'Success Rate', value: '98.4%', icon: LucideIcons.activity, color: Colors.green, width: cardWidth),
          if (isDesktop) ...[
            _StatCard(label: 'Fleet Status', value: 'Optimal', icon: LucideIcons.shieldCheck, color: Colors.teal, width: cardWidth),
            if (screenWidth > 1400)
              _StatCard(label: 'Active GPS', value: '24/30', icon: LucideIcons.navigation, color: AppTheme.accentOrange, width: cardWidth),
          ],
        ],
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 20),
          Text(value, style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.slateGray, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDesktop;
  const _EmptyState({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isDesktop ? 100 : 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/empty.png', height: isDesktop ? 280 : 180),
          const SizedBox(height: 32),
          Text(
            'Pipeline Status: Idle',
            style: GoogleFonts.outfit(fontSize: isDesktop ? 32 : 20, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Create a new order to begin Transglobe logistics deployment.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.slateGray, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final LogisticsRequest req;
  const _RequestCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.bgLow, borderRadius: BorderRadius.circular(12)),
              child: const Icon(LucideIcons.package, color: AppTheme.electricBlue, size: 18),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SHIPMENT REQ-${req.id.substring(0, 6).toUpperCase()}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue),
                  ),
                  Text('${req.pickupLocation} → ${req.destinationLocation}', style: const TextStyle(fontSize: 12, color: AppTheme.slateGray)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormat.format(req.estimatedPrice), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.electricBlue)),
                Text(req.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
