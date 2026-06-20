import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/place_photo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/place_category.dart';
import '../../domain/entities/safe_space.dart';
import 'safety_badge.dart';
import 'safety_visuals.dart';

/// A proximity tile in the Grindr-style grid: photo, safety badge, distance
/// and a favorite toggle.
class SpaceCard extends StatelessWidget {
  const SpaceCard({
    super.key,
    required this.space,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final SafeSpace space;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            _scrim(),
            _favoriteButton(),
            Positioned(
              top: 8,
              left: 8,
              child: SafetyBadge(
                label: space.safetyLabel,
                score: space.safetyScore,
                compact: true,
              ),
            ),
            _info(context),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    if (space.hasPhoto) {
      return CachedNetworkImage(
        imageUrl: PlacePhoto.url(space.photoName!),
        httpHeaders: PlacePhoto.headers,
        fit: BoxFit.cover,
        placeholder: (_, _) => _fallback(),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceElevated, AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(
          categoryIcon(_category),
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          size: 40,
        ),
      ),
    );
  }

  Widget _scrim() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent, Colors.black87],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
    );
  }

  Widget _favoriteButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: IconButton(
        onPressed: onToggleFavorite,
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFavorite ? AppColors.notSafe : Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Widget _info(BuildContext context) {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            space.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.near_me_rounded,
                  color: Colors.white70, size: 13),
              const SizedBox(width: 3),
              Text(
                space.distanceLabel ?? '—',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (space.googleRating != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star_rounded,
                    color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text(
                  space.googleRating!.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  PlaceCategory get _category {
    final type = space.primaryType ?? '';
    return PlaceCategory.values.firstWhere(
      (c) => type.contains(c.apiValue) && c != PlaceCategory.all,
      orElse: () => PlaceCategory.all,
    );
  }
}
