import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/discovery_state.dart';
import '../controllers/favorites_controller.dart';
import '../widgets/category_chips.dart';
import '../widgets/safety_filter_bar.dart';
import '../widgets/space_card.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'space_detail_screen.dart';

/// The Grindr-style home: nearby places ordered by proximity, with safety
/// filters, category chips and pull-to-refresh.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider).init();
      ref.read(discoveryControllerProvider.notifier).discover();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryControllerProvider);
    final controller = ref.read(discoveryControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _HomeTitle(),
        actions: [
          IconButton(
            tooltip: 'Favoritos',
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () => _open(const FavoritesScreen()),
          ),
          IconButton(
            tooltip: 'Histórico',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => _open(const HistoryScreen()),
          ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => _open(const SettingsScreen()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CategoryChips(
                active: state.category,
                onSelected: controller.setCategory,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SafetyFilterBar(
                active: state.filter,
                refreshing: state.loading,
                onChanged: controller.setFilter,
                onRefresh: () => controller.discover(forceRefresh: true),
              ),
            ),
            Expanded(child: _Body(state: state)),
          ],
        ),
      ),
    );
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }
}

class _HomeTitle extends StatelessWidget {
  const _HomeTitle();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Safe Spaces', style: TextStyle(fontSize: 20)),
        Text(
          'Locais acolhedores perto de você',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});

  final DiscoveryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.loading && state.spaces.isEmpty) {
      return const _StatusMessage(
        icon: Icons.travel_explore_rounded,
        title: 'Procurando locais perto de você…',
        subtitle: 'Analisando avaliações e reputação na web.',
        showSpinner: true,
      );
    }

    if (state.error != null && state.spaces.isEmpty) {
      return _StatusMessage(
        icon: Icons.error_outline_rounded,
        title: 'Não foi possível carregar',
        subtitle: state.error!,
        action: FilledButton.icon(
          onPressed: () =>
              ref.read(discoveryControllerProvider.notifier).discover(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    final spaces = state.visibleSpaces;
    if (spaces.isEmpty) {
      return const _StatusMessage(
        icon: Icons.search_off_rounded,
        title: 'Nenhum local neste filtro',
        subtitle: 'Tente outra categoria ou remova o filtro de segurança.',
      );
    }

    final favoriteIds = ref.watch(favoriteIdsProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(discoveryControllerProvider.notifier).discover(forceRefresh: true),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
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
            isFavorite: favoriteIds.contains(space.id),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SpaceDetailScreen(initialSpace: space),
              ),
            ),
            onToggleFavorite: () =>
                ref.read(favoritesControllerProvider.notifier).toggle(space),
          );
        },
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.showSpinner = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSpinner)
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: CircularProgressIndicator(),
              )
            else
              Icon(icon, size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
