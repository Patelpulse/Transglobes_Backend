import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_provider.dart';
import '../../core/theme/app_theme.dart';

class CmsContentScreen extends ConsumerWidget {
  final String moduleType;
  final String title;
  final IconData icon;

  const CmsContentScreen({
    super.key,
    required this.moduleType,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(cmsContentsProvider(moduleType));

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.topBarBackground,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimaryDark,
            fontWeight: FontWeight.w900,
            fontSize: 34,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(cmsContentsProvider(moduleType)),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => _showEditor(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Content'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: contentsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Container(
                width: 560,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.lineSoft),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 56, color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'No $title added yet',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first content entry from the Add Content button.',
                      style: TextStyle(color: AppTheme.textSecondaryDark),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final value = _normalizeValue(item['value']);
              final entryTitle = value['title'] ?? item['key'] ?? 'Untitled';
              final description = value['description'] ?? value['content'] ?? '';
              final status = value['status'] ?? 'active';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.lineSoft),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entryTitle.toString(),
                            style: const TextStyle(
                              color: AppTheme.textPrimaryDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status.toString().toLowerCase() == 'active'
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            status.toString().toUpperCase(),
                            style: TextStyle(
                              color: status.toString().toLowerCase() == 'active'
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description.toString(),
                      style: const TextStyle(
                        color: AppTheme.textSecondaryDark,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _showEditor(context, ref, existing: item),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _deleteItem(context, ref, item['_id']?.toString()),
                          icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                          label: const Text('Delete', style: TextStyle(color: AppTheme.danger)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to load content: $e',
            style: const TextStyle(color: AppTheme.danger),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context, WidgetRef ref, String? id) async {
    if (id == null || id.isEmpty) return;
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('admin/cms/$id');
      ref.invalidate(cmsContentsProvider(moduleType));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully')),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_dioMessage(e))),
        );
      }
    }
  }

  void _showEditor(BuildContext context, WidgetRef ref, {Map<String, dynamic>? existing}) {
    final value = _normalizeValue(existing?['value']);
    final titleCtrl = TextEditingController(text: value['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: value['description']?.toString() ?? '');
    final statusCtrl = TextEditingController(text: value['status']?.toString() ?? 'active');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add $title' : 'Edit $title'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description/Content'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: statusCtrl.text.toLowerCase() == 'inactive' ? 'inactive' : 'active',
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                ],
                onChanged: (v) => statusCtrl.text = v ?? 'active',
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dio = ref.read(dioProvider);
                final key = existing?['key']?.toString() ??
                    '${moduleType}_${DateTime.now().millisecondsSinceEpoch}';
                await dio.post(
                  'admin/cms',
                  data: {
                    'key': key,
                    'type': moduleType,
                    'value': {
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'status': statusCtrl.text.trim(),
                    },
                  },
                );
                ref.invalidate(cmsContentsProvider(moduleType));
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              } on DioException catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(_dioMessage(e))),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

final cmsContentsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, type) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('admin/cms', queryParameters: {'type': type});
  final data = response.data;
  if (data is Map && data['contents'] is List) {
    return (data['contents'] as List)
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return [];
});

Map<String, dynamic> _normalizeValue(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw == null) return {};
  return {'content': raw.toString()};
}

String _dioMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) return data['message'].toString();
  return e.message ?? 'Request failed';
}
