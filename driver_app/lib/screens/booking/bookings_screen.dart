import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:driver_app/core/theme.dart';
import 'package:driver_app/models/booking_model.dart';
import 'package:driver_app/providers/booking_provider.dart';
import 'package:driver_app/services/driver_service.dart';
import 'package:driver_app/screens/chat/chat_screen.dart';
import 'package:driver_app/screens/booking/booking_detail_screen.dart';
import 'package:driver_app/screens/booking/active_ride_screen.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  final String? filterVehicleType; // e.g., 'cab' or 'truck'
  const BookingsScreen({super.key, this.filterVehicleType});
  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: 1);
  }
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    var pending = ref.watch(pendingBookingsProvider);
    var active = ref.watch(activeBookingsProvider);
    var history = ref.watch(historyBookingsProvider);

    if (widget.filterVehicleType != null) {
      pending = pending.where((b) => b.vehicleType == widget.filterVehicleType).toList();
      active = active.where((b) => b.vehicleType == widget.filterVehicleType).toList();
      history = history.where((b) => b.vehicleType == widget.filterVehicleType).toList();
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        elevation: 0,
        title: const Text('Bookings', style: TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.neonGreen,
          unselectedLabelColor: AppTheme.darkTextSecondary,
          indicatorColor: AppTheme.neonGreen,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'Pending (${pending.length})'),
            Tab(text: 'Active (${active.length})'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          RefreshIndicator(
            onRefresh: () => ref.read(bookingProvider.notifier).fetchBookings(),
            color: AppTheme.neonGreen,
            child: _buildPendingList(pending),
          ),
          RefreshIndicator(
            onRefresh: () => ref.read(bookingProvider.notifier).fetchBookings(),
            color: AppTheme.neonGreen,
            child: _buildActiveList(active),
          ),
          RefreshIndicator(
            onRefresh: () => ref.read(bookingProvider.notifier).fetchBookings(),
            color: AppTheme.neonGreen,
            child: _buildHistoryList(history),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingList(List<BookingModel> bookings) {
    if (bookings.isEmpty) return _buildEmpty('No pending requests', Icons.inbox_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _PendingBookingCard(booking: bookings[i]),
    );
  }

  Widget _buildActiveList(List<BookingModel> bookings) {
    if (bookings.isEmpty) return _buildEmpty('No active trips', Icons.directions_car_outlined);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _ActiveBookingCard(booking: bookings[i]),
    );
  }

  Widget _buildHistoryList(List<BookingModel> bookings) {
    if (bookings.isEmpty) return _buildEmpty('No trip history yet', Icons.history);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (_, i) => _HistoryBookingCard(booking: bookings[i]),
    );
  }

  Widget _buildEmpty(String msg, IconData icon) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppTheme.darkDivider),
                const SizedBox(height: 12),
                Text(msg, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pending Booking Card ──
class _PendingBookingCard extends ConsumerStatefulWidget {
  final BookingModel booking;
  const _PendingBookingCard({required this.booking});
  @override
  ConsumerState<_PendingBookingCard> createState() => _PendingBookingCardState();
}

class _PendingBookingCardState extends ConsumerState<_PendingBookingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _slide = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingDetailScreen(bookingId: b.id))),
      child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.earningsAmber.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: AppTheme.earningsAmber.withValues(alpha: 0.08), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _TypeBadge(b.vehicleType, b.subType),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.earningsAmber.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('₹${b.fare.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.earningsAmber, fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RouteRow(b.pickupAddress, b.dropAddress),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _InfoChip(Icons.route, '${b.distanceKm} km'),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.access_time, '${b.etaMinutes} min'),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.person, b.userName),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.phone, b.userPhone),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref.read(bookingProvider.notifier).rejectBooking(b.id),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.offlineRed, side: BorderSide(color: AppTheme.offlineRed.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          final driverProfile = ref.read(driverProfileProvider).value;
                          if (driverProfile == null) return;

                          ref.read(bookingProvider.notifier).acceptBooking(b.id);
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                receiverId: b.userId ?? '',
                                receiverName: b.userName,
                                driverId: driverProfile.id,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle, size: 18), SizedBox(width: 8), Text('Accept', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))]),
                      ),
                    ),
                ],
              ),
            ],
        ),
      ),
    );
  }
}

// ── Active Booking Card ──
class _ActiveBookingCard extends ConsumerWidget {
  final BookingModel booking;
  const _ActiveBookingCard({required this.booking});

