import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/logistics_provider.dart';
import '../models/logistics_request.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final TextEditingController _trackController = TextEditingController();
  LogisticsRequest? _foundRequest;
  bool _hasSearched = false;

  String _shortBookingId(String id, [int length = 8]) {
    final normalized = id.trim();
    if (normalized.isEmpty) return 'UNKNOWN';
    if (normalized.length <= length) return normalized.toUpperCase();
    return normalized.substring(0, length).toUpperCase();
  }

  void _searchTracking() {
    final provider = Provider.of<LogisticsProvider>(context, listen: false);
    final input = _trackController.text.toUpperCase();
    
    setState(() {
      _foundRequest = provider.requests.firstWhere(
        (r) => 'REQ-${_shortBookingId(r.id)}' == input || r.id.toUpperCase() == input,
        orElse: () => provider.requests.first, // For demo, return first if not found
      );
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLow,
      appBar: AppBar(
        title: Text('LIVE TRACKING', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBox(),
            const SizedBox(height: 32),
            if (_foundRequest != null) _buildActiveTrackingCard(_foundRequest!),
            const SizedBox(height: 32),
            Text(
              'RECENT SHIPMENTS',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.slateGray, letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            ...Provider.of<LogisticsProvider>(context).requests.take(3).map((r) => 
              _buildRecentSearch('REQ-${_shortBookingId(r.id)}', '${r.pickupLocation} → ${r.destinationLocation}', r.status)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: TextField(
        controller: _trackController,
        decoration: InputDecoration(
          hintText: 'Enter ID (e.g. REQ-XXXX)',
          border: InputBorder.none,
          icon: const Icon(LucideIcons.search, color: AppTheme.electricBlue, size: 20),
          suffixIcon: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ElevatedButton(
              onPressed: _searchTracking,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('TRACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTrackingCard(LogisticsRequest req) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE SHIPMENT', style: GoogleFonts.outfit(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text('REQ-${_shortBookingId(req.id)}', style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.truck, color: AppTheme.accentOrange, size: 14),
                    const SizedBox(width: 6),
                    Text(req.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTrackingTimeline(req),
          const SizedBox(height: 32),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          _buildShipmentDetailRow(LucideIcons.mapPin, 'Current Status', 'Processing in ${req.pickupLocation}'),
          const SizedBox(height: 12),
          _buildShipmentDetailRow(LucideIcons.clock, 'ETA', 'Analysis in Progress'),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(LogisticsRequest req) {
    return Column(
      children: [
        _buildTimelineItem('Shipment Ordered', req.pickupLocation, true, true),
        _buildTimelineItem('In Transit', 'Processing', false, true),
        _buildTimelineItem('Out for Delivery', req.destinationLocation, false, true),
        _buildTimelineItem('Delivered', 'Pending', false, false),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String sub, bool isDone, bool hasNext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppTheme.accentOrange : Colors.white10,
                border: Border.all(color: Colors.white24, width: 2),
              ),
            ),
            if (hasNext)
              Container(width: 2, height: 30, color: isDone ? AppTheme.accentOrange : Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isDone ? Colors.white : Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
              Text(sub, style: TextStyle(color: isDone ? Colors.white70 : Colors.white30, fontSize: 11), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShipmentDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white30, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white30, fontSize: 10)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearch(String id, String route, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.bgLow, borderRadius: BorderRadius.circular(10)),
            child: const Icon(LucideIcons.package, color: AppTheme.electricBlue, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryBlue)),
                Text(
                  route, 
                  style: const TextStyle(fontSize: 12, color: AppTheme.slateGray),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(status, style: TextStyle(color: status.contains('Delivered') ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
