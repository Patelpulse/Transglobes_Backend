import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/country_code_provider.dart';
import '../../../../core/theme/app_theme.dart';

class CountryCodeManagementScreen extends ConsumerStatefulWidget {
  const CountryCodeManagementScreen({super.key});

  @override
  ConsumerState<CountryCodeManagementScreen> createState() => _CountryCodeManagementScreenState();
}

class _CountryCodeManagementScreenState extends ConsumerState<CountryCodeManagementScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedStatus = 'Publish';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _addCode() {
    if (_codeController.text.isNotEmpty && _nameController.text.isNotEmpty) {
      ref.read(countryCodeProvider.notifier).addCountryCode(
        _codeController.text,
        _nameController.text,
        _selectedStatus,
      );
      _codeController.clear();
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Country Code Added Successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final countryCodes = ref.watch(countryCodeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Country Code Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form Section
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Enter Code',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: 'Enter Country Code',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter Country Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter Country Name',
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select Status',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: ['Publish', 'Unpublish']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedStatus = v!),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _addCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Add Country Code'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Table Section
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Text('Show'),
                              const SizedBox(width: 8),
                              const Text('10'), // Placeholder for entries count
                              const SizedBox(width: 8),
                              const Text('entries'),
                              const Spacer(),
                              const Text('Search:'),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 200,
                                height: 35,
                                child: TextField(
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Table
                        Table(
                          border: TableBorder(
                            horizontalInside: BorderSide(color: Colors.grey.withOpacity(0.1)),
                          ),
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(3),
                            2: FlexColumnWidth(4),
                            3: FlexColumnWidth(3),
                            4: FlexColumnWidth(3), // Increased from 2 to 3
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05)),
                              children: const [
                                Padding(padding: EdgeInsets.all(12), child: Text('Sr No.', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Country Code Title', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Country Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Country Code Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                Padding(padding: EdgeInsets.all(12), child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            ),
                            ...countryCodes.asMap().entries.map((entry) {
                              final index = entry.key;
                              final code = entry.value;
                              return TableRow(
                                children: [
                                  Padding(padding: const EdgeInsets.all(12), child: Text('${index + 1}')),
                                  Padding(padding: const EdgeInsets.all(12), child: Text(code.code)),
                                  Padding(padding: const EdgeInsets.all(12), child: Text(code.countryName)),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: UnconstrainedBox(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: code.status == 'Publish' ? Colors.green : Colors.grey,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          code.status,
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Wrap(
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(Icons.edit, color: Colors.green, size: 18),
                                          onPressed: () {},
                                        ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                          onPressed: () {
                                            ref.read(countryCodeProvider.notifier).removeCountryCode(code.id);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
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
