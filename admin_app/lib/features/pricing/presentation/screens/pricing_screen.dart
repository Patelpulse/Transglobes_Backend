import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/dio_provider.dart';

// ─── Pricing Config Provider ──────────────────────────────
final pricingConfigsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('admin/pricing');
  if (response.data['success'] == true) {
    return List<Map<String, dynamic>>.from(response.data['data']);
  }
  return [];
});

// ─── Pricing Management Screen ───────────────────────────────────────────────
class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configsAsync = ref.watch(pricingConfigsProvider);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.topBarBackground,
        elevation: 0,
        title: const Text(
          'Pricing Management',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 34,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(pricingConfigsProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () => _showCreateDialog(context, ref),
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
          ),
        ],
      ),
      body: configsAsync.when(
        data: (configs) => configs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.price_change_outlined,
                        color: AppTheme.textMutedLight, size: 64),
                    const SizedBox(height: 16),
                    const Text('No pricing configs yet',
                        style: TextStyle(color: AppTheme.textSecondaryDark)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Default Config'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: configs.length,
                itemBuilder: (context, i) =>
                    _PricingConfigCard(config: configs[i]),
              ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppTheme.textSecondaryDark)),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreatePricingDialog(onSaved: () {
        ref.invalidate(pricingConfigsProvider);
      }),
    );
  }
}

// ─── Pricing Config Card ──────────────────────────────────────────────────────
class _PricingConfigCard extends ConsumerWidget {
  final Map<String, dynamic> config;
  const _PricingConfigCard({required this.config});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = config['isActive'] == true;
    final logistics = config['logistics'] as Map<String, dynamic>? ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : AppTheme.lineSoft,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.16)
              : const Color(0xFFEFF2F7),
          child: Icon(Icons.price_change_outlined,
              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryDark,
              size: 20),
        ),
        title: Row(
          children: [
            Text(config['name'] ?? 'Config',
                style: const TextStyle(
                    color: AppTheme.textPrimaryDark, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ACTIVE',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(
          config['city'] ?? 'All Cities',
          style: const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 12),
        ),
        iconColor: AppTheme.textSecondaryDark,
        collapsedIconColor: AppTheme.textSecondaryDark,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: AppTheme.lineSoft),
                const SizedBox(height: 8),
                const Text('Base Pricing',
                    style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Base Fare',
                        '₹${config['baseFare'] ?? 0}'),
                    _chip('Per KM',
                        '₹${config['perKmCharge'] ?? 0}'),
                    _chip('Per Min',
                        '₹${config['perMinuteCharge'] ?? 0}'),
                    _chip('Min Fare',
                        '₹${config['minimumFare'] ?? 0}'),
                    _chip('GST', '${config['gstPercent'] ?? 18}%'),
                    _chip('Platform Fee',
                        '${config['platformFeePercent'] ?? 0}%'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Surcharges',
                    style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Night Multiplier',
                        '${config['nightChargeMultiplier'] ?? 1.0}x'),
                    _chip('Peak Multiplier',
                        '${config['peakHourMultiplier'] ?? 1.0}x'),
                    _chip('Toll',
                        '₹${config['tollCharges'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Logistics Pricing',
                    style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('Logistics Base',
                        '₹${logistics['baseFare'] ?? 0}'),
                    _chip('Per KM',
                        '₹${logistics['perKmCharge'] ?? 0}'),
                    _chip('Helper/Person',
                        '₹${logistics['helperCostPerPerson'] ?? 0}'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditDialog(context, ref),
                        icon: const Icon(Icons.edit_outlined,
                            size: 14),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textPrimaryDark,
                          side: const BorderSide(
                              color: AppTheme.lineSoft),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!isActive)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _activate(context, ref),
                          icon: const Icon(Icons.check_circle,
                              size: 14),
                          label: const Text('Set Active'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.lineSoft),
      ),
      child: Column(
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondaryDark, fontSize: 9)),
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreatePricingDialog(
        existing: config,
        onSaved: () => ref.invalidate(pricingConfigsProvider),
      ),
    );
  }

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('admin/pricing/${config['_id']}',
          data: {'isActive': true});
      ref.invalidate(pricingConfigsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Create/Edit Pricing Dialog ───────────────────────────────────────────────
class _CreatePricingDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  const _CreatePricingDialog({this.existing, required this.onSaved});

  @override
  ConsumerState<_CreatePricingDialog> createState() =>
      _CreatePricingDialogState();
}

