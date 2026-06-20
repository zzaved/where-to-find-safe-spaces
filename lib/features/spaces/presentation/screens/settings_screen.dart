import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';

/// App settings, methodology explanation and a notification self-test.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceId = ref.watch(deviceServiceProvider).deviceId;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Como classificamos'),
          const _InfoCard(
            text:
                'Cada local é avaliado a partir de duas fontes: (1) palavras-chave '
                'positivas e negativas nas avaliações do Google e (2) uma '
                'verificação de reputação na web feita pelo Claude (Anthropic) '
                'com busca na web, que procura notícias e polêmicas sobre '
                'acolhimento à comunidade LGBTQIA+. Disso sai o Safe Score de 0 a 100.',
          ),
          const SizedBox(height: 8),
          _LegendRow(color: AppColors.safe, label: 'Safe space — 65 a 100'),
          _LegendRow(color: AppColors.neutral, label: 'Sinais mistos — 41 a 64'),
          _LegendRow(color: AppColors.notSafe, label: 'Não seguro — 0 a 40'),
          const SizedBox(height: 24),
          const _SectionLabel('Notificações'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_active_rounded,
                  color: AppColors.primary),
              title: const Text('Testar notificação local'),
              subtitle: const Text('Envia uma notificação de exemplo'),
              onTap: () async {
                final service = ref.read(notificationServiceProvider);
                await service.init();
                await service.requestPermission();
                await service.showDiscoverySummary(
                  total: 12,
                  safeCount: 7,
                  unsafeCount: 2,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notificação enviada!')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Sobre'),
          const _InfoCard(
            text:
                'Safe Spaces ajuda pessoas LGBTQIA+ a encontrar locais acolhedores '
                'por proximidade. Projeto acadêmico — Atividade Ponderada 4.',
          ),
          const SizedBox(height: 12),
          Text(
            'ID do dispositivo: $deviceId',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
