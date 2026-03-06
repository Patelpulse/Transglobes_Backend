import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/leaflet_map.dart';
import 'ride_tracking_screen.dart';

class BusBookingScreen extends StatefulWidget {
  const BusBookingScreen({super.key});

  @override
  State<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  final List<Map<String, dynamic>> _routes = [
    {
      'title': 'Route 402 - Downtown Exp',
      'departs': '08:30 AM',
      'seats': '12 seats left',
      'seatsColor': Colors.green,
      'isFastest': true,
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBuis_ZZy7LZ-ehsHot2z-UnIZvnhiVt-WRbt8yEuKLYnbh1A39Wqz75-wyyqfvl0qo6VjPBANt03nc6edHcy9Gxdgp7GjY4LnxlGvIyvvPO__7yCpGzG3eTxU0TwJs9RZqfB4hWI8f430B8XAvBwNbfX34ktmiU8tNs4HcTzMs548wvbrikmvj7bV8Gw5Rr5D4N74tHvrTs30DdmMYGRdqIxymXUCzPTpMObwPkwLL4iTW_828TL6kf9rwMhPMgUjvVRuNqRaBHLM',
    },
    {
      'title': 'Route 105 - Tech Park Hub',
      'departs': '09:15 AM',
      'seats': '4 seats left',
      'seatsColor': Colors.amber,
      'isFastest': false,
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDwS9oAdK9dkeQQi2qk740e07oLorjOaWG4WLCJdbXd2sOTddO4DAXW-lF6-16HZmqUuFUGAd0nofUEQcMq8IDrrkFqnIl5uFf4N0qHVat18oueQir1V4prNbwRffFI8WJ41qsWN_X-2jE4crRDZDEPX3WVBA5fiR4PsuGlGnjBjCjomvD_Q2X6HadgvepWzHMeiLYdczaTJS7RuFRAUIx5aoII--hURptVqF1HccWj_I9dnsDTPSPeTDBNaJLG-nh90PREUUY9RCA',
    },
    {
      'title': 'Route 88 - Waterfront Loop',
      'departs': '09:45 AM',
      'seats': '24 seats left',
      'seatsColor': Colors.green,
      'isFastest': false,
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBF-oB242LImlXjuHcx7Qm6wuFnKKgaGa5tphVhAftsYcfZjurOFF7FmFMDvHLXFRPkkMgxYERw_nETnA2RISjXQJN-6CCz3tMFWhtjH9uaInebTGCc8_Ckd6uS3H1YDGKhoHv2Bu4a_PaZbhuKyHzLALccmdAk24UGsw8JIlksBBLnteK6uiZRjg4v30QH3b5XlxrmOE3EOTP3543AsZZgytdlNKj7QRa6r3gCQR0HF-6ElpISeC91DNRUZxiZoeX5-zE1hDV3lYA',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: context.colors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Bus Routes",
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: context.colors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.theme.dividerColor.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const LeafletMap(location: null, markers: []),
                ),
              ),
            ),

            // Tabs / Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip("Morning", true),
                  const SizedBox(width: 8),
                  _buildFilterChip("Office", false),
                  const SizedBox(width: 8),
                  _buildFilterChip("Public", false),
                  const SizedBox(width: 8),
                  _buildFilterChip("Price", false),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Routes",
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Found 12 routes for your commute today",
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Route Cards
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _routes.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final route = _routes[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (route['isFastest'])
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.theme.primaryColor.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "FASTEST",
                                  style: TextStyle(
                                    color: context.theme.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              route['title'],
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: context.colors.textSecondary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Departs: ${route['departs']}",
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_seat,
                                  color: route['seatsColor'],
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  route['seats'],
                                  style: TextStyle(
                                    color: route['seatsColor'],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RideTrackingScreen(
                                      pickup: const {
                                        "address": "Bus Stop A",
                                        "lat": 19.0760,
                                        "lng": 72.8777,
                                      },
                                      dropoff: const {
                                        "address": "Downtown Terminal",
                                        "lat": 19.0800,
                                        "lng": 72.8800,
                                      },
                                      vehicle: {
                                        "name": route['title'],
                                        "type": "Bus",
                                      },
                                      rideId:
                                          "BUS-${DateTime.now().millisecondsSinceEpoch}",
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.confirmation_number,
                                size: 16,
                              ),
                              label: const Text("Book Seat"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: route['isFastest']
                                    ? context.theme.primaryColor
                                    : context.colors.button,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                minimumSize: const Size(100, 36),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: NetworkImage(route['image']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? context.theme.primaryColor
            : context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? context.theme.primaryColor
              : context.theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : context.colors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down,
            color: isSelected ? Colors.white : context.colors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