class _CreatePricingDialogState extends ConsumerState<_CreatePricingDialog> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _baseFareCtrl = TextEditingController(text: '0');
  final _perKmCtrl = TextEditingController(text: '0');
  final _perMinCtrl = TextEditingController(text: '0');
  final _minFareCtrl = TextEditingController(text: '0');
  final _gstCtrl = TextEditingController(text: '18');
  final _platformFeeCtrl = TextEditingController(text: '0');
  final _tollCtrl = TextEditingController(text: '0');
  final _nightMultCtrl = TextEditingController(text: '1.0');
  final _peakMultCtrl = TextEditingController(text: '1.0');
  final _logBaseCtrl = TextEditingController(text: '0');
  final _logPerKmCtrl = TextEditingController(text: '0');
  final _helperCostCtrl = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      final l = e['logistics'] as Map<String, dynamic>? ?? {};
      _nameCtrl.text = e['name'] ?? '';
      _cityCtrl.text = e['city'] ?? 'All';
      _baseFareCtrl.text = (e['baseFare'] ?? 0).toString();
      _perKmCtrl.text = (e['perKmCharge'] ?? 0).toString();
      _perMinCtrl.text = (e['perMinuteCharge'] ?? 0).toString();
      _minFareCtrl.text = (e['minimumFare'] ?? 0).toString();
      _gstCtrl.text = (e['gstPercent'] ?? 18).toString();
      _platformFeeCtrl.text = (e['platformFeePercent'] ?? 0).toString();
      _tollCtrl.text = (e['tollCharges'] ?? 0).toString();
      _nightMultCtrl.text = (e['nightChargeMultiplier'] ?? 1.0).toString();
      _peakMultCtrl.text = (e['peakHourMultiplier'] ?? 1.0).toString();
      _logBaseCtrl.text = (l['baseFare'] ?? 0).toString();
      _logPerKmCtrl.text = (l['perKmCharge'] ?? 0).toString();
      _helperCostCtrl.text = (l['helperCostPerPerson'] ?? 0).toString();
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _cityCtrl, _baseFareCtrl, _perKmCtrl, _perMinCtrl,
      _minFareCtrl, _gstCtrl, _platformFeeCtrl, _tollCtrl, _nightMultCtrl,
      _peakMultCtrl, _logBaseCtrl, _logPerKmCtrl, _helperCostCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final dio = ref.read(dioProvider);
      final data = {
        'name': _nameCtrl.text.trim(),
        'city': _cityCtrl.text.trim().isEmpty ? 'All' : _cityCtrl.text.trim(),
        'baseFare': double.tryParse(_baseFareCtrl.text) ?? 0,
        'perKmCharge': double.tryParse(_perKmCtrl.text) ?? 0,
        'perMinuteCharge': double.tryParse(_perMinCtrl.text) ?? 0,
        'minimumFare': double.tryParse(_minFareCtrl.text) ?? 0,
        'gstPercent': double.tryParse(_gstCtrl.text) ?? 18,
        'platformFeePercent': double.tryParse(_platformFeeCtrl.text) ?? 0,
        'tollCharges': double.tryParse(_tollCtrl.text) ?? 0,
        'nightChargeMultiplier': double.tryParse(_nightMultCtrl.text) ?? 1.0,
        'peakHourMultiplier': double.tryParse(_peakMultCtrl.text) ?? 1.0,
        'logistics': {
          'baseFare': double.tryParse(_logBaseCtrl.text) ?? 0,
          'perKmCharge': double.tryParse(_logPerKmCtrl.text) ?? 0,
          'helperCostPerPerson': double.tryParse(_helperCostCtrl.text) ?? 0,
        },
      };

      if (widget.existing != null) {
        await dio.put('admin/pricing/${widget.existing!['_id']}', data: data);
      } else {
        await dio.post('admin/pricing', data: data);
      }

      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColorDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                children: [
                  Text(
                    widget.existing == null
                        ? 'Create Pricing Config'
                        : 'Edit Pricing Config',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Config Name *', _nameCtrl),
                    _field('City (leave blank for All)', _cityCtrl),
                    const _Heading('Base Fare'),
                    Row(children: [
                      Expanded(child: _field('Base Fare (₹)', _baseFareCtrl, isNum: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('Per KM (₹)', _perKmCtrl, isNum: true)),
                    ]),
                    Row(children: [
                      Expanded(child: _field('Per Min (₹)', _perMinCtrl, isNum: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('Min Fare (₹)', _minFareCtrl, isNum: true)),
                    ]),
                    const _Heading('Taxes & Fees'),
                    Row(children: [
                      Expanded(child: _field('GST %', _gstCtrl, isNum: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('Platform Fee %', _platformFeeCtrl, isNum: true)),
                    ]),
                    const _Heading('Surcharges'),
                    Row(children: [
                      Expanded(child: _field('Toll (₹)', _tollCtrl, isNum: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('Night Multiplier', _nightMultCtrl, isNum: true)),
                    ]),
                    _field('Peak Multiplier', _peakMultCtrl, isNum: true),
                    const _Heading('Logistics Pricing'),
                    Row(children: [
                      Expanded(child: _field('Logistics Base (₹)', _logBaseCtrl, isNum: true)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('Per KM (₹)', _logPerKmCtrl, isNum: true)),
                    ]),
                    _field('Helper Cost/Person (₹)', _helperCostCtrl, isNum: true),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                widget.existing == null ? 'Create' : 'Update',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool isNum = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
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
            borderSide:
                const BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text,
          style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13)),
    );
  }
}
