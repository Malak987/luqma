import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import 'store_status_badge.dart';

/// Restaurant/store card: a large photo with the live status on it, then the
/// name, its main category and address. Closed stores are shown in grayscale.
///
/// It renders only fields the API really returns (no rating, delivery time or
/// distance), and receives display values instead of data dependencies.
class StoreCard extends StatelessWidget {
  const StoreCard({
    required this.name,
    required this.isOpenNow,
    required this.onTap,
    this.imageUrl,
    this.address,
    this.categoryName,
    super.key,
  });

  final String name;
  final bool isOpenNow;
  final VoidCallback onTap;
  final String? imageUrl;
  final String? address;
  final String? categoryName;

  static const List<double> _grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final hasAddress = address?.isNotEmpty == true;
    final hasCategory = categoryName?.isNotEmpty == true;

    Widget artwork = AppNetworkImage(
      url: imageUrl,
      placeholder: const StoreArtworkPlaceholder(),
    );
    if (!isOpenNow) {
      artwork = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_grayscale),
        child: artwork,
      );
    }

    return Semantics(
      container: true,
      button: true,
      label: name,
      child: Material(
        color: colors.surface,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: .12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    artwork,
                    // Soft fade so the status pill stays readable on any photo.
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.center,
                          colors: [Color(0x66000000), Color(0x00000000)],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: AppSpacing.sm,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: .94),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: StoreStatusBadge(isOpenNow: isOpenNow),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.bodyText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (hasCategory) ...[
                            const SizedBox(height: AppSpacing.xs),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.background,
                                borderRadius: AppRadius.smallRadius,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xxs),
                                child: Text(
                                  categoryName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelMedium
                                      ?.copyWith(color: colors.mutedText),
                                ),
                              ),
                            ),
                          ],
                          if (hasAddress) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: AppSizes.iconSmall,
                                    color: colors.primary),
                                const SizedBox(width: AppSpacing.xxs),
                                Expanded(
                                  child: Text(
                                    address!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: colors.mutedText),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(
                        dimension: 40,
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 20, color: colors.onPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoreArtworkPlaceholder extends StatelessWidget {
  const StoreArtworkPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return ColoredBox(
        color: colors.elevatedSurface,
        child: Center(
            child: Icon(Icons.restaurant_outlined,
                size: AppSizes.iconLarge, color: colors.mutedText)));
  }
}
