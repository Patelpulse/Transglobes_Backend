import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/address_model.dart';

// ─── Address Book Screen ──────────────────────────────────
class AddressBookScreen extends StatefulWidget {
  final Function(AddressEntry)? onSelect;
  const AddressBookScreen({super.key, this.onSelect});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<AddressEntry> _pickupAddresses = [
    AddressEntry(
      id: '1',
      label: 'Home',
      fullAddress: '12, Green Valley, Sector 21',
      houseNumber: '12',
      floorNumber: 'Ground Floor',
      landmark: 'Near City Mall',
      city: 'Mumbai',
      pincode: '400001',
      phone: '+91 98765 43210',
      email: 'user@example.com',
      type: 'pickup',
      icon: Icons.home_rounded,
    ),
  ];

  final List<AddressEntry> _receivedAddresses = [
    AddressEntry(
      id: '2',
      label: "Parent's Home",
      fullAddress: '8, Patel Nagar, MG Road',
      houseNumber: '8',
      floorNumber: '2nd Floor',
      landmark: 'Opp. Reliance Fresh',
      city: 'Pune',
      pincode: '411001',
      phone: '+91 91234 56789',
      type: 'received',
      icon: Icons.location_on_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddressForm({AddressEntry? existing, required String type}) {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final addressController = TextEditingController(text: existing?.fullAddress ?? '');
    final houseController = TextEditingController(text: existing?.houseNumber ?? '');
    final floorController = TextEditingController(text: existing?.floorNumber ?? '');
    final landmarkController = TextEditingController(text: existing?.landmark ?? '');
    final cityController = TextEditingController(text: existing?.city ?? '');
    final pincodeController = TextEditingController(text: existing?.pincode ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    IconData selectedIcon = existing?.icon ?? Icons.location_on_rounded;

    final iconOptions = [
      Icons.home_rounded,
      Icons.work_rounded,
      Icons.location_on_rounded,
      Icons.star_rounded,
      Icons.favorite_rounded,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Container(
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    existing == null
                        ? 'Add New ${type == 'pickup' ? 'Pickup' : 'Delivery'} Address'
                        : 'Edit Address',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type == 'pickup'
                        ? 'Where should we pick up from?'
                        : 'Where should we deliver to?',
                    style: TextStyle(fontSize: 13, color: context.colors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // Icon picker
                  _sectionLabel('Choose Icon'),
                  const SizedBox(height: 10),
                  Row(
                    children: iconOptions.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedIcon = icon),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.theme.primaryColor
                                : context.theme.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? context.theme.primaryColor
                                  : context.theme.dividerColor.withOpacity(0.2),
                            ),
                          ),
                          child: Icon(icon,
                              color: isSelected ? Colors.white : context.colors.textSecondary,
                              size: 24),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // ── Address Label ──
                  _sectionLabel('Address Label'),
                  const SizedBox(height: 8),
                  _buildField(labelController, 'Label', 'e.g. Home, Office, Warehouse',
                      Icons.label_outline),
                  const SizedBox(height: 16),

                  // ── Contact Information ──
                  _sectionLabel('Contact Information'),
                  const SizedBox(height: 8),
                  _buildField(phoneController, 'Phone Number', '+91 XXXXX XXXXX',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _buildField(emailController, 'Email Address', 'example@email.com',
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),

                  // ── Address Details ──
                  _sectionLabel('Address Details'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(houseController, 'House / Flat No.',
                            'e.g. A-12', Icons.house_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(floorController, 'Floor', 'e.g. 3rd Floor',
                            Icons.layers_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildField(addressController, 'Full Address',
                      'Street, Area, Locality', Icons.location_on_outlined,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  _buildField(landmarkController, 'Landmark (optional)',
                      'e.g. Near City Mall', Icons.place_outlined),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                            cityController, 'City', 'Mumbai', Icons.location_city_outlined),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(pincodeController, 'Pincode', '400001',
                            Icons.pin_drop_outlined,
                            keyboardType: TextInputType.number),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (addressController.text.trim().isEmpty ||
                            cityController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill address and city')),
                          );
                          return;
                        }
                        final newEntry = AddressEntry(
                          id: existing?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          label: labelController.text.trim().isEmpty
                              ? (type == 'pickup' ? 'Pickup' : 'Delivery')
                              : labelController.text.trim(),
                          fullAddress: addressController.text.trim(),
                          houseNumber: houseController.text.trim().isEmpty
                              ? null
                              : houseController.text.trim(),
                          floorNumber: floorController.text.trim().isEmpty
                              ? null
                              : floorController.text.trim(),
                          landmark: landmarkController.text.trim().isEmpty
                              ? null
                              : landmarkController.text.trim(),
                          city: cityController.text.trim(),
                          pincode: pincodeController.text.trim(),
                          phone: phoneController.text.trim().isEmpty
                              ? null
                              : phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          type: type,
                          icon: selectedIcon,
                        );
                        setState(() {
                          if (type == 'pickup') {
                            if (existing != null) {
                              final idx = _pickupAddresses
                                  .indexWhere((a) => a.id == existing.id);
                              if (idx != -1) _pickupAddresses[idx] = newEntry;
                            } else {
                              _pickupAddresses.add(newEntry);
                            }
                          } else {
                            if (existing != null) {
                              final idx = _receivedAddresses
                                  .indexWhere((a) => a.id == existing.id);
                              if (idx != -1) _receivedAddresses[idx] = newEntry;
                            } else {
                              _receivedAddresses.add(newEntry);
                            }
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Address saved!'),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: Text(
                          existing == null ? 'Save Address' : 'Update Address',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: context.colors.textPrimary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  void _deleteAddress(AddressEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Address'),
        content: Text('Remove "${entry.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                if (entry.type == 'pickup') {
                  _pickupAddresses.removeWhere((a) => a.id == entry.id);
                } else {
                  _receivedAddresses.removeWhere((a) => a.id == entry.id);
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: context.colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Address Book',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: context.colors.textPrimary)),
        centerTitle: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.theme.primaryColor,
          labelColor: context.theme.primaryColor,
          unselectedLabelColor: context.colors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.upload_rounded), text: 'Pickup'),
            Tab(icon: Icon(Icons.download_rounded), text: 'Received'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddressList(_pickupAddresses, 'pickup'),
          _buildAddressList(_receivedAddresses, 'received'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(
            type: _tabController.index == 0 ? 'pickup' : 'received'),
        backgroundColor: context.theme.primaryColor,
        icon: const Icon(Icons.add_location_alt_rounded, color: Colors.white),
        label: const Text('Add Address',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAddressList(List<AddressEntry> addresses, String type) {
    if (addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pickup' ? Icons.upload_rounded : Icons.download_rounded,
              size: 64,
              color: context.theme.primaryColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type == 'pickup' ? 'Pickup' : 'Delivery'} Addresses',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text('Tap "Add Address" to save one',
                style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: addresses.length,
      itemBuilder: (_, idx) {
        final addr = addresses[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: () => _showAddressForm(existing: addr, type: type),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.theme.primaryColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(addr.icon,
                              color: context.theme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(addr.label,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: context.colors.textPrimary)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (type == 'pickup'
                                              ? Colors.green
                                              : Colors.blue)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      type == 'pickup' ? 'Pickup' : 'Delivery',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: type == 'pickup'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${addr.city} - ${addr.pincode}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.theme.primaryColor)),
                            ],
                          ),
                        ),
                        // Edit & Delete buttons
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit_rounded,
                                  size: 18, color: context.theme.primaryColor),
                              onPressed: () =>
                                  _showAddressForm(existing: addr, type: type),
                              tooltip: 'Edit',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  size: 18, color: Colors.red),
                              onPressed: () => _deleteAddress(addr),
                              tooltip: 'Delete',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    if (widget.onSelect != null) ...[
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            widget.onSelect!(addr);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Select this Address',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(
                            foregroundColor: context.theme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: context.theme.primaryColor.withOpacity(0.08),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Address info rows
                    _infoRow(Icons.location_on_outlined, addr.fullAddress),
                    if (addr.houseNumber != null || addr.floorNumber != null)
                      _infoRow(
                        Icons.house_outlined,
                        [
                          if (addr.houseNumber != null)
                            'House/Flat: ${addr.houseNumber}',
                          if (addr.floorNumber != null)
                            'Floor: ${addr.floorNumber}',
                        ].join('  ·  '),
                      ),
                    if (addr.landmark != null)
                      _infoRow(Icons.place_outlined, addr.landmark!),
                    if (addr.phone != null)
                      _infoRow(Icons.phone_outlined, addr.phone!),
                    if (addr.email != null)
                      _infoRow(Icons.email_outlined, addr.email!),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: context.colors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13, color: context.colors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
