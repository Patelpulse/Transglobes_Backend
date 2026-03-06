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
    if (location.startsWith('/users')) return 1;
    if (location.startsWith('/drivers')) return 2;
    if (location.startsWith('/finance')) return 3;
    if (location.startsWith('/alerts')) return 4;
    if (location.startsWith('/settings')) return 5;
    return 0; // Fleet / Dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/users');
        break;
      case 2:
        context.go('/drivers');
        break;
      case 3:
        context.go('/finance');
        break;
      case 4:
        context.go('/alerts');
        break;
      case 5:
        context.go('/settings');
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
                  color: AppTheme.backgroundColorDark,
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
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColorDark,
        border: Border(right: BorderSide(color: AppTheme.borderDark, width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 70,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text(
              'TRANSGLOBE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarItem(
                  icon: Icons.directions_car,
                  title: 'Fleet & Analytics',
                  isSelected: currentIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),
                _SidebarItem(
                  icon: Icons.people,
                  title: 'Users Management',
                  isSelected: currentIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),
                _SidebarItem(
                  icon: Icons.assignment_ind,
                  title: 'Drivers Management',
                  isSelected: currentIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),
                _SidebarItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Finance & Pricing',
                  isSelected: currentIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
                _SidebarItem(
                  icon: Icons.notifications,
                  title: 'Alerts & Support',
                  isSelected: currentIndex == 4,
                  badgeCount: unreadCount,
                  onTap: () => _onItemTapped(4, context),
                ),
                _SidebarItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  isSelected: currentIndex == 5,
                  onTap: () => _onItemTapped(5, context),
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final int badgeCount; // Added badgeCount
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0, // Default value for badgeCount
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textMutedLight,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textPrimaryLight,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount.toString(),
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
        onTap: onTap,
      ),
    );
  }
}
