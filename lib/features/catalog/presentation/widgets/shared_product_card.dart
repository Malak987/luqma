import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_sizes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../favorites/presentation/widgets/favorite_toggle_button.dart';

/// A visual product row shared by catalog and favorite projections. It does
/// not manufacture a MenuItem or infer configuration from incomplete data.
class SharedProductCard extends StatelessWidget {
  const SharedProductCard({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.placeholder,
    required this.price,
    this.metadata,
    this.action,
    this.onTap,
    super.key,
  });

  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final Widget placeholder;
  final Widget price;
  final Widget? metadata;
  final Widget? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final artwork = ClipRRect(
      borderRadius: AppRadius.largeRadius,
      child: Stack(fit: StackFit.expand, children: [
        AppNetworkImage(url: imageUrl, placeholder: placeholder),
        PositionedDirectional(
          top: AppSpacing.xs,
          end: AppSpacing.xs,
          child: FavoriteToggleButton(
            menuItemId: id,
            size: 48,
            backgroundColor: colors.surface.withValues(alpha: .92),
          ),
        ),
      ]),
    );
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
              color: colors.headingText, fontWeight: FontWeight.w800)),
      if (description.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xxs),
        Text(description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                theme.textTheme.bodySmall?.copyWith(color: colors.mutedText)),
      ],
      if (metadata != null) ...[
        const SizedBox(height: AppSpacing.xxs),
        metadata!
      ],
      const SizedBox(height: AppSpacing.sm),
      LayoutBuilder(builder: (context, constraints) {
        if (action == null) return price;
        if (constraints.maxWidth < 190 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.35) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                price,
                const SizedBox(height: AppSpacing.xs),
                action!
              ]);
        }
        return Row(children: [
          Expanded(child: price),
          const SizedBox(width: AppSpacing.xs),
          action!
        ]);
      }),
    ]);
    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlargeRadius,
          side: BorderSide(color: colors.border)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth < AppSizes.compactWidth - AppSpacing.xl ||
                MediaQuery.textScalerOf(context).scale(1) > 1.35) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(aspectRatio: 2, child: artwork),
                    const SizedBox(height: AppSpacing.sm),
                    content,
                  ]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox.square(dimension: 112, child: artwork),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: content),
            ]);
          }),
        ),
      ),
    );
  }
}
