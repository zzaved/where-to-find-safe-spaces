import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/place_photo.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/citation.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/safe_space.dart';
import '../controllers/favorites_controller.dart';
import '../controllers/space_detail_controller.dart';
import '../widgets/safety_visuals.dart';

/// Full profile of a place: safety score, web-reputation summary, signals,
/// reviews (linking to their source) and quick actions (share, maps, website).
class SpaceDetailScreen extends ConsumerWidget {
  const SpaceDetailScreen({super.key, required this.initialSpace});

  final SafeSpace initialSpace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(spaceDetailControllerProvider(initialSpace.googlePlaceId));
    // Show cached data immediately; enrich once the deep check completes.
    final space = detail.valueOrNull ?? initialSpace;
    final deepLoading = detail.isLoading;
    final isFavorite = ref.watch(favoriteIdsProvider).contains(space.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _Header(space: space, isFavorite: isFavorite),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScoreCard(space: space),
                  const SizedBox(height: 16),
                  _ReputationCard(space: space, loading: deepLoading),
                  if (space.positiveSignals.isNotEmpty ||
                      space.negativeSignals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SignalsCard(space: space),
                  ],
                  if (space.webCitations.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _CitationsCard(citations: space.webCitations),
                  ],
                  const SizedBox(height: 16),
                  _ActionsRow(space: space),
                  if (space.reviews.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle('Avaliações'),
                    const SizedBox(height: 8),
                    ...space.reviews.map((r) => _ReviewTile(review: r)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.space, required this.isFavorite});

  final SafeSpace space;
  final bool isFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.background,
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isFavorite ? AppColors.notSafe : Colors.white,
          ),
          onPressed: () =>
              ref.read(favoritesControllerProvider.notifier).toggle(space),
        ),
        IconButton(
          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
          onPressed: () => ref.read(shareServiceProvider).shareSpace(space),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          space.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (space.hasPhoto)
              CachedNetworkImage(
                imageUrl: PlacePhoto.url(space.photoName!, width: 1000),
                httpHeaders: PlacePhoto.headers,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceElevated,
                ),
              )
            else
              const ColoredBox(color: AppColors.surfaceElevated),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black45, Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.space});

  final SafeSpace space;

  @override
  Widget build(BuildContext context) {
    final color = safetyColor(space.safetyLabel);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _ScoreRing(score: space.safetyScore, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(safetyIcon(space.safetyLabel), color: color, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        safetyText(space.safetyLabel),
                        style: TextStyle(
                          color: color,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    space.address ?? space.categoryLabel,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (space.googleRating != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${space.googleRating!.toStringAsFixed(1)} '
                          '(${space.googleRatingsTotal})',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        if (space.distanceLabel != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.near_me_rounded,
                              color: AppColors.textSecondary, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            space.distanceLabel!,
                            style:
                                const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text(
            '$score',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ReputationCard extends ConsumerWidget {
  const _ReputationCard({required this.space, required this.loading});

  final SafeSpace space;
  final bool loading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.public_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Reputação na web',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: () => ref
                        .read(spaceDetailControllerProvider(space.googlePlaceId)
                            .notifier)
                        .refreshDeep(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              space.classificationSummary ??
                  (loading
                      ? 'Verificando notícias e avaliações na web…'
                      : 'Sem informações aprofundadas ainda.'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalsCard extends StatelessWidget {
  const _SignalsCard({required this.space});

  final SafeSpace space;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (space.positiveSignals.isNotEmpty) ...[
              _signalGroup('Sinais positivos', space.positiveSignals,
                  AppColors.safe),
            ],
            if (space.positiveSignals.isNotEmpty &&
                space.negativeSignals.isNotEmpty)
              const SizedBox(height: 12),
            if (space.negativeSignals.isNotEmpty)
              _signalGroup('Sinais de atenção', space.negativeSignals,
                  AppColors.notSafe),
          ],
        ),
      ),
    );
  }

  Widget _signalGroup(String title, List<String> signals, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: signals
              .map(
                (s) => Chip(
                  label: Text(s, style: const TextStyle(fontSize: 12)),
                  backgroundColor: color.withValues(alpha: 0.15),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CitationsCard extends StatelessWidget {
  const _CitationsCard({required this.citations});

  final List<Citation> citations;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fontes consultadas',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ...citations.map(
              (c) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.link_rounded,
                    color: AppColors.primary, size: 20),
                title: Text(
                  c.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
                onTap: () => _launch(c.url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  const _ActionsRow({required this.space});

  final SafeSpace space;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (space.googleMapsUri != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launch(space.googleMapsUri!),
              icon: const Icon(Icons.map_rounded, size: 18),
              label: const Text('Mapa'),
            ),
          ),
        if (space.googleMapsUri != null && space.website != null)
          const SizedBox(width: 12),
        if (space.website != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _launch(space.website!),
              icon: const Icon(Icons.language_rounded, size: 18),
              label: const Text('Site'),
            ),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.author,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 2),
                Text(review.rating.toStringAsFixed(1)),
              ],
            ),
            if (review.relativeTime.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  review.relativeTime,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(review.text, style: const TextStyle(height: 1.4)),
            if (review.hasSource) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _launch(review.sourceUri),
                child: const Row(
                  children: [
                    Icon(Icons.open_in_new_rounded,
                        color: AppColors.primary, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Ver avaliação na fonte',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

Future<void> _launch(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
