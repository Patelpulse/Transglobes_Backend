import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../vehicles/domain/models/logistics_booking.dart';
import '../../../vehicles/presentation/providers/logistics_booking_provider.dart';
import '../../../drivers/presentation/providers/driver_provider.dart';

// ─── Supervisor Dashboard Screen ─────────────────────────────────────────────
class SupervisorScreen extends ConsumerStatefulWidget {
  const SupervisorScreen({super.key});

  @override
  ConsumerState<SupervisorScreen> createState() => _SupervisorScreenState();
}

class _SupervisorScreenState extends ConsumerState<SupervisorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Supervisor Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(logisticsBookingsProvider);
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'PENDING', icon: Icon(Icons.pending_actions, size: 16)),
            Tab(text: 'ACTIVE', icon: Icon(Icons.local_shipping, size: 16)),
            Tab(text: 'STATS', icon: Icon(Icons.bar_chart, size: 16)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _BookingsList(status: LogisticsBookingStatus.pending),
          _BookingsList(status: LogisticsBookingStatus.processing),
          const _SupervisorStats(),
        ],
      ),
    );
  }
}

// ─── Filtered bookings list ───────────────────────────────────────────────────
class _BookingsList extends ConsumerWidget {
  final LogisticsBookingStatus status;
  const _BookingsList({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(filteredLogisticsBookingsProvider(status));

    return bookingsAsync.when(
      data: (bookings) => bookings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      color: Colors.white30, size: 64),
                  const SizedBox(height: 16),
                  Text('No ${status.name} bookings',
                      style: const TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(logisticsBookingsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: bookings.length,
                itemBuilder: (context, i) =>
                    _SupervisorBookingCard(booking: bookings[i]),
              ),
            ),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: Colors.white54)),
      ),
    );
  }
}

