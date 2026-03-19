import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/network/socket_service.dart';
import '../../features/auth/providers/admin_profile_provider.dart';
import '../../features/support/providers/notification_provider.dart';

class AdminScaffold extends ConsumerWidget {
  final Widget child;

  const AdminScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/trips')) return 1;
    if (location.startsWith('/country-code')) return 2;
    if (location.startsWith('/page')) return 3;
    if (location.startsWith('/faq')) return 4;
    if (location.startsWith('/vehicle')) return 5;
    if (location.startsWith('/coupon')) return 6;
    if (location.startsWith('/riders')) return 7;
    if (location.startsWith('/payouts')) return 8;
    if (location.startsWith('/payments')) return 9;
    if (location.startsWith('/users')) return 10;
    if (location.startsWith('/super-admin')) return 11;
    if (location.startsWith('/logistics/modes')) return 13;
    if (location.startsWith('/logistics')) return 12;
    return 0; // Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/trips');
        break;
      case 2:
        context.go('/country-code');
        break;
      case 7:
        context.go('/drivers');
        break;
      case 10:
        context.go('/users');
        break;
      case 11:
        context.go('/super-admin');
        break;
      case 12:
        context.go('/logistics');
        break;
      case 13:
        context.go('/logistics/modes');
        break;
      default:
        // Other routes to be implemented
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adminProfile = ref.watch(adminProfileNotifierProvider).value;
    final unreadCount = ref.watch(adminUnreadCountProvider);
    
