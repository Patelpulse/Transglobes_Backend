import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/logistics_booking_provider.dart';
import '../../domain/models/logistics_booking.dart';
import '../../../drivers/presentation/providers/driver_provider.dart';

import '../../../../core/theme/app_theme.dart';

class LogisticsBookingScreen extends ConsumerWidget {
  final LogisticsBookingStatus? filterStatus;

  const LogisticsBookingScreen({super.key, this.filterStatus});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(filteredLogisticsBookingsProvider(filterStatus));
    final statusLabel = _getStatusLabel(filterStatus);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        title: Text(statusLabel, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(logisticsBookingsProvider),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) => bookings.isEmpty
          ? const Center(
              child: Text('No shipments found', 
                style: TextStyle(color: Colors.white70)),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(logisticsBookingsProvider),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildSimpleShipmentCard(context, ref, booking);
                },
              ),
            ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 48),
              const SizedBox(height: 16),
              const Text('Failed to load bookings', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(logisticsBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleShipmentCard(BuildContext context, WidgetRef ref, LogisticsBooking booking) {
    final statusColor = _getStatusColor(booking.status);
    final dateStr = DateFormat('MMM dd, hh:mm a').format(booking.createdAt);

    return InkWell(
      onTap: () => _showBookingDetailModal(context, ref, booking),
      borderRadius: BorderRadius.circular(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BOOKED BY: ${booking.userName.toUpperCase()} | ${booking.userPhone}',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(booking.status).toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRow('PICKUP:', booking.pickupName, Icons.location_on_outlined, const Color(0xFF4ADE80)),
            const SizedBox(height: 12),
            _buildRow('DROP:', booking.dropName, Icons.flag_outlined, const Color(0xFFF43F5E)),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderDark, height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MODE OF TRAVEL', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _getModeIcon(booking.modeOfTravel),
                        const SizedBox(width: 6),
                        Text(booking.modeOfTravel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PRICE', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('₹${booking.price.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ordered on: $dateStr', 
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
                if (booking.status != LogisticsBookingStatus.processing)
                  ElevatedButton.icon(
                    onPressed: () => _showActiveDriversModal(context, ref, booking.id),
                    icon: const Icon(Icons.person_search_outlined, size: 16),
                    label: const Text('SEARCH DRIVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBillingEditModal(BuildContext context, WidgetRef ref, LogisticsBooking booking) {
    final vehiclePriceCtrl = TextEditingController(text: booking.vehiclePrice.toInt().toString());
    final helperCostCtrl = TextEditingController(text: booking.helperCost.toInt().toString());
    final additionalChargesCtrl = TextEditingController(text: booking.additionalCharges.toInt().toString());
    final discountAmountCtrl = TextEditingController(text: booking.discountAmount.toInt().toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColorDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          double getVal(String text) => double.tryParse(text) ?? 0.0;
          
          double calculateTotal() {
            final v = getVal(vehiclePriceCtrl.text);
            final h = getVal(helperCostCtrl.text);
            final a = getVal(additionalChargesCtrl.text);
            final d = getVal(discountAmountCtrl.text);
            return (v + h + a) - d;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Update Billing Details', 
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white60),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildEditField('Vehicle Price (₹)', vehiclePriceCtrl, Icons.local_shipping_outlined, (val) => setModalState(() {})),
                  const SizedBox(height: 16),
                  _buildEditField('Helper Cost (₹)', helperCostCtrl, Icons.person_outline, (val) => setModalState(() {})),
                  const SizedBox(height: 16),
                  _buildEditField('Additional Charges (₹)', additionalChargesCtrl, Icons.add_circle_outline, (val) => setModalState(() {})),
                  const SizedBox(height: 16),
                  _buildEditField('Discount (₹)', discountAmountCtrl, Icons.label_off_outlined, (val) => setModalState(() {})),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Calculated Total', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('₹${calculateTotal().toInt()}', 
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Basic validation
                        final v = getVal(vehiclePriceCtrl.text);
                        final h = getVal(helperCostCtrl.text);
                        final a = getVal(additionalChargesCtrl.text);
                        final d = getVal(discountAmountCtrl.text);

                        if (v < 0 || h < 0 || a < 0 || d < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Values cannot be negative')),
                          );
                          return;
                        }

                        final success = await ref.read(logisticsBookingRepoProvider).updateBilling(
                          bookingId: booking.id,
                          vehiclePrice: v,
                          helperCost: h,
                          additionalCharges: a,
                          discountAmount: d,
                          totalPrice: calculateTotal(),
                        );
                        
                        if (success && context.mounted) {
                          ref.invalidate(logisticsBookingsProvider);
                          Navigator.pop(context); // Close edit modal
                          Navigator.pop(context); // Close detail modal to refresh
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Billing updated successfully'),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('SAVE BILLING DETAILS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl, IconData icon, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          onChanged: onChanged,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showBookingDetailModal(BuildContext context, WidgetRef ref, LogisticsBooking booking) {
    final transportNameController = TextEditingController(text: booking.transportName);
    final transportNumberController = TextEditingController(text: booking.transportNumber);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColorDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Stack(
          children: [
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: SingleChildScrollView(
                controller: scrollController,
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Shipment Details', 
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        if (booking.status == LogisticsBookingStatus.processing)
                          Tooltip(
                            message: 'Editing is disabled while the order is being processed by the driver.',
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_clock, size: 12, color: Colors.amber),
                                  SizedBox(width: 4),
                                  Text('Read Only – ProcessingStage', 
                                    style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1, color: Colors.white10),
                    _buildDetailSection('GENERAL INFO', [
                      _buildDetailRow('Client ID', booking.userId),
                      _buildDetailRow('Client Name', booking.userName),
                      _buildDetailRow('Client Phone', booking.userPhone),
                      _buildDetailRow('Booking ID', booking.id),
                      _buildDetailRow('Status', _getStatusLabel(booking.status).toUpperCase(), color: _getStatusColor(booking.status), isBold: true),
                      _buildDetailRow('Date', DateFormat('MMMM dd, yyyy - hh:mm a').format(booking.createdAt)),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('LOGISTICS INFO', [
                      _buildDetailRow('Mode', booking.modeOfTravel.toUpperCase()),
                      _buildDetailRow('Distance', '${booking.distanceKm.toStringAsFixed(1)} KM'),
                      _buildDetailRow('Helper Count', booking.helperCount.toString()),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('ROUTE', [
                      _buildRouteDetail('Pickup', booking.pickupName, booking.pickupAddressDetails),
                      const SizedBox(height: 24),
                      _buildRouteDetail('Drop', booking.dropName, booking.receivedAddressDetails),
                    ]),
                    const SizedBox(height: 24),
                    _buildDetailSection('BILLING', [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (booking.status != LogisticsBookingStatus.processing)
                            TextButton.icon(
                              onPressed: () => _showBillingEditModal(context, ref, booking),
                              icon: const Icon(Icons.edit_note, size: 18, color: Colors.white),
                              label: const Text('EDIT BILLING', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                            )
                          else
                            const Text('EDITING DISABLED', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      _buildDetailRow('Vehicle Price', '₹${booking.vehiclePrice.toInt()}'),
                      _buildDetailRow('Helper Cost', '₹${booking.helperCost.toInt()}'),
                      if (booking.additionalCharges > 0)
                        _buildDetailRow('Additional Charges', '₹${booking.additionalCharges.toInt()}', color: AppTheme.primaryColor),
                      if (booking.discountAmount > 0)
                        _buildDetailRow('Discount Applied', '-₹${booking.discountAmount.toInt()}', color: AppTheme.success),
                      _buildDetailRow('Total Amount', '₹${booking.price.toInt()}', isBold: true, color: Colors.white),
                    ]),
                    if (booking.items.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildDetailSection('ITEMS TO TRANSPORT', [
                        ...booking.items.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white70),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['itemName']?.toString().toUpperCase() ?? 'UNNAMED ITEM', 
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    Text('Category: ${item['type'] ?? 'General'}', 
                                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ]),
                    ],
                    const SizedBox(height: 24),
                    Opacity(
                      opacity: booking.status == LogisticsBookingStatus.processing ? 0.4 : 1.0,
                      child: AbsorbPointer(
                        absorbing: booking.status == LogisticsBookingStatus.processing,
                        child: _buildTransportFields(booking, transportNameController, transportNumberController),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (booking.status != LogisticsBookingStatus.processing)
                      Column(
                        children: [
                          SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  // Show loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Dispatched order to active drivers...'), duration: Duration(seconds: 1)),
                                  );
                                  
                                  // Directly dispatch (no modal)
                                  final success = await ref.read(logisticsBookingRepoProvider).assignDriver(
                                    booking.id, 
                                    'all',
                                    transportName: transportNameController.text.trim(),
                                    transportNumber: transportNumberController.text.trim(),
                                  );
                                  
                                  if (success && context.mounted) {
                                    ref.invalidate(logisticsBookingsProvider);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order generated & sent successfully!'),
                                        backgroundColor: AppTheme.success,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.send_rounded),
                                label: const Text('SEND ORDER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportFields(LogisticsBooking booking, TextEditingController nameCtrl, TextEditingController numCtrl) {
    String nameLabel = '';
    String numLabel = '';
    IconData nameIcon = Icons.info_outline;
    IconData numIcon = Icons.numbers_outlined;

    final mode = booking.modeOfTravel.toLowerCase();
    
    if (mode.contains('train')) {
      nameLabel = 'Train Name';
      numLabel = 'Train Number';
      nameIcon = Icons.train_outlined;
    } else if (mode.contains('flight')) {
      nameLabel = 'Airline Name';
      numLabel = 'Flight Number';
      nameIcon = Icons.flight_takeoff_outlined;
    } else if (mode.contains('sea')) {
      nameLabel = 'Vessel/Ship Name';
      numLabel = 'Voyage Number';
      nameIcon = Icons.directions_boat_outlined;
    } else {
      return const SizedBox.shrink();
    }

    return _buildDetailSection('TRANSPORT DETAILS', [
      const SizedBox(height: 8),
      _buildEditField(nameLabel, nameCtrl, nameIcon, (_) {}),
      const SizedBox(height: 16),
      _buildEditField(numLabel, numCtrl, numIcon, (_) {}),
    ]);
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, fontFamily: 'Manrope')),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'Manrope')),
          Text(value, style: TextStyle(
            color: color ?? Colors.white, 
            fontSize: 14, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontFamily: 'Manrope',
          )),
        ],
      ),
    );
  }

  Widget _buildRouteDetail(String label, String name, Map<String, dynamic>? details) {
    if (details == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      );
    }

    final String addressLabel = details['label']?.toString() ?? 'Address';
    final String fullAddr = details['fullAddress']?.toString() ?? '';
    final String houseNo = details['houseNumber']?.toString() ?? '';
    final String floor = details['floorNumber']?.toString() ?? '';
    final String landmark = details['landmark']?.toString() ?? '';
    final String city = details['city']?.toString() ?? '';
    final String pincode = details['pincode']?.toString() ?? '';
    final String phone = details['phone']?.toString() ?? '';
    final String email = details['email']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label.toUpperCase(), 
                    style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
                const Spacer(),
                if (addressLabel.isNotEmpty)
                  Text(addressLabel, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_pin, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fullAddr.isNotEmpty)
                        Text(fullAddr, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, height: 1.4)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (houseNo.isNotEmpty) _buildAddressTag('House: $houseNo'),
                          if (floor.isNotEmpty) _buildAddressTag('Floor: $floor'),
                          if (city.isNotEmpty) _buildAddressTag(city),
                          if (pincode.isNotEmpty) _buildAddressTag(pincode),
                        ],
                      ),
                      if (landmark.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.assistant_navigation, size: 14, color: Colors.white38),
                              const SizedBox(width: 6),
                              Expanded(child: Text('Near $landmark', style: const TextStyle(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic))),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (phone.isNotEmpty) 
                            Expanded(
                              child: Row(children: [
                                const Icon(Icons.phone_outlined, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(phone, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ]),
                            ),
                          if (email.isNotEmpty)
                            Expanded(
                              child: Row(children: [
                                const Icon(Icons.email_outlined, size: 16, color: Colors.white38),
                                const SizedBox(width: 8),
                                Expanded(child: Text(email, style: const TextStyle(color: Colors.white60, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              ]),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  
    Widget _buildAddressTag(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
      );
    }
  
    Widget _buildRow(String label, String value, IconData icon, Color iconColor) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Manrope')),
              ],
            ),
          ),
        ],
      );
    }

  void _showStationSelector(BuildContext context, Function(String) onSelected) {
    final stations = [
      'Noida Junction (Transit)',
      'Ghaziabad Station',
      'New Delhi Terminal',
      'Anand Vihar Hub',
      'Tughlakabad Dry Port',
      'Dadri ICD'
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundColorDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('SELECT TRANSIT HUB / STATION', 
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...stations.map((s) => ListTile(
              onTap: () {
                onSelected(s);
                Navigator.pop(context);
              },
              leading: const Icon(Icons.train, color: AppTheme.primaryColor),
              title: Text(s, style: const TextStyle(color: Colors.white, fontSize: 14)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
            )).toList(),
          ],
        ),
      ),
    );
  }
  
    Widget _getModeIcon(String mode) {
      switch (mode.toLowerCase()) {
        case 'flight': return const Icon(Icons.airplanemode_active, size: 16, color: Colors.white70);
        case 'sea cargo': return const Icon(Icons.directions_boat, size: 16, color: Colors.white70);
        case 'train': return const Icon(Icons.train, size: 16, color: Colors.white70);
        default: return const Icon(Icons.local_shipping, size: 16, color: Colors.white70);
      }
    }
  
    Color _getStatusColor(LogisticsBookingStatus status) {
      switch (status) {
        case LogisticsBookingStatus.pending: return const Color(0xFFFBBF24);
        case LogisticsBookingStatus.processing: return const Color(0xFF60A5FA);
        case LogisticsBookingStatus.inTransit: return const Color(0xFF818CF8);
        case LogisticsBookingStatus.completed: return const Color(0xFF34D399);
        case LogisticsBookingStatus.cancelled: return const Color(0xFF94A3B8);
        case LogisticsBookingStatus.delayed: return const Color(0xFFF43F5E);
      }
    }
  
    String _getStatusLabel(LogisticsBookingStatus? status) {
      if (status == null) return "All Bookings";
      switch (status) {
        case LogisticsBookingStatus.pending: return "Pending";
        case LogisticsBookingStatus.processing: return "Processing";
        case LogisticsBookingStatus.inTransit: return "In-Transit";
        case LogisticsBookingStatus.completed: return "Completed";
        case LogisticsBookingStatus.cancelled: return "Cancelled";
        case LogisticsBookingStatus.delayed: return "Delayed";
      }
    }
  
    void _showActiveDriversModal(BuildContext context, WidgetRef ref, String bookingId) {
      // Set filter to active when showing the modal
      Future.microtask(() {
        ref.read(driverFilterProvider.notifier).setFilter(DriverFilter.active);
      });
  
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.backgroundColorDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final drivers = ref.watch(filteredDriversProvider);
  
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Active Driver', 
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => ref.read(driverSearchProvider.notifier).updateQuery(val),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search driver name or license...',
                      hintStyle: const TextStyle(color: Colors.white60),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: drivers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, color: Colors.white60, size: 48),
                              const SizedBox(height: 16),
                              Text('No active drivers found',
                                style: TextStyle(color: Colors.white60)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: drivers.length,
                          itemBuilder: (context, index) {
                            final driver = drivers[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                    child: Text(driver.name[0].toUpperCase(), 
                                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(driver.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        Text('License: ${driver.licenseNumber ?? "N/A"}', 
                                          style: const TextStyle(color: Colors.white60, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      
                                      final success = await ref.read(logisticsBookingRepoProvider).assignDriver(bookingId, driver.id);
                                      
                                      if (success) {
                                        ref.invalidate(logisticsBookingsProvider);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Successfully assigned ${driver.name} to this shipment!'),
                                              backgroundColor: AppTheme.success,
                                            ),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Failed to assign driver. Please try again.'),
                                              backgroundColor: AppTheme.danger,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: const Text('SEND', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    Future<String?> _showRailwayStationModal(BuildContext context, WidgetRef ref, String bookingId) {
      final TextEditingController stationController = TextEditingController();
      final List<String> stations = [
        "New Delhi (NDLS)",
        "Mumbai Central (MMCT)",
        "Howrah (HWH)",
        "Chennai Central (MAS)",
        "Bangalore City (SBC)",
        "Pune Junction (PUNE)",
        "Ahmedabad Junction (ADI)",
        "Jaipur Junction (JP)",
        "Lucknow Charbagh (LKO)",
        "Hyderabad Deccan (HYB)",
        "Chandigarh Junction (CDG)",
        "Kanpur Central (CNB)",
        "Patna Junction (PNBE)",
      ];

      return showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppTheme.backgroundColorDark,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Transit / Station', 
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Assign a nearby station or transit point:', 
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                  const SizedBox(height: 24),
                  
                  // Text Entry Field
                  TextField(
                    controller: stationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter custom station name...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      suffixIcon: stationController.text.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                            onPressed: () {
                              setState(() {
                                stationController.clear();
                              });
                            },
                          )
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('OR SELECT FROM MAJOR STATIONS', 
                    style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: stations.length,
                      itemBuilder: (context, index) {
                        final station = stations[index];
                        final isSelected = stationController.text.trim() == station;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            onTap: () {
                              setState(() {
                                stationController.text = station;
                              });
                            },
                            tileColor: isSelected 
                              ? AppTheme.primaryColor.withOpacity(0.15) 
                              : Colors.white.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: isSelected 
                                ? const BorderSide(color: AppTheme.primaryColor, width: 1.5)
                                : BorderSide.none,
                            ),
                            leading: Icon(
                              Icons.train, 
                              color: isSelected ? AppTheme.primaryColor : Colors.white70
                            ),
                            title: Text(station, 
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white, 
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600
                              )
                            ),
                            trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20)
                              : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: stationController.text.trim().isEmpty 
                        ? null 
                        : () => Navigator.pop(context, stationController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('CONFIRM SELECTION', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
            );
          }
        ),
      );
    }
  }