// ─── Supervisor booking card ──────────────────────────────────────────────────
class _SupervisorBookingCard extends StatelessWidget {
  final LogisticsBooking booking;
  const _SupervisorBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM, hh:mm a').format(booking.createdAt);
    final statusColor = booking.status == LogisticsBookingStatus.pending
        ? Colors.orange
        : booking.status == LogisticsBookingStatus.processing
            ? Colors.blue
            : Colors.green;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SupervisorBookingDetailScreen(booking: booking),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                    booking.userName.toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    booking.status.name.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoRow(Icons.location_on_outlined, 'PICKUP', booking.pickupName,
                const Color(0xFF4ADE80)),
            const SizedBox(height: 6),
            _infoRow(Icons.flag_outlined, 'DROP', booking.dropName,
                const Color(0xFFF43F5E)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pill(booking.modeOfTravel, Icons.directions_boat),
                Text('₹${booking.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                Text(dateStr,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
              ],
            ),
            if (booking.segments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${booking.segments.length} segment(s) defined',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SupervisorBookingDetailScreen(booking: booking),
                  ),
                ),
                icon: const Icon(Icons.edit_road, size: 16),
                label: const Text('MANAGE BOOKING',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(value,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Supervisor Stats Widget ──────────────────────────────────────────────────
class _SupervisorStats extends ConsumerWidget {
  const _SupervisorStats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(logisticsBookingsProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (e, s) => const Center(
          child: Text('Could not load stats', style: TextStyle(color: Colors.white54))),
      data: (all) {
        final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
        final data = {
          'pending': all.where((b) => b.status == LogisticsBookingStatus.pending).length,
          'confirmed': all.where((b) => b.status == LogisticsBookingStatus.processing).length,
          'inTransit': all.where((b) => b.status == LogisticsBookingStatus.inTransit).length,
          'delivered': all.where((b) => b.status == LogisticsBookingStatus.completed).length,
          'cancelled': all.where((b) => b.status == LogisticsBookingStatus.cancelled).length,
          'totalActive': all.where((b) => [
            LogisticsBookingStatus.pending,
            LogisticsBookingStatus.processing,
            LogisticsBookingStatus.inTransit,
          ].contains(b.status)).length,
          'last30DaysRevenue': all
              .where((b) => b.status == LogisticsBookingStatus.completed && b.createdAt.isAfter(thirtyDaysAgo))
              .fold<double>(0, (sum, b) => sum + b.price),
        };
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _statCard('Pending',
                      data['pending'].toString(), Colors.orange,
                      Icons.pending_actions),
                  _statCard('Confirmed',
                      data['confirmed'].toString(), Colors.blue,
                      Icons.check_circle_outline),
                  _statCard('In Transit',
                      data['inTransit'].toString(), Colors.purple,
                      Icons.local_shipping),
                  _statCard('Delivered',
                      data['delivered'].toString(), Colors.green,
                      Icons.done_all),
                  _statCard('Cancelled',
                      data['cancelled'].toString(), Colors.red,
                      Icons.cancel_outlined),
                  _statCard('Active Orders',
                      data['totalActive'].toString(),
                      AppTheme.primaryColor, Icons.timelapse),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColorDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_rupee,
                        color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('30-Day Revenue',
                            style: TextStyle(
                                color: Colors.white54, fontSize: 12)),
                        Text(
                          '₹${NumberFormat('#,##,###').format(data['last30DaysRevenue'] ?? 0)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }
}

// ─── Supervisor Booking Detail Screen ────────────────────────────────────────
class SupervisorBookingDetailScreen extends ConsumerStatefulWidget {
  final LogisticsBooking booking;
  const SupervisorBookingDetailScreen({super.key, required this.booking});

  @override
  ConsumerState<SupervisorBookingDetailScreen> createState() =>
      _SupervisorBookingDetailState();
}

class _SupervisorBookingDetailState
    extends ConsumerState<SupervisorBookingDetailScreen> {
  static String get _fallbackApiBase =>
      kIsWeb
          ? '${Uri.base.origin}/api'
          : 'https://transglobesbackend-production.up.railway.app/api';
  late LogisticsBooking _booking;
  bool _saving = false;

  // Segment editor state
  final List<Map<String, dynamic>> _segments = [];

  // Pricing override controllers
  final _vehiclePriceCtrl = TextEditingController();
  final _helperCostCtrl = TextEditingController();
  final _tollCtrl = TextEditingController();
  final _nightCtrl = TextEditingController();
  final _handlingCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();

  // Goods editor
  int _helperCount = 0;
  String _vehicleType = 'Road';

  static const _modes = ['Road', 'Train', 'Flight', 'Sea Cargo'];

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
    _helperCount = _booking.helperCount;
    _vehicleType = _booking.modeOfTravel.isNotEmpty ? _booking.modeOfTravel : 'Road';

    // Populate pricing
    _vehiclePriceCtrl.text = _booking.vehiclePrice.toStringAsFixed(0);
    _helperCostCtrl.text = _booking.helperCost.toStringAsFixed(0);
    _tollCtrl.text = '0';
    _nightCtrl.text = '0';
    _handlingCtrl.text = _booking.additionalCharges.toStringAsFixed(0);
    _discountCtrl.text = _booking.discountAmount.toStringAsFixed(0);

    // Load existing segments
    for (final seg in _booking.segments) {
      _segments.add({
        'id': seg.id,
        'fromCtrl': TextEditingController(text: seg.start['address'] ?? ''),
        'toCtrl': TextEditingController(text: seg.end['address'] ?? ''),
        'mode': seg.mode,
        'transportNameCtrl': TextEditingController(text: seg.transportName ?? ''),
        'transportNumberCtrl': TextEditingController(text: seg.transportNumber ?? ''),
        'priceCtrl': TextEditingController(text: seg.price.toStringAsFixed(0)),
        'dateCtrl': TextEditingController(text: seg.estimatedDate ?? ''),
        'timeCtrl': TextEditingController(text: seg.estimatedTime ?? ''),
      });
    }
  }

  @override
  void dispose() {
    _vehiclePriceCtrl.dispose();
    _helperCostCtrl.dispose();
    _tollCtrl.dispose();
    _nightCtrl.dispose();
    _handlingCtrl.dispose();
    _discountCtrl.dispose();
    for (final s in _segments) {
      (s['fromCtrl'] as TextEditingController).dispose();
      (s['toCtrl'] as TextEditingController).dispose();
      (s['transportNameCtrl'] as TextEditingController).dispose();
      (s['transportNumberCtrl'] as TextEditingController).dispose();
      (s['priceCtrl'] as TextEditingController).dispose();
      (s['dateCtrl'] as TextEditingController).dispose();
      (s['timeCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _addSegment() {
    setState(() {
      _segments.add({
        'id': '',
        'fromCtrl': TextEditingController(),
        'toCtrl': TextEditingController(),
        'mode': 'Road',
        'transportNameCtrl': TextEditingController(),
        'transportNumberCtrl': TextEditingController(),
        'priceCtrl': TextEditingController(text: '0'),
        'dateCtrl': TextEditingController(),
        'timeCtrl': TextEditingController(),
      });
    });
  }

  void _removeSegment(int index) {
    setState(() {
      final seg = _segments.removeAt(index);
      (seg['fromCtrl'] as TextEditingController).dispose();
      (seg['toCtrl'] as TextEditingController).dispose();
      (seg['transportNameCtrl'] as TextEditingController).dispose();
      (seg['transportNumberCtrl'] as TextEditingController).dispose();
      (seg['priceCtrl'] as TextEditingController).dispose();
      (seg['dateCtrl'] as TextEditingController).dispose();
      (seg['timeCtrl'] as TextEditingController).dispose();
    });
  }

  bool _isNotFound(DioException error) => error.response?.statusCode == 404;

  String _formatApiError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final data = error.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (status == 404) {
        return 'Requested save endpoint was not found on the server.';
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }

  void _updateLocalBooking({
    String? modeOfTravel,
    int? helperCount,
    double? helperCost,
    double? vehiclePrice,
    double? additionalCharges,
    double? discountAmount,
    double? totalPrice,
    LogisticsBookingStatus? status,
  }) {
    _booking = LogisticsBooking(
      id: _booking.id,
      userId: _booking.userId,
      userName: _booking.userName,
      userPhone: _booking.userPhone,
      pickupName: _booking.pickupName,
      dropName: _booking.dropName,
      modeOfTravel: modeOfTravel ?? _booking.modeOfTravel,
      price: totalPrice ?? _booking.price,
      status: status ?? _booking.status,
      createdAt: _booking.createdAt,
      distanceKm: _booking.distanceKm,
      vehiclePrice: vehiclePrice ?? _booking.vehiclePrice,
      helperCost: helperCost ?? _booking.helperCost,
      additionalCharges: additionalCharges ?? _booking.additionalCharges,
      discountAmount: discountAmount ?? _booking.discountAmount,
      helperCount: helperCount ?? _booking.helperCount,
      items: _booking.items,
      pickupAddressDetails: _booking.pickupAddressDetails,
      receivedAddressDetails: _booking.receivedAddressDetails,
      railwayStation: _booking.railwayStation,
      transportName: _booking.transportName,
      transportNumber: _booking.transportNumber,
      estimatedTime: _booking.estimatedTime,
      estimatedDate: _booking.estimatedDate,
      segments: _booking.segments,
    );
  }

  Future<Response<dynamic>> _patchWithFallback(
    Dio dio,
    List<String> paths, {
    Map<String, dynamic>? data,
  }) async {
    DioException? lastError;
    for (final path in paths) {
      try {
        return await dio.patch(
          path,
          data: data,
          options: path.startsWith('http')
              ? Options(headers: const {'X-Admin-Fallback-Auth': '1'})
              : null,
        );
      } on DioException catch (error) {
        lastError = error;
        if (!_isNotFound(error)) rethrow;
      }
    }
    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: paths.join(' | ')),
          message: 'All fallback PATCH endpoints failed.',
        );
  }

  Future<Response<dynamic>> _postWithFallback(
    Dio dio,
    List<String> paths, {
    Map<String, dynamic>? data,
  }) async {
    DioException? lastError;
    for (final path in paths) {
      try {
        return await dio.post(
          path,
          data: data,
          options: path.startsWith('http')
              ? Options(headers: const {'X-Admin-Fallback-Auth': '1'})
              : null,
        );
      } on DioException catch (error) {
        lastError = error;
        if (!_isNotFound(error)) rethrow;
      }
    }
    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: paths.join(' | ')),
          message: 'All fallback POST endpoints failed.',
        );
  }

  Future<void> _saveRoadmap() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final segmentsData = _segments.map((s) => {
        'start': {'address': (s['fromCtrl'] as TextEditingController).text},
        'end': {'address': (s['toCtrl'] as TextEditingController).text},
        'mode': s['mode'],
        'transportName': (s['transportNameCtrl'] as TextEditingController).text,
        'transportNumber': (s['transportNumberCtrl'] as TextEditingController).text,
        'price': double.tryParse((s['priceCtrl'] as TextEditingController).text) ?? 0,
        'estimatedDate': (s['dateCtrl'] as TextEditingController).text,
        'estimatedTime': (s['timeCtrl'] as TextEditingController).text,
        'status': 'pending',
      }).toList();

      final response = await _patchWithFallback(
        dio,
        [
          'logistics-bookings/${_booking.id}/roadmap',
          'logistics-booking/${_booking.id}/roadmap',
          'admin/supervisor/bookings/${_booking.id}/roadmap',
          '$_fallbackApiBase/logistics-bookings/${_booking.id}/roadmap',
        ],
        data: {'segments': segmentsData},
      );

      if (response.data['success'] == true) {
        ref.invalidate(logisticsBookingsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Roadmap saved!'),
                backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_formatApiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _savePricingOverride() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final toll = double.tryParse(_tollCtrl.text) ?? 0;
      final night = double.tryParse(_nightCtrl.text) ?? 0;
      final handling = double.tryParse(_handlingCtrl.text) ?? 0;
      final vehicleP = double.tryParse(_vehiclePriceCtrl.text) ?? 0;
      final helperC = double.tryParse(_helperCostCtrl.text) ?? 0;
      final discount = double.tryParse(_discountCtrl.text) ?? 0;
      final total = vehicleP + helperC + toll + night + handling - discount;

      final payload = {
        'vehiclePrice': vehicleP,
        'helperCost': helperC,
        'additionalCharges': toll + night + handling,
        'discountAmount': discount,
        'totalPrice': total,
        'tollCharges': toll,
        'nightCharges': night,
        'handlingCharges': handling,
      };

      await _patchWithFallback(
        dio,
        [
          'logistics-bookings/${_booking.id}/billing',
          'logistics-booking/${_booking.id}/billing',
          'admin/supervisor/bookings/${_booking.id}/pricing-override',
          '$_fallbackApiBase/logistics-bookings/${_booking.id}/billing',
          '$_fallbackApiBase/admin/supervisor/bookings/${_booking.id}/pricing-override',
        ],
        data: payload,
      );

      _updateLocalBooking(
        vehiclePrice: vehicleP,
        helperCost: helperC,
        additionalCharges: toll + night + handling,
        discountAmount: discount,
        totalPrice: total,
      );
      ref.invalidate(logisticsBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pricing updated!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_formatApiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveGoodsDetails() async {
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      const helperRate = 800.0;
      final helperCost = _helperCount * helperRate;

      await _patchWithFallback(
        dio,
        [
          'admin/supervisor/bookings/${_booking.id}/goods',
          'logistics-bookings/${_booking.id}/billing',
          'logistics-booking/${_booking.id}/billing',
          '$_fallbackApiBase/admin/supervisor/bookings/${_booking.id}/goods',
          '$_fallbackApiBase/logistics-bookings/${_booking.id}/billing',
        ],
        data: {
          'items': _booking.items,
          'helperCount': _helperCount,
          'vehicleType': _vehicleType,
          'helperCost': helperCost,
        },
      );

      _helperCostCtrl.text = helperCost.toStringAsFixed(0);
      _updateLocalBooking(
        helperCount: _helperCount,
        helperCost: helperCost,
        modeOfTravel: _vehicleType,
      );
      ref.invalidate(logisticsBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Goods details saved!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_formatApiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _approveBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColorDark,
        title: const Text('Approve Booking',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Confirm this booking and notify the customer?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green),
              child: const Text('Approve')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);

      await _patchWithFallback(
        dio,
        [
          'logistics-bookings/${_booking.id}/status',
          'admin/supervisor/bookings/${_booking.id}/approve',
          '$_fallbackApiBase/logistics-bookings/${_booking.id}/status',
          '$_fallbackApiBase/admin/supervisor/bookings/${_booking.id}/approve',
        ],
        data: {'status': 'confirmed', 'adminOverride': true},
      );

      _updateLocalBooking(status: LogisticsBookingStatus.processing);
      ref.invalidate(logisticsBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Booking approved!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_formatApiError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignDriverToSegment(int segIndex) async {
    final driversAsync = ref.read(driversProvider);
    driversAsync.when(
      data: (drivers) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceColorDark,
            title: const Text('Assign Driver to Segment',
                style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: drivers.length,
                itemBuilder: (_, i) {
                  final d = drivers[i];
                  final isOnline = d.isOnline ?? false;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isOnline ? Colors.green : Colors.grey,
                      child: Text(d.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(d.name,
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                        '${d.mobileNumber ?? ''} · ${isOnline ? "Online" : "Offline"}',
                        style: const TextStyle(color: Colors.white54)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final seg = _segments[segIndex];
                      final segId = seg['id'] as String;
                      if (segId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Save roadmap first to assign drivers to segments.')),
                        );
                        return;
                      }
                      try {
                        final dio = ref.read(dioProvider);
                        await _postWithFallback(
                          dio,
                          [
                            'logistics-bookings/${_booking.id}/segment/$segId/assign',
                            'logistics-booking/${_booking.id}/segment/$segId/assign',
                            '$_fallbackApiBase/logistics-bookings/${_booking.id}/segment/$segId/assign',
                          ],
                          data: {'driverId': d.id},
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${d.name} assigned to segment ${segIndex + 1}'),
                                backgroundColor: Colors.green),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: ${_formatApiError(e)}'),
                                backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () {},
      error: (e, _) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Manage: ${_booking.userName}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (_booking.status == LogisticsBookingStatus.pending)
            TextButton.icon(
              onPressed: _saving ? null : _approveBooking,
              icon: const Icon(Icons.check_circle,
                  color: Colors.green, size: 18),
              label: const Text('APPROVE',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Booking Overview ──────────────────────────
                  _sectionCard(
                    title: 'Booking Overview',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        _infoRow('Booking ID', _booking.id.substring(_booking.id.length - 8).toUpperCase()),
                        _infoRow('Customer', '${_booking.userName} · ${_booking.userPhone}'),
                        _infoRow('Pickup', _booking.pickupName),
                        _infoRow('Drop', _booking.dropName),
                        _infoRow('Mode', _booking.modeOfTravel),
                        _infoRow('Total Price', '₹${_booking.price.toStringAsFixed(0)}'),
                        _infoRow('Status', _booking.status.name.toUpperCase()),
                        if (_booking.items.isNotEmpty)
                          _infoRow('Items', '${_booking.items.length} item(s)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Goods Details Editor ──────────────────────
                  _sectionCard(
                    title: 'Edit Goods Details',
                    icon: Icons.inventory_2_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transport Mode',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _vehicleType,
                          dropdownColor: AppTheme.surfaceColorDark,
                          decoration: _inputDecoration('Transport Mode'),
                          items: _modes
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m,
                                        style: const TextStyle(
                                            color: Colors.white)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _vehicleType = v!),
                        ),
                        const SizedBox(height: 12),
                        const Text('Number of Helpers',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (_helperCount > 0)
                                  setState(() => _helperCount--);
                              },
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.white70),
                            ),
                            Text('$_helperCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _helperCount++),
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveGoodsDetails,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8))),
                            child: const Text('Save Goods Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Roadmap Builder ───────────────────────────
                  _sectionCard(
                    title: 'Roadmap Builder',
                    icon: Icons.alt_route,
                    action: TextButton.icon(
                      onPressed: _addSegment,
                      icon: const Icon(Icons.add,
                          color: AppTheme.primaryColor, size: 16),
                      label: const Text('Add Segment',
                          style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                    child: Column(
                      children: [
                        if (_segments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                                'No segments defined. Add segments to create a multi-stop journey.',
                                style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12),
                                textAlign: TextAlign.center),
                          ),
                        ..._segments.asMap().entries.map((entry) {
                          final i = entry.key;
                          final seg = entry.value;
                          return _buildSegmentEditor(i, seg);
                        }),
                        if (_segments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _saveRoadmap,
                              icon: const Icon(Icons.save_outlined,
                                  size: 16),
                              label: const Text('Save Roadmap'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Pricing Override ──────────────────────────
                  _sectionCard(
                    title: 'Pricing Override',
                    icon: Icons.currency_rupee,
                    child: Column(
                      children: [
                        _priceField('Vehicle/Transport Price',
                            _vehiclePriceCtrl, Icons.local_shipping_outlined),
                        const SizedBox(height: 10),
                        _priceField('Helper Cost',
                            _helperCostCtrl, Icons.person_outline),
                        const SizedBox(height: 10),
                        _priceField('Toll Charges',
                            _tollCtrl, Icons.toll_outlined),
                        const SizedBox(height: 10),
                        _priceField('Night Charges',
                            _nightCtrl, Icons.nightlight_outlined),
                        const SizedBox(height: 10),
                        _priceField('Handling Charges',
                            _handlingCtrl, Icons.handyman_outlined),
                        const SizedBox(height: 10),
                        _priceField('Discount',
                            _discountCtrl, Icons.discount_outlined),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: ₹${_calcTotal().toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _savePricingOverride,
                            icon: const Icon(Icons.done, size: 16),
                            label: const Text('Apply Pricing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  double _calcTotal() {
    final v = double.tryParse(_vehiclePriceCtrl.text) ?? 0;
    final h = double.tryParse(_helperCostCtrl.text) ?? 0;
    final t = double.tryParse(_tollCtrl.text) ?? 0;
    final n = double.tryParse(_nightCtrl.text) ?? 0;
    final ha = double.tryParse(_handlingCtrl.text) ?? 0;
    final d = double.tryParse(_discountCtrl.text) ?? 0;
    return v + h + t + n + ha - d;
  }

  Widget _buildSegmentEditor(int index, Map<String, dynamic> seg) {
    final letter = String.fromCharCode(65 + index); // A, B, C...
    final nextLetter = String.fromCharCode(66 + index);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Segment $letter → $nextLetter',
                  style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _assignDriverToSegment(index),
                icon: const Icon(Icons.person_add_outlined,
                    color: Colors.blue, size: 18),
                tooltip: 'Assign Driver',
              ),
              IconButton(
                onPressed: () => _removeSegment(index),
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 18),
                tooltip: 'Remove Segment',
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: seg['fromCtrl'] as TextEditingController,
            style: const TextStyle(color: Colors.white),
            decoration:
                _inputDecoration('From Location ($letter)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: seg['toCtrl'] as TextEditingController,
            style: const TextStyle(color: Colors.white),
            decoration:
                _inputDecoration('To Location ($nextLetter)'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: seg['mode'] as String,
            dropdownColor: AppTheme.surfaceColorDark,
            decoration: _inputDecoration('Mode'),
            items: _modes
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m,
                          style:
                              const TextStyle(color: Colors.white)),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => seg['mode'] = v!),
          ),
          if (seg['mode'] == 'Train' || seg['mode'] == 'Flight') ...[
            const SizedBox(height: 8),
            TextField(
              controller:
                  seg['transportNameCtrl'] as TextEditingController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                  seg['mode'] == 'Train'
                      ? 'Train Name'
                      : 'Flight Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: seg['transportNumberCtrl']
                  as TextEditingController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration(
                  seg['mode'] == 'Train'
                      ? 'Train Number'
                      : 'Flight Number'),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller:
                      seg['dateCtrl'] as TextEditingController,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _inputDecoration('Est. Date (YYYY-MM-DD)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller:
                      seg['timeCtrl'] as TextEditingController,
                  style: const TextStyle(color: Colors.white),
                  decoration:
                      _inputDecoration('Est. Time (HH:MM)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller:
                seg['priceCtrl'] as TextEditingController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: _inputDecoration('Segment Price (₹)'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
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
              Icon(icon, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              if (action != null) ...[
                const Spacer(),
                action,
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _priceField(
      String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      keyboardType: TextInputType.number,
      decoration: _inputDecoration(label, prefixIcon: icon),
      onChanged: (_) => setState(() {}),
    );
  }

  InputDecoration _inputDecoration(String label, {IconData? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: Colors.white38, size: 18)
          : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.primaryColor),
      ),
    );
  }
}
