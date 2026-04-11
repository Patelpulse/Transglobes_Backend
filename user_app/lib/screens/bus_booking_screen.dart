import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../services/ride_service.dart';
import '../widgets/leaflet_map.dart';
import 'searching_ride_screen.dart';

class BusBookingScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? pickup;
  final Map<String, dynamic>? dropoff;

  const BusBookingScreen({
    super.key,
    this.pickup,
    this.dropoff,
  });

  @override
  ConsumerState<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends ConsumerState<BusBookingScreen> {
  final List<Map<String, dynamic>> _routes = [
    {
      'title': 'Route 402 - Downtown Exp',
      'departs': '08:30 AM',
      'seats': '12 seats left',
      'seatsColor': Colors.green,
      'isFastest': true,
      'fare': 120,
      'distance': 8.4,
      'pickup': {
        'title': 'Central Bus Terminal',
        'address': 'Central Bus Terminal, Sector 18',
        'lat': 19.0760,
        'lng': 72.8777,
      },
      'dropoff': {
        'title': 'Downtown Junction',
        'address': 'Downtown Junction, CBD',
        'lat': 19.0890,
        'lng': 72.8910,
      },
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBuis_ZZy7LZ-ehsHot2z-UnIZvnhiVt-WRbt8yEuKLYnbh1A39Wqz75-wyyqfvl0qo6VjPBANt03nc6edHcy9Gxdgp7GjY4LnxlGvIyvvPO__7yCpGzG3eTxU0TwJs9RZqfB4hWI8f430B8XAvBwNbfX34ktmiU8tNs4HcTzMs548wvbrikmvj7bV8Gw5Rr5D4N74tHvrTs30DdmMYGRdqIxymXUCzPTpMObwPkwLL4iTW_828TL6kf9rwMhPMgUjvVRuNqRaBHLM',
    },
    {
      'title': 'Route 105 - Tech Park Hub',
      'departs': '09:15 AM',
      'seats': '4 seats left',
      'seatsColor': Colors.amber,
      'isFastest': false,
      'fare': 150,
      'distance': 11.2,
      'pickup': {
        'title': 'North Gate Stop',
        'address': 'North Gate Stop, Tech Corridor',
        'lat': 19.1050,
        'lng': 72.8650,
      },
      'dropoff': {
        'title': 'Tech Park Hub',
        'address': 'Tech Park Hub, Main Entrance',
        'lat': 19.1200,
        'lng': 72.8770,
      },
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDwS9oAdK9dkeQQi2qk740e07oLorjOaWG4WLCJdbXd2sOTddO4DAXW-lF6-16HZmqUuFUGAd0nofUEQcMq8IDrrkFqnIl5uFf4N0qHVat18oueQir1V4prNbwRffFI8WJ41qsWN_X-2jE4crRDZDEPX3WVBA5fiR4PsuGlGnjBjCjomvD_Q2X6HadgvepWzHMeiLYdczaTJS7RuFRAUIx5aoII--hURptVqF1HccWj_I9dnsDTPSPeTDBNaJLG-nh90PREUUY9RCA',
    },
    {
      'title': 'Route 88 - Waterfront Loop',
      'departs': '09:45 AM',
      'seats': '24 seats left',
      'seatsColor': Colors.green,
      'isFastest': false,
      'fare': 95,
      'distance': 6.8,
      'pickup': {
        'title': 'Harbor Pickup Point',
        'address': 'Harbor Pickup Point, Waterfront',
        'lat': 19.0000,
        'lng': 72.8400,
      },
      'dropoff': {
        'title': 'Waterfront Loop',
        'address': 'Waterfront Loop, Main Gate',
        'lat': 19.0200,
        'lng': 72.8700,
      },
      'image':
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBF-oB242LImlXjuHcx7Qm6wuFnKKgaGa5tphVhAftsYcfZjurOFF7FmFMDvHLXFRPkkMgxYERw_nETnA2RISjXQJN-6CCz3tMFWhtjH9uaInebTGCc8_Ckd6uS3H1YDGKhoHv2Bu4a_PaZbhuKyHzLALccmdAk24UGsw8JIlksBBLnteK6uiZRjg4v30QH3b5XlxrmOE3EOTP3543AsZZgytdlNKj7QRa6r3gCQR0HF-6ElpISeC91DNRUZxiZoeX5-zE1hDV3lYA',
    },
  ];

  bool _isBooking = false;
  int? _bookingRouteIndex;

  Map<String, dynamic> _resolveLocation(
    Map<String, dynamic>? preferred,
    Map<String, dynamic> fallback,
  ) {
    final resolved = Map<String, dynamic>.from(fallback);
    if (preferred != null) {
      resolved.addAll(preferred);
    }
    return resolved;
  }

  Future<void> _bookRoute(int index) async {
    if (_isBooking) return;

    final route = _routes[index];
    final fare = (route['fare'] as num).toDouble();
    final distance = (route['distance'] as num).toDouble();
    final pickup = _resolveLocation(widget.pickup, route['pickup'] as Map<String, dynamic>);
    final dropoff = _resolveLocation(widget.dropoff, route['dropoff'] as Map<String, dynamic>);

    setState(() {
      _isBooking = true;
      _bookingRouteIndex = index;
    });

    try {
      final ride = await ref.read(rideServiceProvider).createRideRequest(
        locations: {
          'pickup': pickup,
          'dropoff': dropoff,
        },
        rideMode: 'bus',
        fare: fare,
        distance: '${distance.toStringAsFixed(1)} km',
        paymentMode: 'cash',
        vehicleType: 'bus',
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchingRideScreen(
            pickup: pickup,
            dropoff: dropoff,
            distance: '${distance.toStringAsFixed(1)} km',
            rideMode: route['title'].toString(),
            price: '₹${fare.toStringAsFixed(0)}',
            otp: ride.otp,
            rideId: ride.id,
            vehicle: {
              'name': route['title'],
              'type': 'Bus',
              'price': fare,
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book shuttle: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
          _bookingRouteIndex = null;
        });
      }
    }
  }

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
          'Bus Routes',
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.theme.dividerColor.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip('Morning', true),
                  const SizedBox(width: 8),
                  _buildFilterChip('Office', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Public', false),
                  const SizedBox(width: 8),
                  _buildFilterChip('Price', false),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Routes',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Found 12 routes for your commute today',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _routes.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final route = _routes[index];
                final isActiveBooking = _isBooking && _bookingRouteIndex == index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: context.theme.dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (route['isFastest'] == true)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'FASTEST',
                                  style: TextStyle(
                                    color: context.theme.primaryColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              route['title'].toString(),
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
                                  'Departs: ${route['departs']}',
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
                                  color: route['seatsColor'] as Color,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  route['seats'].toString(),
                                  style: TextStyle(
                                    color: route['seatsColor'] as Color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _isBooking ? null : () => _bookRoute(index),
                              icon: isActiveBooking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.confirmation_number,
                                      size: 16,
                                    ),
                              label: Text(isActiveBooking ? 'Booking...' : 'Book Seat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: route['isFastest'] == true
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
                            image: NetworkImage(route['image'].toString()),
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
        color: isSelected ? context.theme.primaryColor : context.theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? context.theme.primaryColor
              : context.theme.dividerColor.withValues(alpha: 0.1),
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
