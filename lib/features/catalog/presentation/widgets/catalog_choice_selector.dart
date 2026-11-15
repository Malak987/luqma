import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';

/// Presentation-only choice configuration; no API parsing or business policy.
class CatalogChoice {
  const CatalogChoice({required this.id, required this.label, this.imageUrl});
  final String id;
  final String label;
  final String? imageUrl;
}

class CatalogChoiceSelector extends StatelessWidget {
  const CatalogChoiceSelector(
      {required this.choices,
      required this.allLabel,
      required this.selectedId,
      required this.onSelected,
      super.key});
  final List<CatalogChoice> choices;
  final String allLabel;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return SizedBox(
      height: math.max(60.0, 40 * scale + 20),
      child: ListView.separated(
        key: const PageStorageKey('catalog_choices'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: choices.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final choice = index == 0 ? null : choices[index - 1];
          final selected = choice == null
              ? selectedId == null
              : choice.id.toLowerCase() == selectedId?.toLowerCase();
          return Center(
              child: ChoiceChip(
            key: ValueKey(choice == null
                ? 'catalog_choice_all'
                : 'catalog_choice_${choice.id}'),
            label: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * .65),
              child: Text(choice?.label ?? allLabel,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            avatar: choice == null
                ? const Icon(Icons.apps, size: 18)
                : choice.imageUrl == null
                    ? null
                    : ClipRRect(
                        borderRadius: AppRadius.smallRadius,
                        child: SizedBox.square(
                            dimension: 24,
                            child: AppNetworkImage(
                              url: choice.imageUrl,
                              placeholder:
                                  const Icon(Icons.restaurant_menu, size: 18),
                            )),
                      ),
            selected: selected,
            onSelected: (_) => onSelected(choice?.id),
            showCheckmark: false,
            selectedColor: colors.primary,
            backgroundColor: colors.surface,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? colors.onPrimary : colors.bodyText),
            side: BorderSide(color: selected ? colors.primary : colors.border),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ));
        },
      ),
    );
  }
}
