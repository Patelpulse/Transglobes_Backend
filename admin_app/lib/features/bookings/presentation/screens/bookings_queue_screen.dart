import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../drivers/domain/models/driver_model.dart';
import '../../../drivers/presentation/providers/driver_provider.dart';

final pendingRideRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('ride/rides/pending');

  if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
    final body = Map<String, dynamic>.from(response.data as Map);
    if (body['success'] == true && body['data'] is List) {
      return (body['data'] as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
  }

  return <Map<String, dynamic>>[];
});

class BookingsQueueScreen extends ConsumerWidget {
  const BookingsQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(pendingRideRequestsProvider);
    final rides = ridesAsync.value ?? const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        title: const Text(
          'Ride Queue',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(pendingRideRequestsProvider),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: ridesAsync.when(
        data: (rides) => rides.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(pendingRideRequestsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: rides.length,
                  itemBuilder: (context, index) => _RideQueueCard(ride: rides[index]),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load ride queue',
                style: TextStyle(color: Colors.grey[300]),
              ),
              const SizedBox(height: 8),
              Text(
                err.toString(),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(pendingRideRequestsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey[500], size: 56),
          const SizedBox(height: 16),
          const Text(
            'No pending ride requests',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'New bookings will appear here before drivers receive them.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RideQueueCard extends StatelessWidget {
  final Map<String, dynamic> ride;

  const _RideQueueCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final createdAt = DateTime.tryParse(ride['createdAt']?.toString() ?? '') ?? DateTime.now();
    final rideId = _stringValue(ride['rideId'] ?? ride['id'] ?? ride['_id']);
    final fare = _doubleValue(ride['fare']);
    final distance = ride['distance']?.toString().trim() ?? '';
    final rideMode = ride['rideMode']?.toString().trim().isNotEmpty == true
        ? ride['rideMode'].toString()
        : 'Ride';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'REQUEST #${rideId.isEmpty ? 'NEW' : rideId.substring(rideId.length > 6 ? rideId.length - 6 : 0).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              _badge('PENDING', const Color(0xFFFBBF24)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _stringValue(ride['userName'], 'Customer'),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _stringValue(ride['phone']),
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
          const SizedBox(height: 14),
          _routeRow(
            Icons.trip_origin,
            _stringValue(ride['pick'], 'Pickup'),
            Icons.location_on_outlined,
            _stringValue(ride['drop'], 'Dropoff'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(Icons.directions_car_outlined, rideMode),
              if (distance.isNotEmpty) _chip(Icons.route_outlined, distance),
              _chip(Icons.payments_outlined, '₹${fare.toStringAsFixed(0)}'),
              _chip(Icons.schedule_outlined, DateFormat('MMM dd, hh:mm a').format(createdAt)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAssignDialog(context),
              icon: const Icon(Icons.how_to_reg_outlined, size: 18),
              label: const Text(
                'ASSIGN DRIVER',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _routeRow(IconData startIcon, String start, IconData endIcon, String end) {
    return Row(
      children: [
        Column(
          children: [
            Icon(startIcon, color: Colors.greenAccent.shade400, size: 16),
            const SizedBox(height: 8),
            Container(width: 1, height: 24, color: AppTheme.borderDark),
            const SizedBox(height: 8),
            Icon(endIcon, color: Colors.redAccent.shade100, size: 16),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                start,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              Text(
                end,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAssignDialog(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColorDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Consumer(
              builder: (context, ref, _) {
                final driversAsync = ref.watch(driversProvider);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Assign Driver',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select an available driver for this ride request.',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: driversAsync.when(
                          data: (drivers) {
                            if (drivers.isEmpty) {
                              return const Center(
                                child: Text('No drivers found', style: TextStyle(color: Colors.white70)),
                              );
                            }

                            final sortedDrivers = [...drivers]
                              ..sort((a, b) {
                                final onlineA = (a.isOnline ?? false) ? 1 : 0;
                                final onlineB = (b.isOnline ?? false) ? 1 : 0;
                                return onlineB.compareTo(onlineA);
                              });

                            return ListView.separated(
                              controller: scrollController,
                              itemCount: sortedDrivers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final driver = sortedDrivers[index];
                                return _DriverTile(
                                  driver: driver,
                                  onAssign: () async {
                                    Navigator.pop(sheetContext);
                                    await _assignDriver(context, ref, driver);
                                  },
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, _) => Center(
                            child: Text(
                              'Failed to load drivers: $err',
                              style: const TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _assignDriver(BuildContext context, WidgetRef ref, Driver driver) async {
    try {
      final dio = ref.read(dioProvider);
      final rideId = _stringValue(ride['rideId'] ?? ride['id'] ?? ride['_id']);
      final response = await dio.put(
        'ride/rides/$rideId/assign',
        data: {
          'driverId': driver.id,
        },
      );

      if (response.statusCode == 200) {
        ref.invalidate(pendingRideRequestsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assigned to ${driver.name}'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
      } else {
        throw Exception('Unexpected status ${response.statusCode}');
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String message = e.message ?? 'Failed to assign driver';
      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign driver: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _stringValue(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class _DriverTile extends StatelessWidget {
  final Driver driver;
  final VoidCallback onAssign;

  const _DriverTile({
    required this.driver,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = driver.isOnline ?? false;
    final statusColor = isOnline ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.12),
          child: Text(
            driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          driver.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            driver.vehicleInfo ?? 'Driver',
            driver.mobileNumber ?? '',
            isOnline ? 'Online' : 'Offline',
          ].where((item) => item.trim().isNotEmpty).join(' • '),
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: ElevatedButton(
          onPressed: onAssign,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Assign'),
        ),
      ),
    );
  }
}
