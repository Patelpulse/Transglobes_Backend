import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/driver_model.dart';
import '../providers/driver_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/network_avatar.dart';
import '../../../support/presentation/screens/chat_screen.dart';
import 'package:intl/intl.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversProvider);
    final filter = ref.watch(driverFilterProvider);
    final filteredDrivers = ref.watch(filteredDriversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Driver Management',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 300,
            child: TextField(
              onChanged: (value) {
                ref.read(driverSearchProvider.notifier).updateQuery(value);
              },
              decoration: InputDecoration(
                hintText: 'Search drivers...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/drivers/new'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterTabs(ref, filter),
            Expanded(
              child: driversAsync.when(
                data: (_) => filteredDrivers.isEmpty
                    ? const Center(
                        child: Text(
                          'No drivers found',
                          style: TextStyle(color: AppTheme.textSecondaryLight),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref.read(driversProvider.notifier).getDrivers(),
                        child: CustomScrollView(
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.all(16),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 320,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.6,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _DriverCard(driver: filteredDrivers[index]),
                                  childCount: filteredDrivers.length,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.danger, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Error: $e',
                        style: const TextStyle(color: AppTheme.danger),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(driversProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildFilterTabs(WidgetRef ref, DriverFilter current) {
    final filters = [
      (DriverFilter.all, 'All'),
      (DriverFilter.active, 'Active'),
      (DriverFilter.pending, 'Pending'),
      (DriverFilter.suspended, 'Suspended'),
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: filters.map((item) {
          final isSelected = current == item.$1;
          return GestureDetector(
            onTap: () => ref.read(driverFilterProvider.notifier).setFilter(item.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                ),
              ),
              child: Center(
                child: Text(
                  item.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DriverCard extends ConsumerWidget {
  final Driver driver;
  const _DriverCard({required this.driver});

  Color _statusColor(DriverStatus status) {
    switch (status) {
      case DriverStatus.active:
        return AppTheme.success;
      case DriverStatus.pending:
        return AppTheme.warning;
      case DriverStatus.suspended:
        return AppTheme.danger;
      default:
        return AppTheme.textMutedLight;
    }
  }

  void _showWarnDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColorDark,
        title: Text('Warn ${driver.name}', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter reason for warning:', style: TextStyle(color: AppTheme.textSecondaryLight)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'e.g. Inappropriate behavior...',
                hintStyle: TextStyle(color: AppTheme.textMutedLight),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppTheme.backgroundColorDark,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning, foregroundColor: Colors.black),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              final reason = controller.text.trim();
              Navigator.pop(context);
              
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final success = await ref.read(driversProvider.notifier).warnDriver(driver.id, reason);
              if (success) {
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Warning sent to driver successfully.')));
              } else {
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to send warning.'), backgroundColor: AppTheme.danger));
              }
            },
            child: const Text('Send Warning'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(driver.status);
    final statusLabel = driver.status.name.toUpperCase();
    final cardGradient = driver.status == DriverStatus.active
        ? const [Color(0xFFECFDF5), Color(0xFFD1FAE5)]
        : driver.status == DriverStatus.suspended
            ? const [Color(0xFFFEF2F2), Color(0xFFFEE2E2)]
            : const [Color(0xFFFFFBEB), Color(0xFFFEF3C7)];

    String displayIfAvailable(String? value) {
      if (value == null) return 'N/A';
      final trimmed = value.trim();
      return trimmed.isEmpty ? 'N/A' : trimmed;
    }

    final primaryInfoLine =
        'Mobile: ${displayIfAvailable(driver.mobileNumber)}  •  PAN: ${displayIfAvailable(driver.panCardNumber)}';
    final secondaryInfoLine =
        'Aadhaar: ${displayIfAvailable(driver.aadharCardNumber)}  •  DL: ${displayIfAvailable(driver.licenseNumber)}';

    final vehicleLine = [
      displayIfAvailable(driver.vehicleModel),
      displayIfAvailable(driver.vehicleNumberPlate),
      displayIfAvailable(driver.vehicleYear),
    ].where((item) => item != 'N/A').join(' • ');

    final docsSummary = [
      if ((driver.insurance ?? '').trim().isNotEmpty) 'Insurance',
      if ((driver.rcBook ?? '').trim().isNotEmpty) 'RC',
      if ((driver.panCardImage ?? '').trim().isNotEmpty) 'PAN Img',
      if ((driver.aadharCardPhoto ?? '').trim().isNotEmpty) 'Aadhaar Img',
      if ((driver.drivingLicensePhoto ?? '').trim().isNotEmpty) 'DL Img',
    ];

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _DriverDetailsModal(driver: driver),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cardGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NetworkAvatarBox(
                  imageUrl: driver.imageUrl,
                  name: driver.name,
                  size: 30,
                  shape: BoxShape.circle,
                  borderColor: statusColor,
                  borderWidth: 2,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driver.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.more_vert, color: AppTheme.textSecondaryLight),
                  onSelected: (value) async {
                    if (value == 'warn') {
                      _showWarnDialog(context, ref);
                    } else if (value == 'suspend') {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final success = await ref
                          .read(driversProvider.notifier)
                          .updateDriverStatus(driver.id, DriverStatus.suspended);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Driver suspended successfully'
                              : 'Failed to suspend driver'),
                          backgroundColor:
                              success ? null : AppTheme.danger,
                        ),
                      );
                    } else if (value == 'activate') {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final success = await ref
                          .read(driversProvider.notifier)
                          .updateDriverStatus(driver.id, DriverStatus.active);
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Driver activated successfully'
                              : 'Failed to activate driver'),
                          backgroundColor:
                              success ? null : AppTheme.danger,
                        ),
                      );
                    } else if (value == 'chat') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: driver.id,
                            receiverName: driver.name,
                            receiverImage: driver.imageUrl,
                          ),
                        ),
                      );
                    } else if (value == 'delete') {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppTheme.surfaceColorDark,
                          title: const Text('Delete Driver',
                              style: TextStyle(color: Colors.white)),
                          content: Text(
                            'Are you sure you want to delete ${driver.name}?',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final scaffoldMessenger =
                                    ScaffoldMessenger.of(context);
                                Navigator.pop(context);
                                final success = await ref
                                    .read(driversProvider.notifier)
                                    .deleteDriver(driver.id);
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? '${driver.name} deleted successfully'
                                        : 'Failed to delete driver'),
                                    backgroundColor:
                                        success ? null : AppTheme.danger,
                                  ),
                                );
                              },
                              child: const Text('Delete',
                                  style: TextStyle(color: AppTheme.danger)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'warn',
                      child: Text('Warn Driver'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'chat',
                      child: Text('Open Chat'),
                    ),
                    if (driver.status != DriverStatus.suspended)
                      const PopupMenuItem<String>(
                        value: 'suspend',
                        child: Text('Suspend Driver'),
                      ),
                    if (driver.status == DriverStatus.suspended)
                      const PopupMenuItem<String>(
                        value: 'activate',
                        child: Text('Activate Driver'),
                      ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Delete Driver'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              driver.email.isEmpty ? 'No email' : driver.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMutedLight,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _chip(statusLabel, statusColor),
                const SizedBox(width: 6),
                _chip(
                  driver.dob != null
                      ? DateFormat('dd MMM yyyy').format(driver.dob!)
                      : 'DOB N/A',
                  const Color(0xFF6366F1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              primaryInfoLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              secondaryInfoLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              vehicleLine.isEmpty ? 'Vehicle: N/A' : 'Vehicle: $vehicleLine',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondaryDark,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              docsSummary.isEmpty
                  ? 'Docs: Not uploaded'
                  : 'Docs: ${docsSummary.join(", ")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMutedLight,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DriverDetailsModal extends StatelessWidget {
  final Driver driver;
  const _DriverDetailsModal({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColorDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: AppTheme.borderDark,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: NetworkAvatarBox(
                    imageUrl: driver.imageUrl,
                    name: driver.name,
                    size: 120,
                    shape: BoxShape.circle,
                    borderColor: AppTheme.primaryColor,
                    borderWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    driver.name,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text("BASIC INFORMATION", style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInfoRow('Driver ID', driver.id),
                _buildInfoRow('Status', driver.status.name.toUpperCase()),
                _buildInfoRow('Email', driver.email),
                _buildInfoRow('Phone', driver.mobileNumber ?? 'N/A'),
                _buildInfoRow('Date of Birth', driver.dob != null ? DateFormat('dd MMM yyyy').format(driver.dob!) : 'N/A'),
                _buildInfoRow('Rating', driver.rating.toStringAsFixed(1)),
                _buildInfoRow('Wallet Balance', '₹${driver.walletBalance.toStringAsFixed(2)}'),
                
                const SizedBox(height: 32),
                const Text("VEHICLE DETAILS", style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInfoRow('Model', driver.vehicleModel ?? 'N/A'),
                _buildInfoRow('Number Plate', driver.vehicleNumberPlate ?? 'N/A'),
                _buildInfoRow('Manufacture Year', driver.vehicleYear ?? 'N/A'),
                
                const SizedBox(height: 32),
                const Text("VERIFICATION DOCUMENTS", style: TextStyle(color: AppTheme.warning, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                _buildInfoRow('Aadhar Number', driver.aadharCardNumber ?? 'N/A'),
                _buildInfoRow('PAN Number', driver.panCardNumber ?? 'N/A'),
                _buildInfoRow('License Number', driver.licenseNumber ?? 'N/A'),
                
                const SizedBox(height: 24),
                _buildDocumentSection("Aadhar Card", driver.aadharCardPhoto),
                _buildDocumentSection("Driving License", driver.drivingLicensePhoto),
                _buildDocumentSection("PAN Card", driver.panCardPhoto),
                _buildDocumentSection("PAN Card (High-res)", driver.panCardImage),
                _buildDocumentSection("RC Book", driver.rcBook),
                _buildDocumentSection("Insurance", driver.insurance),
                _buildDocumentSection("Signature", driver.signatureUrl),
                
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColorDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDark),
          ),
          child: url != null && url.isNotEmpty
              ? NetworkAvatarBox(
                  imageUrl: url,
                  name: label,
                  size: 200,
                  shape: BoxShape.rectangle,
                  fallback: const Center(child: Icon(Icons.broken_image, color: AppTheme.textMutedLight)),
                )
              : const Center(child: Text("Not Uploaded", style: TextStyle(color: AppTheme.textMutedLight))),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textMutedLight, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}