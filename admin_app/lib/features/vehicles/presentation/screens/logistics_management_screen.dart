import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/logistics_vehicle_provider.dart';
import '../../domain/models/logistics_vehicle.dart';
import '../../../../core/theme/app_theme.dart';

class LogisticsManagementScreen extends ConsumerWidget {
  const LogisticsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(logisticsVehiclesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColorDark,
      appBar: AppBar(
        title: const Text('Logistics Modes Management', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        data: (vehicles) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vehicles.length,
          itemBuilder: (context, index) {
            final vehicle = vehicles[index];
            return _buildVehicleCard(context, ref, vehicle);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }

  Widget _buildVehicleCard(BuildContext context, WidgetRef ref, LogisticsVehicle vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColorDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              vehicle.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => 
                Container(width: 80, height: 80, color: Colors.grey[800], child: const Icon(Icons.broken_image)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Capacity: ${vehicle.capacity}',
                  style: TextStyle(color: AppTheme.textMutedLight, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Base: ₹${vehicle.basePrice.toInt()}',
                      style: const TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '₹${vehicle.pricePerKm.toInt()}/km',
                      style: TextStyle(color: AppTheme.textSecondaryLight, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => _showEditDialog(context, ref, vehicle),
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
              ),
              Switch(
                value: vehicle.isActive,
                onChanged: (val) async {
                  await ref.read(logisticsVehicleRepositoryProvider).updateLogisticsVehicle(vehicle.id, {'isActive': val});
                  if (context.mounted) {
                    ref.invalidate(logisticsVehiclesProvider);
                  }
                },
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final kmPriceCtrl = TextEditingController();
    final imgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColorDark,
        title: const Text('Add New Mode', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameCtrl, 'Name (e.g. Train)'),
              _buildTextField(capCtrl, 'Capacity (e.g. 50 tons)'),
              _buildTextField(priceCtrl, 'Base Price (e.g. 5000)', keyboardType: TextInputType.number),
              _buildTextField(kmPriceCtrl, 'Price Per Km (e.g. 10)', keyboardType: TextInputType.number),
              _buildTextField(imgCtrl, 'Image URL'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final vehicle = LogisticsVehicle(
                id: '',
                name: nameCtrl.text,
                capacity: capCtrl.text,
                basePrice: double.tryParse(priceCtrl.text) ?? 0.0,
                pricePerKm: double.tryParse(kmPriceCtrl.text) ?? 0.0,
                imageUrl: imgCtrl.text,
              );
              await ref.read(logisticsVehicleRepositoryProvider).addLogisticsVehicle(vehicle);
              if (context.mounted) {
                ref.invalidate(logisticsVehiclesProvider);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, LogisticsVehicle vehicle) {
    final nameCtrl = TextEditingController(text: vehicle.name);
    final capCtrl = TextEditingController(text: vehicle.capacity);
    final priceCtrl = TextEditingController(text: vehicle.basePrice.toString());
    final kmPriceCtrl = TextEditingController(text: vehicle.pricePerKm.toString());
    final imgCtrl = TextEditingController(text: vehicle.imageUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColorDark,
        title: const Text('Edit Mode', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameCtrl, 'Name'),
              _buildTextField(capCtrl, 'Capacity'),
              _buildTextField(priceCtrl, 'Base Price', keyboardType: TextInputType.number),
              _buildTextField(kmPriceCtrl, 'Price Per Km', keyboardType: TextInputType.number),
              _buildTextField(imgCtrl, 'Image URL'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(logisticsVehicleRepositoryProvider).updateLogisticsVehicle(vehicle.id, {
                'name': nameCtrl.text,
                'capacity': capCtrl.text,
                'basePrice': double.tryParse(priceCtrl.text) ?? 0.0,
                'pricePerKm': double.tryParse(kmPriceCtrl.text) ?? 0.0,
                'imageUrl': imgCtrl.text,
              });
              if (context.mounted) {
                ref.invalidate(logisticsVehiclesProvider);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textMutedLight),
          filled: true,
          fillColor: AppTheme.backgroundColorDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
