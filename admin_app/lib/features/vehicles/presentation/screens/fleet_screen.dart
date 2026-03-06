import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/vehicle.dart';
import '../../presentation/providers/vehicle_provider.dart';
import '../../../../shared/widgets/network_avatar.dart';

class FleetScreen extends ConsumerStatefulWidget {
  const FleetScreen({super.key});

  @override
  ConsumerState<FleetScreen> createState() => _FleetScreenState();
}

class _FleetScreenState extends ConsumerState<FleetScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsyncValue = ref.watch(vehiclesProvider);
    final filteredVehicles = ref.watch(filteredVehiclesProvider);
    final currentFilter = ref.watch(vehicleFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(ref, currentFilter),
            _buildFilterPills(),
            Expanded(
              child: vehiclesAsyncValue.when(
                data: (_) {
                  if (filteredVehicles.isEmpty) {
                    return const Center(
                      child: Text(
                        "No vehicles found matching criteria.",
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(vehiclesProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredVehicles.length,
                      itemBuilder: (context, index) {
                        final vehicle = filteredVehicles[index];
                        final isExpired =
                            vehicle.status == VehicleStatus.expired;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              _showVehicleDetails(context, vehicle);
                            },
                            child: (isExpired || vehicle.needsInspection)
                                ? _buildInspectionCard(vehicle)
                                : _buildVehicleCard(vehicle),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF135BEC)),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFF43F5E),
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Failed to load fleet data.",
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(vehiclesProvider),
                        child: const Text(
                          "Retry",
                          style: TextStyle(color: Color(0xFF135BEC)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddVehicleDialog(context);
        },
        backgroundColor: const Color(0xFF135BEC),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader() {
    if (_isSearching) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search plate, vin, name...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          ref
                              .read(searchQueryProvider.notifier)
                              .updateQuery(val);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          ref
                              .read(searchQueryProvider.notifier)
                              .updateQuery('');
                          setState(() {});
                        },
                        child: const Icon(
                          Icons.close,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(searchQueryProvider.notifier).updateQuery('');
                });
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Color(0xFF135BEC),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 20),
            ),
          ),
          const Text(
            "Transglobe Fleet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isSearching = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(WidgetRef ref, VehicleFilter currentFilter) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF2D364A), width: 1)),
      ),
      child: Row(
        children: [
          _buildTab("All", VehicleFilter.all, currentFilter, ref),
          _buildTab("Cabs", VehicleFilter.cab, currentFilter, ref),
          _buildTab("Trucks", VehicleFilter.truck, currentFilter, ref),
          _buildTab("Buses", VehicleFilter.bus, currentFilter, ref),
        ],
      ),
    );
  }

  Widget _buildTab(
    String title,
    VehicleFilter filter,
    VehicleFilter currentFilter,
    WidgetRef ref,
  ) {
    final isActive = filter == currentFilter;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(vehicleFilterProvider.notifier).setFilter(filter),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Container(
            decoration: isActive
                ? const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF135BEC), width: 2),
                    ),
                  )
                : null,
            padding: const EdgeInsets.only(bottom: 8),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: isActive
                    ? const Color(0xFF135BEC)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter by Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatusFilterOption(ref, "All Statuses", null),
              _buildStatusFilterOption(ref, "Active", VehicleStatus.active),
              _buildStatusFilterOption(
                ref,
                "Maintenance",
                VehicleStatus.maintenance,
              ),
              _buildStatusFilterOption(ref, "Inactive", VehicleStatus.inactive),
              _buildStatusFilterOption(ref, "Expired", VehicleStatus.expired),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterOption(
    WidgetRef ref,
    String label,
    VehicleStatus? status,
  ) {
    final currentStatus = ref.watch(statusFilterProvider);
    final isSelected = currentStatus == status;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF135BEC))
          : null,
      onTap: () {
        ref.read(statusFilterProvider.notifier).setFilter(status);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildFilterPills() {
    final statusFilter = ref.watch(statusFilterProvider);
    final needsInspection = ref.watch(needsInspectionProvider);

    String statusLabel = "Status";
    if (statusFilter == VehicleStatus.active) statusLabel = "Active";
    if (statusFilter == VehicleStatus.inactive) statusLabel = "Inactive";
    if (statusFilter == VehicleStatus.maintenance) statusLabel = "Maintenance";
    if (statusFilter == VehicleStatus.expired) statusLabel = "Expired";

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showStatusFilterSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: statusFilter != null
                    ? const Color(0xFF135BEC)
                    : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(
                    statusLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          /* Insurance filter placeholder for future expansion */
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Text(
                  "Insurance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.expand_more, color: Colors.white, size: 16),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(needsInspectionProvider.notifier).toggle();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: needsInspection
                    ? const Color(0xFF135BEC)
                    : const Color(0xFF135BEC).withOpacity(0.1),
                border: Border.all(
                  color: const Color(0xFF135BEC).withOpacity(0.5),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Needs Inspection",
                style: TextStyle(
                  color: needsInspection
                      ? Colors.white
                      : const Color(0xFF135BEC),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVehicleDetails(BuildContext context, Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF101622),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D364A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: NetworkAvatarBox(
                          imageUrl: vehicle.imageUrl,
                          name: vehicle.name,
                          size: 120,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      vehicle.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      vehicle.plateNumber,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF135BEC),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildDetailRow("VIN Number", vehicle.vin),
                    const Divider(color: Color(0xFF2D364A), height: 32),
                    _buildDetailRow(
                      "Status",
                      vehicle.status.name.toUpperCase(),
                      color: _getStatusColor(vehicle.status),
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 32),
                    _buildDetailRow(
                      "Insurance Expiry",
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(vehicle.insuranceExpiry),
                    ),
                    const Divider(color: Color(0xFF2D364A), height: 32),
                    if (vehicle.mileage != null) ...[
                      _buildDetailRow(
                        "Mileage",
                        "${NumberFormat('#,###').format(vehicle.mileage)} km",
                      ),
                      const Divider(color: Color(0xFF2D364A), height: 32),
                    ],
                    if (vehicle.batteryLevel != null) ...[
                      _buildDetailRow(
                        "Battery Level",
                        "${(vehicle.batteryLevel! * 100).toInt()}%",
                      ),
                      const Divider(color: Color(0xFF2D364A), height: 32),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF135BEC),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Edit action for ${vehicle.name}'),
                            ),
                          );
                        },
                        child: const Text(
                          'Edit Vehicle',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow(
    String label,
    String value, {
    Color color = Colors.white,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showAddVehicleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Add Vehicle',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'This feature allows administrators to onboard new vehicles into the system. Functionality mock.',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF135BEC),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.active:
        return const Color(0xFF10B981); // Success
      case VehicleStatus.inactive:
        return const Color(0xFF64748B); // Neutral
      case VehicleStatus.maintenance:
        return const Color(0xFFF59E0B); // Warning
      case VehicleStatus.expired:
        return const Color(0xFFF43F5E); // Danger
    }
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final formattedDate = dateFormat.format(vehicle.insuranceExpiry);

    String info2Label = "";
    String info2Value = "";
    Color info2Color = Colors.white;

    if (vehicle.mileage != null) {
      info2Label = "LAST MAINTENANCE";
      info2Value = "${NumberFormat('#,###').format(vehicle.mileage)} km ago";
    } else if (vehicle.batteryLevel != null) {
      info2Label = "CHARGING";
      info2Value = "${(vehicle.batteryLevel! * 100).toInt()}%";
      info2Color = const Color(0xFF135BEC);
    } else {
      info2Label = "PLATE NUMBER";
      info2Value = vehicle.plateNumber;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        border: Border.all(color: const Color(0xFF2D364A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: NetworkAvatarBox(
                  imageUrl: vehicle.imageUrl,
                  name: vehicle.name,
                  size: 64,
                  shape: BoxShape.rectangle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            "${vehicle.name} • ${vehicle.plateNumber}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(top: 4, left: 8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(vehicle.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.vin,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2D364A), height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "INSURANCE EXPIRY",
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info2Label,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info2Value,
                      style: TextStyle(
                        color: info2Color,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildInspectionCard(Vehicle vehicle) {
    final dateFormat = DateFormat('MMM dd');
    final formattedDate = dateFormat.format(vehicle.insuranceExpiry);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.5),
        border: Border.all(
          color: vehicle.status == VehicleStatus.expired
              ? const Color(0xFFF43F5E).withOpacity(0.5)
              : const Color(0xFFF59E0B).withOpacity(0.5),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: NetworkAvatarBox(
                        imageUrl: vehicle.imageUrl,
                        name: vehicle.name,
                        size: 64,
                        shape: BoxShape.rectangle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 120),
                            child: Text(
                              vehicle.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.vin,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2D364A), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "INSURANCE EXPIRY",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.status == VehicleStatus.expired
                                ? "EXPIRED ($formattedDate)"
                                : "DUE IN 3 DAYS",
                            style: TextStyle(
                              color: vehicle.status == VehicleStatus.expired
                                  ? const Color(0xFFF43F5E)
                                  : const Color(0xFFF59E0B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PLATE NUMBER",
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vehicle.plateNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: vehicle.status == VehicleStatus.expired
                    ? const Color(0xFFF43F5E)
                    : const Color(0xFFF59E0B),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    vehicle.status == VehicleStatus.expired
                        ? "URGENT ACTION"
                        : "INSPECTION REQ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