    // Auto-connect socket when profile is available
    if (adminProfile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(socketServiceProvider).connect(adminProfile.id);
      });
    }

    return ResponsiveBuilder(
      builder: (context, sizingInformation) {
        bool isDesktop =
            sizingInformation.deviceScreenType == DeviceScreenType.desktop;

        final currentIndex = _calculateSelectedIndex(context);

        return Scaffold(
          drawer: isDesktop ? null : _buildDrawer(context, ref, currentIndex, unreadCount),
          body: Row(
            children: [
              if (isDesktop) _buildSidebar(context, ref, currentIndex, unreadCount),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8F9FA), // Light gray background for content
                  child: child,
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop
              ? null
              : Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderDark, width: 1),
                      ),
                    ),
                    child: BottomNavigationBar(
                      currentIndex: currentIndex,
                      onTap: (index) => _onItemTapped(index, context),
                      backgroundColor: AppTheme.backgroundColorDark,
                      type: BottomNavigationBarType.fixed,
                      selectedItemColor: AppTheme.primaryColor,
                      unselectedItemColor: AppTheme.textMutedLight,
                      selectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                      items: [
                        const BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.directions_car),
                          ),
                          label: 'FLEET',
                        ),
                        const BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.people),
                          ),
                          label: 'USERS',
                        ),
                        const BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.account_balance_wallet),
                          ),
                          label: 'FINANCE',
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Badge(
                              label: Text(unreadCount.toString()),
                              isLabelVisible: unreadCount > 0,
                              child: const Icon(Icons.notifications),
                            ),
                          ),
                          label: 'ALERTS',
                        ),
                        const BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Icon(Icons.settings),
                          ),
                          label: 'SETTINGS',
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSidebar(BuildContext context, WidgetRef ref, int currentIndex, int unreadCount) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.dashboard_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Dashboard',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: currentIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _SidebarItem(
                  icon: Icons.bolt,
                  title: 'Trips List',
                  isSelected: currentIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                  subItems: [
                    _SidebarSubItem(title: 'Pending Trips', count: 979, color: const Color(0xFF4ADE80)),
                    _SidebarSubItem(title: 'Accepted Trips', count: 0, color: const Color(0xFFA855F7)),
                    _SidebarSubItem(title: 'Reach Loc. Trips', count: 0, color: const Color(0xFFFB923C)),
                    _SidebarSubItem(title: 'Start Ride Trips', count: 0, color: const Color(0xFFA855F7)),
                    _SidebarSubItem(title: 'Completed Trips', count: 2, color: const Color(0xFF4ADE80)),
                    _SidebarSubItem(title: 'Cancelled Trips', count: 0, color: const Color(0xFFF43F5E)),
                  ],
                ),
                _SidebarItem(
                  icon: Icons.phone,
                  title: 'Country Code',
                  isSelected: currentIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                _SidebarItem(
                  icon: Icons.pages,
                  title: 'Page',
                  isSelected: currentIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                _SidebarItem(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  isSelected: currentIndex == 4,
                  onTap: () => _onItemTapped(4, context),
                ),
                _SidebarItem(
                  icon: Icons.local_shipping,
                  title: 'Vehicle',
                  isSelected: currentIndex == 5,
                  onTap: () => _onItemTapped(5, context),
                ),
                _SidebarItem(
                  icon: Icons.card_giftcard,
                  title: 'Coupon',
                  isSelected: currentIndex == 6,
                  onTap: () => _onItemTapped(6, context),
                ),
                _SidebarItem(
                  icon: Icons.person_add_alt,
                  title: 'Rider List',
                  isSelected: currentIndex == 7,
                  onTap: () => _onItemTapped(7, context),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Payout List',
                  isSelected: currentIndex == 8,
                  onTap: () => _onItemTapped(8, context),
                ),
                _SidebarItem(
                  icon: Icons.credit_card,
                  title: 'Payment Gateway List',
                  isSelected: currentIndex == 9,
                  onTap: () => _onItemTapped(9, context),
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'User List',
                  isSelected: currentIndex == 10,
                  onTap: () => _onItemTapped(10, context),
                ),
                _SidebarItem(
                  icon: Icons.admin_panel_settings,
                  title: 'Super Admin',
                  isSelected: currentIndex == 11,
                  onTap: () => _onItemTapped(11, context),
                ),
                _SidebarItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Logistics & Shipping Management',
                  isSelected: currentIndex == 12,
                  onTap: () => _onItemTapped(12, context),
                  subItems: [
                    _SidebarSubItem(
                      title: 'Logistics on Pending', 
                      count: 0, 
                      color: const Color(0xFFFBBF24),
                      onTap: () => context.go('/logistics/pending'),
                    ),
                    _SidebarSubItem(
                      title: 'Logistics on Processing', 
                      count: 0, 
                      color: const Color(0xFF60A5FA),
                      onTap: () => context.go('/logistics/processing'),
                    ),
                    _SidebarSubItem(
                      title: 'In-Transit / Out for Delivery', 
                      count: 0, 
                      color: const Color(0xFF818CF8),
                      onTap: () => context.go('/logistics/in-transit'),
                    ),
                    _SidebarSubItem(
                      title: 'Logistic Complete on Location', 
                      count: 0, 
                      color: const Color(0xFF34D399),
                      onTap: () => context.go('/logistics/completed'),
                    ),
                    _SidebarSubItem(
                      title: 'Delayed/Alerts', 
                      count: 0, 
                      color: const Color(0xFFF43F5E),
                      onTap: () => context.go('/logistics/alerts'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.1),
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
                elevation: 0,
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, int currentIndex, int unreadCount) {
    return Drawer(
      backgroundColor: AppTheme.backgroundColorDark,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderDark)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: AppTheme.primaryColor, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Admin Portal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined,
                color: AppTheme.textMutedLight),
            title:
                const Text('Dashboard', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline,
                color: AppTheme.textMutedLight),
            title: const Text('User Management',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/users');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_eta_outlined,
                color: AppTheme.textMutedLight),
            title: const Text('Driver Management',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/drivers');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined,
                color: AppTheme.textMutedLight),
            title: const Text('Finance & Pricing',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/finance');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Stack(
              children: [
                const Icon(Icons.notifications_outlined,
                    color: AppTheme.textMutedLight),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title:
                const Text('Alerts & Support', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/alerts');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined,
                color: AppTheme.textMutedLight),
            title: const Text('Settings', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/settings');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping_outlined,
                color: AppTheme.textMutedLight),
            title: const Text('Logistics Management', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/logistics');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined,
                color: AppTheme.textMutedLight),
            title: const Text('Super Admin Management', style: TextStyle(color: Colors.white)),
            onTap: () {
              context.go('/super-admin');
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Logout',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                ref.read(authStateProvider.notifier).logout();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final int badgeCount;
  final VoidCallback onTap;
  final List<_SidebarSubItem>? subItems;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    this.subItems,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.subItems != null && widget.subItems!.isNotEmpty) {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: widget.isSelected || _isExpanded
                  ? AppTheme.primaryColor.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
                widget.onTap();
              },
              leading: Icon(
                widget.icon,
                color: widget.isSelected || _isExpanded
                    ? AppTheme.primaryColor
                    : Colors.grey[600],
                size: 20,
              ),
              title: Text(
                widget.title,
                style: TextStyle(
                  color: widget.isSelected || _isExpanded
                      ? AppTheme.primaryColor
                      : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: widget.isSelected || _isExpanded
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
              trailing: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: _isExpanded ? AppTheme.primaryColor : Colors.grey[400],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 8),
              child: Column(
                children: widget.subItems!.map((subItem) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      onTap: subItem.onTap,
                      leading: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              subItem.title,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: subItem.color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              subItem.count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? AppTheme.primaryColor.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          widget.icon,
          color: widget.isSelected ? AppTheme.primaryColor : Colors.grey[600],
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  color: widget.isSelected
                      ? AppTheme.primaryColor
                      : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (widget.badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        hoverColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: widget.onTap,
      ),
    );
  }
}

class _SidebarSubItem {
  final String title;
  final int count;
  final Color color;
  final VoidCallback? onTap;

  _SidebarSubItem({
    required this.title,
    required this.count,
    required this.color,
    this.onTap,
  });
}
