import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import 'location_search_screen.dart';
import 'ride_booking_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'payments_screen.dart';
import 'offers_screen.dart';
import 'settings_screen.dart';
import 'support_screen.dart';
import 'about_screen.dart';
import 'logistics_booking_screen.dart';
import 'bus_booking_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      const HomeTab(),
      const ActivityTab(),
      const WalletScreen(),
      AccountTab(
        onTabChange: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    ];

    return Scaffold(
      drawer: _buildDrawer(context),
      body: tabs[_currentIndex],
      backgroundColor: context.theme.scaffoldBackgroundColor,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        height: 70,
        surfaceTintColor: Colors.transparent,
        indicatorColor: context.theme.primaryColor.withOpacity(0.1),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(Icons.home, color: context.theme.primaryColor),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.history_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.history,
              color: context.theme.primaryColor,
            ),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
              color: context.theme.primaryColor,
            ),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: context.colors.textSecondary,
            ),
            selectedIcon: Icon(
              Icons.settings,
              color: context.theme.primaryColor,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const Color transPurple = Color(0xFF8B7DBE);
    final userAsync = ref.watch(fullUserProfileProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Drawer Header
          DrawerHeader(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A1A1A), Color(0xFF2D2442)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: transPurple.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        userAsync.when(
                          data: (user) => Text(
                            user?.name ?? "User",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          loading: () => const Text("Loading...",
                              style: TextStyle(color: Colors.white70)),
                          error: (_, __) => const Text("User",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const Text(
                          "4.8 ★ Gold Member",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vehicle Modes (Services)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "OUR SERVICES",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          _drawerServiceItem(
            context,
            icon: Icons.directions_car_rounded,
            title: "Transglobe (Cabs)",
            subtitle: "Comfortable city rides",
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              // Already on home screen which shows Cabs by default
            },
          ),
          _drawerServiceItem(
            context,
            icon: Icons.local_shipping_rounded,
            title: "Logistics (Trucks)",
            subtitle: "Deliver heavy goods",
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LogisticsBookingScreen(),
                ),
              );
            },
          ),
          _drawerServiceItem(
            context,
            icon: Icons.directions_bus_rounded,
            title: "Shuttle (Buses)",
            subtitle: "Smart daily commute",
            color: Colors.purple,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusBookingScreen(),
                ),
              );
            },
          ),

          const Divider(height: 32),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerMenuItem(Icons.history, "My Trips", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                }),
                _drawerMenuItem(Icons.account_balance_wallet_outlined,
                    "Wallet", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                }),
                _drawerMenuItem(Icons.local_offer_outlined, "Offers", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const OffersScreen()),
                  );
                }),
                _drawerMenuItem(Icons.settings_outlined, "Settings", () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                }),
                _drawerMenuItem(Icons.help_outline, "Support", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SupportScreen()),
                  );
                }),
                const Divider(),
                _drawerMenuItem(Icons.logout, "Logout", () {
                  AuthService().signOut();
                }, isDestructive: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerServiceItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
  }

  Widget _drawerMenuItem(IconData icon, String title, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleWhereTo() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LocationSearchScreen(title: 'Where to?'),
      ),
    );

    if (result != null && result is Map && mounted) {
      final pickup =
          result['pickup'] ??
          {
            'name': 'Current Location',
            'address': 'Using GPS',
            'lat': 19.0760,
            'lng': 72.8777,
          };
      final dropoff = result['dropoff'] ?? result;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RideBookingScreen(
            pickup: pickup,
            dropoff: Map<String, dynamic>.from(dropoff),
            serviceType: 'cab',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color transPurple = Color(0xFF8B7DBE);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Menu button
                    Builder(
                      builder: (ctx) => GestureDetector(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.menu,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search Bar (Tappable)
                    Expanded(
                      child: GestureDetector(
                        onTap: _handleWhereTo,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.grey[500],
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  "Search location",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Pay Button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "Pay",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Headline
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Comfort In Every Mile",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 3. Hero Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A1A), Color(0xFF2D2442)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Car Image (Right aligned)
                      Positioned(
                        right: -10,
                        bottom: 0,
                        top: 0,
                        child: AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: Image.asset(
                            "assets/images/homescreen/hero_car.png",
                            width: 260,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Get Ready?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              "Then Let's go now.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _handleWhereTo,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: transPurple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Book Now",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 4. Top Services
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Top Services",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSquareServiceCard(
                      "assets/images/homescreen/service_ride.png",
                      "Transglobe",
                      _handleWhereTo,
                    ),
                    _buildSquareServiceCard(
                      "assets/images/homescreen/service_outstation.png",
                      "Logistics",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const LogisticsBookingScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSquareServiceCard(
                      "assets/images/homescreen/service_rental.png",
                      "Shuttle",
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BusBookingScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 5. Featured Features (Carousel)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Featured Features",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 160,
                child: PageView(
                  controller: PageController(viewportFraction: 0.85),
                  padEnds: false,
                  children: [
                    _buildCarouselCard(
                      "Safe Mobility",
                      "Verified drivers with emergency support",
                      Icons.shield_outlined,
                      const Color(0xFFE8F5E9),
                      const Color(0xFF2E7D32),
                    ),
                    _buildCarouselCard(
                      "Express Logistics",
                      "Real-time tracking for all deliveries",
                      Icons.local_shipping_outlined,
                      const Color(0xFFE3F2FD),
                      const Color(0xFF1976D2),
                    ),
                    _buildCarouselCard(
                      "Smart Shuttle",
                      "Zero-emission commuting for everyone",
                      Icons.eco_outlined,
                      const Color(0xFFFFF3E0),
                      const Color(0xFFE65100),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselCard(
    String title,
    String subtitle,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16, left: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: iconColor.withOpacity(0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareServiceCard(
    String imagePath,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 64) / 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Box
            Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5FF), // Soft blue-gray background
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 10),
            // Label Below Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> pastRides = [
    {
      'date': 'Today, 10:30 AM',
      'from': 'Oberoi Mall, Goregaon',
      'to': 'Mindspace, Malad',
      'price': '₹145.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Yesterday, 8:15 PM',
      'from': 'Phoenix Mall, Parel',
      'to': 'Bandra West',
      'price': '₹320.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Oct 24, 4:20 PM',
      'from': 'Gateway of India',
      'to': 'CST Station',
      'price': '₹45.00',
      'type': 'AUTO',
      'icon': Icons.electric_rickshaw,
      'color': Colors.amber,
    },
    {
      'date': 'Oct 23, 11:00 AM',
      'from': 'Versova Metro',
      'to': 'Juhu Circle',
      'price': '₹25.00',
      'type': 'BIKE',
      'icon': Icons.two_wheeler,
      'color': Colors.green,
    },
    {
      'date': 'Oct 22, 9:00 PM',
      'from': 'R-City Mall, Ghatkopar',
      'to': 'Powai Lake',
      'price': '₹190.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Oct 20, 2:30 PM',
      'from': 'Airport Terminal 1',
      'to': 'Andheri East',
      'price': '₹210.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Oct 18, 10:00 AM',
      'from': 'Link Road, Borivali',
      'to': 'Dahisar East',
      'price': '₹35.00',
      'type': 'AUTO',
      'icon': Icons.electric_rickshaw,
      'color': Colors.amber,
    },
    {
      'date': 'Oct 15, 6:45 PM',
      'from': 'Seawoods Grand Central',
      'to': 'Vashi Sector 17',
      'price': '₹120.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Oct 12, 8:00 AM',
      'from': 'Koramangala 5th Block',
      'to': 'Indiranagar',
      'price': '₹180.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Oct 08, 9:20 PM',
      'from': 'Hitec City',
      'to': 'Gachibowli',
      'price': '₹165.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
    {
      'date': 'Oct 05, 1:00 PM',
      'from': 'Jubilee Hills',
      'to': 'Banjara Hills',
      'price': '₹90.00',
      'type': 'AUTO',
      'icon': Icons.electric_rickshaw,
      'color': Colors.amber,
    },
    {
      'date': 'Oct 01, 7:30 AM',
      'from': 'DLF Cybercity',
      'to': 'Gurgaon Sector 29',
      'price': '₹250.00',
      'type': 'CAB',
      'icon': Icons.directions_car,
      'color': Colors.blue,
    },
  ];

  final List<Map<String, dynamic>> upcomingRides = [
    {
      'date': 'Tomorrow, 9:00 AM',
      'from': 'Willingdon Colony',
      'to': 'Airport T2',
      'price': 'Estimated ₹450',
      'type': 'RESERVE',
      'icon': Icons.event_available,
      'color': Colors.deepPurple,
    },
    {
      'date': 'Oct 28, 5:30 PM',
      'from': 'Office Park',
      'to': 'Home',
      'price': 'Estimated ₹180',
      'type': 'SCHEDULED',
      'icon': Icons.access_time_filled,
      'color': Colors.blue,
    },
    {
      'date': 'Nov 02, 10:00 AM',
      'from': 'Home',
      'to': 'Pune (Intercity)',
      'price': 'Estimated ₹2400',
      'type': 'INTERCITY',
      'icon': Icons.map,
      'color': Colors.deepOrange,
    },
    {
      'date': 'Nov 05, 7:00 PM',
      'from': 'Hotel Grand',
      'to': 'Railway Station',
      'price': 'Estimated ₹150',
      'type': 'SCHEDULED',
      'icon': Icons.access_time_filled,
      'color': Colors.blue,
    },
    {
      'date': 'Nov 12, 10:30 AM',
      'from': 'Residence',
      'to': 'Golf Club',
      'price': 'Estimated ₹220',
      'type': 'RESERVE',
      'icon': Icons.event_available,
      'color': Colors.deepPurple,
    },
  ];

  void _showRideDetails(Map<String, dynamic> ride, bool isUpcoming) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: context.theme.dividerColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride['type'],
                      style: TextStyle(
                        color: context.theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      ride['date'],
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (ride['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    ride['icon'] as IconData,
                    color: ride['color'] as Color,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildDetailRow(Icons.location_on_outlined, "From", ride['from']),
            const SizedBox(height: 24),
            _buildDetailRow(Icons.flag_outlined, "To", ride['to']),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Fare",
                  style: TextStyle(
                    fontSize: 16,
                    color: context.colors.textSecondary,
                  ),
                ),
                Text(
                  ride['price'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                if (isUpcoming) {
                  // Handle cancel logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Ride Cancelled Successfully"),
                    ),
                  );
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isUpcoming
                    ? Colors.red
                    : context.theme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                isUpcoming ? "Cancel Ride" : "Rebook Ride",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.theme.dividerColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: context.colors.textSecondary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Past"),
            Tab(text: "Upcoming"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRideList(pastRides, false),
          _buildRideList(upcomingRides, true),
        ],
      ),
    );
  }

  Widget _buildRideList(List<Map<String, dynamic>> rides, bool isUpcoming) {
    if (rides.isEmpty) {
      return const Center(child: Text("No activity found"));
    }
    return ListView.builder(
      itemCount: rides.length,
      itemBuilder: (context, index) {
        final ride = rides[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: ride['color'],
            child: Icon(ride['icon'], color: Colors.white),
          ),
          title: Text(ride['date']),
          subtitle: Text("${ride['from']} to ${ride['to']}"),
          trailing: Text(ride['price']),
          onTap: () => _showRideDetails(ride, isUpcoming),
        );
      },
    );
  }
}

class AccountTab extends ConsumerWidget {
  final Function(int)? onTabChange;
  const AccountTab({super.key, this.onTabChange});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final userPhone = user?.phoneNumber ?? "+91 98765 43210";

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Profile Header
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      userProfileAsync.when(
                        data: (userName) => Text(
                          userName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 28,
                          width: 28,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (err, stack) => Text(
                          user?.displayName ?? "Transglobal User",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.theme.primaryColor.withOpacity(
                                0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 14,
                                  color: context.theme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "4.8 Rating",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: context.theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            userPhone,
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    ),
                    child: Hero(
                      tag: 'profile_pic',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: context.theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.theme.primaryColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: context.theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile Completion Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.theme.primaryColor,
                      context.theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: context.theme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Profile Completion",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "85%",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 6,
                          width:
                              MediaQuery.of(context).size.width *
                              0.6, // 85% roughly
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Add your email to reach 100% and get ₹50 credit!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Rewards Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.forestGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.forestGreen.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Transglobal Rewards",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Platinum",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "You have earned 1,250 points this month!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.forestGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          "View Rewards",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Interactive Grid for Quick Actions
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                padding: EdgeInsets.zero,
                children: [
                  _buildGridItem(
                    context,
                    Icons.help_center_outlined,
                    "Help",
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    ),
                  ),
                  _buildGridItem(
                    context,
                    Icons.account_balance_wallet_outlined,
                    "Wallet",
                    () => onTabChange?.call(2),
                  ),
                  _buildGridItem(
                    context,
                    Icons.history_outlined,
                    "Activity",
                    () => onTabChange?.call(1),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Account Options
              _buildMenuSection(context, "Account Settings", [
                _buildMenuRow(
                  context,
                  Icons.person_outline,
                  "Personal Information",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  ),
                ),
                _buildMenuRow(
                  context,
                  Icons.payment_outlined,
                  "Payment Methods",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentsScreen(),
                    ),
                  ),
                ),
                _buildMenuRow(
                  context,
                  Icons.local_offer_outlined,
                  "Promos & Offers",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OffersScreen(),
                    ),
                  ),
                ),
              ]),

              const SizedBox(height: 24),

              // Safety Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: Colors.blue[800],
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Safety Center",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Manage your safety settings and emergency contacts.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[800]?.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.blue[800]),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Refer & Earn Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Refer & Earn",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Invite friends & earn up to ₹500",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.deepOrange.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Share",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _buildMenuSection(context, "More Info", [
                _buildMenuRow(
                  context,
                  Icons.settings_outlined,
                  "App Settings",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  ),
                ),
                _buildMenuRow(
                  context,
                  Icons.info_outline,
                  "About Transglobal",
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  ),
                ),
                _buildMenuRow(
                  context,
                  Icons.logout,
                  "Logout",
                  () => AuthService().signOut(),
                  isDestructive: true,
                ),
              ]),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  "v1.0.4 • Transglobal Mobility",
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.theme.dividerColor.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: context.colors.textPrimary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    List<Widget> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.colors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: context.theme.dividerColor.withOpacity(0.05),
            ),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuRow(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : context.colors.textPrimary,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : context.colors.textPrimary,
        ),
      ),
      trailing: isDestructive
          ? null
          : Icon(
              Icons.chevron_right,
              size: 18,
              color: context.colors.textSecondary,
            ),
    );
  }
}
