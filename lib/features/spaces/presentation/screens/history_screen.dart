import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/place_category.dart';

/// Past discovery searches made on this device (read from `search_history`).
final searchHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final deviceId = ref.watch(deviceServiceProvider).deviceId;
  final rows = await client
      .from('search_history')
      .select()
      .eq('device_id', deviceId)
      .order('created_at', ascending: false)
      .limit(40);
  return (rows as List).cast<Map<String, dynamic>>();
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de buscas')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erro: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma busca ainda.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(color: AppColors.border),
            itemBuilder: (context, index) => _HistoryTile(row: rows[index]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final category = PlaceCategory.values.firstWhere(
      (c) => c.apiValue == row['category'],
      orElse: () => PlaceCategory.all,
    );
    final count = row['result_count'] ?? 0;
    final createdAt = DateTime.tryParse(row['created_at']?.toString() ?? '');
    final when = createdAt != null
        ? DateFormat('dd/MM/yyyy • HH:mm').format(createdAt.toLocal())
        : '';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        backgroundColor: AppColors.surfaceElevated,
        child: Icon(Icons.search_rounded, color: AppColors.primary),
      ),
      title: Text('${category.label} • $count locais'),
      subtitle: Text(when,
          style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}
