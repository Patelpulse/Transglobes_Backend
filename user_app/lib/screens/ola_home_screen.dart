import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ride_service.dart';
import '../models/ride_type_model.dart';
import '../services/auth_service.dart';

class OlaHomeScreen extends ConsumerStatefulWidget {
  const OlaHomeScreen({super.key});

  @override
  ConsumerState<OlaHomeScreen> createState() => _OlaHomeScreenState();
}

class _OlaHomeScreenState extends ConsumerState<OlaHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _fromController = TextEditingController(
    text: "The Weekend Wine & More, 504, 1, Hazipur, Sector 104, Noida, U...",
  );
  final TextEditingController _toController = TextEditingController();
  String _selectedWhen = "Now";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _handleRideSelection(RideTypeModel rideType) async {
    final userId = ref.read(authServiceProvider).currentUser?.uid ?? "demo_user";
    
    final success = await ref.read(rideServiceProvider).createRideRequest(
      from: _fromController.text,
      to: _toController.text,
      when: _selectedWhen,
      rideTypeId: rideType.id,
      userId: userId,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? "Ride request for ${rideType.name} saved to database!" 
            : "Failed to save ride request"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rideTypesAsync = ref.watch(rideTypesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Icon(Icons.menu, color: Colors.black),
        title: Image.network(
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/Ola_Cabs_logo.svg/1200px-Ola_Cabs_logo.svg.png',
          height: 30,
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text("LOG IN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xffd4e157),
              indicatorWeight: 4,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: "DAILY RIDES"),
                Tab(text: "OUTSTATION"),
                Tab(text: "RENTALS"),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Input Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xfff5f5f5),
                    child: Column(
                      children: [
                        _buildLocationInput("FROM", _fromController, Icons.circle, Colors.green),
                        const SizedBox(height: 8),
                        _buildLocationInput("TO", _toController, Icons.square, Colors.red, hint: "Search for a locality or landmark"),
                        const SizedBox(height: 8),
                        _buildWhenDropdown(),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      "AVAILABLE RIDES",
                      style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),

                  // Ride List
                  rideTypesAsync.when(
                    data: (rides) => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rides.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, indent: 80),
                      itemBuilder: (context, index) {
                        final ride = rides[index];
                        return _buildRideItem(ride);
                      },
                    ),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (err, stack) => Center(child: Text("Error: $err")),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput(String label, TextEditingController controller, IconData icon, Color iconColor, {String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xffe0e0e0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhenDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffe0e0e0),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text("WHEN", style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const Text("Now", style: TextStyle(fontSize: 14, color: Colors.black)),
          const Spacer(),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildRideItem(RideTypeModel ride) {
    IconData getIcon(String name) {
      switch (name.toLowerCase()) {
        case 'auto': return Icons.electric_rickshaw;
        case 'bike': return Icons.two_wheeler;
        case 'mini': return Icons.directions_car;
        case 'sedan':
        case 'prime sedan': return Icons.directions_car_filled;
        case 'suv':
        case 'prime suv': return Icons.minor_crash;
        default: return Icons.directions_car;
      }
    }

    return ListTile(
      onTap: () => _handleRideSelection(ride),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(getIcon(ride.name), size: 30, color: Colors.black),
          if (ride.waitingTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(ride.waitingTime, style: const TextStyle(fontSize: 10, color: Colors.black)),
          ]
        ],
      ),
      title: Row(
        children: [
          Text(ride.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
        ],
      ),
      subtitle: Text(ride.description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    );
  }
}
