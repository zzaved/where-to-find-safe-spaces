import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/space_card.dart';
import 'space_detail_screen.dart';

/// Lists the places this device has saved, persisted in Postgres.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favorites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Erro ao carregar favoritos: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
        data: (spaces) {
          if (spaces.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 56, color: AppColors.textSecondary),
                    SizedBox(height: 16),
                    Text(
                      'Você ainda não salvou nenhum local',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Toque no coração de um local para guardá-lo aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(favoritesControllerProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: spaces.length,
              itemBuilder: (context, index) {
                final space = spaces[index];
                return SpaceCard(
                  space: space,
                  isFavorite: true,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SpaceDetailScreen(initialSpace: space),
                    ),
                  ),
                  onToggleFavorite: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .toggle(space),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
