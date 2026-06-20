import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_screen.dart';

/// First-run screen: explains the value, primes notification permission and
/// hands off to the home screen (which requests GPS access).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const _PrideMark(),
              const SizedBox(height: 28),
              const Text(
                'Encontre espaços\nseguros perto de você',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Mapeamos locais próximos e analisamos avaliações e a reputação '
                'na web para indicar quais são acolhedores para a comunidade '
                'LGBTQIA+ — e quais merecem atenção.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              const _Bullet(
                icon: Icons.near_me_rounded,
                text: 'Locais ordenados por proximidade (usa seu GPS).',
              ),
              const _Bullet(
                icon: Icons.verified_rounded,
                text: 'Safe Score com base em avaliações e notícias.',
              ),
              const _Bullet(
                icon: Icons.favorite_rounded,
                text: 'Salve favoritos e compartilhe com quem você confia.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                  ),
                  onPressed: () => _start(context, ref),
                  child: const Text(
                    'Começar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Pediremos acesso à localização e notificações.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final notifications = ref.read(notificationServiceProvider);
    await notifications.init();
    await notifications.requestPermission();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _PrideMark extends StatelessWidget {
  const _PrideMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.prideGradient,
        ),
      ),
      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 34),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
