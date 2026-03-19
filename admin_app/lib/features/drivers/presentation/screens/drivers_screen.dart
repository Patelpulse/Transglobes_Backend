import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/driver_model.dart';
import '../providers/driver_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/network_avatar.dart';
import '../../../../shared/widgets/community_card.dart';
import '../../../support/presentation/screens/chat_screen.dart';

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
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: filteredDrivers.length,
                          itemBuilder: (context, index) {
                            return _DriverCard(driver: filteredDrivers[index]);
                          },
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
    return CommunityCard(
      imageUrl: driver.imageUrl,
      name: driver.name,
      subtitle: driver.vehicleInfo ?? driver.email,
      avatarBorderColor: _statusColor(driver.status),
      trailingAction: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondaryLight),
        color: AppTheme.surfaceColorDark,
        onSelected: (value) async {
          if (value == 'warn') {
            _showWarnDialog(context, ref);
          } else if (value == 'suspend') {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final success = await ref.read(driversProvider.notifier).updateDriverStatus(driver.id, DriverStatus.suspended);
            if (success) {
              scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Driver suspended successfully')));
            } else {
              scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to suspend driver'), backgroundColor: AppTheme.danger));
            }
          } else if (value == 'activate') {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final success = await ref.read(driversProvider.notifier).updateDriverStatus(driver.id, DriverStatus.active);
            if (success) {
              scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Driver activated successfully')));
            } else {
               scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to activate driver'), backgroundColor: AppTheme.danger));
            }
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'warn',
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 20),
                SizedBox(width: 8),
                Text('Warn Driver', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          if (driver.status != DriverStatus.suspended)
            const PopupMenuItem<String>(
              value: 'suspend',
              child: Row(
                children: [
                  Icon(Icons.block, color: AppTheme.danger, size: 20),
                  SizedBox(width: 8),
                  Text('Suspend Driver', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          if (driver.status == DriverStatus.suspended)
            const PopupMenuItem<String>(
              value: 'activate',
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppTheme.success, size: 20),
                  SizedBox(width: 8),
                  Text('Activate Driver', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
      onChat: () {
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
      },
      onView: () {
        // Show details - could be a modal or navigation
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _DriverDetailsModal(driver: driver),
        );
      },
      onDelete: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.surfaceColorDark,
            title: const Text('Delete Driver', style: TextStyle(color: Colors.white)),
            content: Text('Are you sure you want to delete ${driver.name}?', style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  final success = await ref.read(driversProvider.notifier).deleteDriver(driver.id);
                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('${driver.name} deleted successfully')),
                    );
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Failed to delete driver'), backgroundColor: AppTheme.danger),
                    );
                  }
                },
                child: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            ],
          ),
        );
      },
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
                
                const Text("BASIC INFORMATION", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                _buildInfoRow('Status', driver.status.name.toUpperCase()),
                _buildInfoRow('Email', driver.email),
                _buildInfoRow('Phone', driver.mobileNumber ?? 'N/A'),
                _buildInfoRow('Rating', driver.rating.toStringAsFixed(1)),
                _buildInfoRow('Wallet Balance', '₹${driver.walletBalance.toStringAsFixed(2)}'),
                
                const SizedBox(height: 32),
                const Text("VEHICLE DETAILS", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                _buildInfoRow('Model', driver.vehicleModel ?? 'N/A'),
                _buildInfoRow('Number Plate', driver.vehicleNumberPlate ?? 'N/A'),
                _buildInfoRow('Manufacture Year', driver.vehicleYear ?? 'N/A'),
                
                const SizedBox(height: 32),
                const Text("VERIFICATION DOCUMENTS", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                _buildInfoRow('Aadhar Number', driver.aadharCardNumber ?? 'N/A'),
                _buildInfoRow('PAN Number', driver.panCardNumber ?? 'N/A'),
                _buildInfoRow('License Number', driver.licenseNumber ?? 'N/A'),
                
                const SizedBox(height: 24),
                _buildDocumentSection("Aadhar Card", driver.aadharCardPhoto),
                _buildDocumentSection("Driving License", driver.drivingLicensePhoto),
                _buildDocumentSection("PAN Card", driver.panCardPhoto),
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