  final _statuses = const ['accepted', 'on_the_way', 'arrived', 'started', 'completed'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = booking;
    final statusIdx = _statuses.indexOf(b.status).clamp(0, 4);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.neonGreen.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: AppTheme.neonGreen.withValues(alpha: 0.08), blurRadius: 20)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeBadge(b.vehicleType, b.subType),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppTheme.neonGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(b.status), style: const TextStyle(color: AppTheme.neonGreen, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _RouteRow(b.pickupAddress, b.dropAddress),
          const SizedBox(height: 14),
          // Progress steps
          _buildProgressBar(statusIdx),
          const SizedBox(height: 14),
          // Action buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final driverProfile = ref.read(driverProfileProvider).value;
                        if (driverProfile == null) return;
            
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              receiverId: b.userId ?? '',
                              receiverName: b.userName,
                              driverId: driverProfile.id,
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.neonGreen, side: BorderSide(color: AppTheme.neonGreen.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: OutlinedButton.icon(
                      onPressed: () => _openMap(b),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.cabBlue, side: BorderSide(color: AppTheme.cabBlue.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      icon: const Icon(Icons.navigation, size: 18),
                      label: const Text('Nav', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 110,
                    child: ElevatedButton(
                      onPressed: () {
                        if (b.status == 'arrived') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveRideScreen(booking: b),
                            ),
                          );
                        } else {
                          _advanceStatus(ref, b);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
                      child: Text(_nextAction(b.status), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String s) {
    const m = {'accepted': 'Accepted', 'on_the_way': 'On the Way', 'arrived': 'Arrived', 'ongoing': 'In Progress'};
    return m[s] ?? s;
  }

  String _nextAction(String s) {
    const m = {'accepted': 'On Way', 'on_the_way': 'Arrived', 'arrived': 'Start Trip', 'ongoing': 'Complete'};
    return m[s] ?? 'Update';
  }

  void _openMap(BookingModel b) async {
    final lat = (b.status == 'ongoing') ? b.dropLat : b.pickupLat;
    final lng = (b.status == 'ongoing') ? b.dropLng : b.pickupLng;
    
    if (lat == null || lng == null) return;
    
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _advanceStatus(WidgetRef ref, BookingModel b) {
    const next = {'accepted': 'on_the_way', 'on_the_way': 'arrived', 'arrived': 'ongoing', 'ongoing': 'completed'};
    if (next.containsKey(b.status)) {
      ref.read(bookingProvider.notifier).updateStatus(b.id, next[b.status]!);
    }
  }

  Widget _buildProgressBar(int idx) {
    final labels = ['Accepted', 'On Way', 'Arrived', 'Started', 'Done'];
    return Row(
      children: List.generate(5, (i) {
        final done = i <= idx;
        return Expanded(
          child: Row(
            children: [
              Expanded(child: Container(height: 3, color: done ? AppTheme.neonGreen : AppTheme.darkDivider)),
              if (i < 4) const SizedBox(width: 0),
            ],
          ),
        );
      }),
    );
  }

  void _showDelaySheet(BuildContext context, WidgetRef ref, String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report Delay Reason', style: TextStyle(color: AppTheme.darkTextPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: ['Heavy Traffic', 'Vehicle Issue', 'Loading Delay', 'Breakdown', 'Weather', 'Road Block', 'Wrong Route', 'Other'].map((r) =>
                GestureDetector(
                  onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delay reported: $r'), backgroundColor: AppTheme.truckOrange, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))); },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppTheme.darkCard, borderRadius: BorderRadius.circular(25), border: Border.all(color: AppTheme.darkDivider)),
                    child: Text(r, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w500)),
                  ),
                )
              ).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ── History Booking Card ──
class _HistoryBookingCard extends StatelessWidget {
  final BookingModel booking;
  const _HistoryBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final isCompleted = b.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.darkDivider.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.neonGreen.withValues(alpha: 0.1) : AppTheme.offlineRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : Icons.cancel,
              color: isCompleted ? AppTheme.neonGreen : AppTheme.offlineRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(b.userName, style: const TextStyle(color: AppTheme.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isCompleted ? AppTheme.neonGreen : AppTheme.offlineRed).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b.status.toUpperCase(),
                        style: TextStyle(
                          color: isCompleted ? AppTheme.neonGreen : AppTheme.offlineRed,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${b.pickupAddress.split(',').first} → ${b.dropAddress.split(',').first}', style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(_formatTime(b.createdAt), style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${b.fare.toStringAsFixed(0)}', style: TextStyle(color: isCompleted ? AppTheme.earningsAmber : AppTheme.offlineRed, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 4),
              if (b.userRating != null)
                Row(children: [
                  const Icon(Icons.star, size: 12, color: AppTheme.earningsAmber),
                  const SizedBox(width: 2),
                  Text(b.userRating!.toString(), style: const TextStyle(color: AppTheme.earningsAmber, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Shared helper widgets ──
class _TypeBadge extends StatelessWidget {
  final String type;
  final String sub;
  const _TypeBadge(this.type, this.sub);

  @override
  Widget build(BuildContext context) {
    final color = type == 'cab' ? AppTheme.cabBlue : type == 'truck' ? AppTheme.truckOrange : AppTheme.busPurple;
    final icon = type == 'cab' ? Icons.local_taxi : type == 'truck' ? Icons.local_shipping : Icons.directions_bus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(sub, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String pickup, drop;
  const _RouteRow(this.pickup, this.drop);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppTheme.darkSurface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(children: [
            const Icon(Icons.trip_origin, color: AppTheme.neonGreen, size: 14),
            const SizedBox(width: 10),
            Expanded(child: Text(pickup, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 3, bottom: 3),
            child: Row(children: [Container(width: 2, height: 14, color: AppTheme.darkDivider)]),
          ),
          Row(children: [
            const Icon(Icons.location_on, color: AppTheme.offlineRed, size: 14),
            const SizedBox(width: 10),
            Expanded(child: Text(drop, style: const TextStyle(color: AppTheme.darkTextPrimary, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.darkSurface, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.darkTextSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.darkTextSecondary, fontSize: 11, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}
