import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/entities/menu_item.dart';
import 'menu_item_card.dart';

/// The choices made in the product sheet. Product options and additional
/// addons deliberately retain separate ID namespaces.
class MenuItemSelection extends Equatable {
  MenuItemSelection({
    this.optionId,
    Set<String> addonIds = const {},
    this.quantity = 1,
  }) : addonIds = Set<String>.unmodifiable(addonIds);

  final String? optionId;
  final Set<String> addonIds;
  final int quantity;

  @override
  List<Object?> get props => [optionId, addonIds, quantity];
}

/// Product sheet: photo on top, details and choices below, quantity and the
/// add button pinned at the bottom. Light and dark share one layout; only the
/// semantic color tokens change.
class MenuItemDetailsSheet extends StatefulWidget {
  const MenuItemDetailsSheet({
    required this.item,
    this.initialSelection,
    super.key,
  });
  final MenuItem item;
  final MenuItemSelection? initialSelection;
  @override
  State<MenuItemDetailsSheet> createState() => _MenuItemDetailsSheetState();
}

class _MenuItemDetailsSheetState extends State<MenuItemDetailsSheet> {
  static const double _heroHeight = 300;
  static const double _bodyOverlap = 28;

  String? _optionId;
  final Set<String> _addonIds = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    final selected = widget.initialSelection;
    // Drop selections no longer present in this actual product snapshot.
    if (widget.item.options.any((option) => option.id == selected?.optionId)) {
      _optionId = selected?.optionId;
    }
    _addonIds.addAll(
      widget.item.addons
          .map((addon) => addon.id)
          .where((id) => selected?.addonIds.contains(id) ?? false),
    );
    final initialQuantity = selected?.quantity ?? 1;
    _quantity = initialQuantity > 0 ? initialQuantity : 1;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final l10n = AppLocalizations.of(context);
    final copy = l10n.catalog;
    final arabic = l10n.locale.languageCode == 'ar';
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = theme.brightness == Brightness.dark;
    final priceColor = isDark ? colors.accent : colors.primary;
    final name = arabic ? item.nameAr : item.nameEn;
    final altName = arabic ? item.nameEn : item.nameAr;
    final description = arabic ? item.descriptionAr : item.descriptionEn;
    final sheetHeight = MediaQuery.sizeOf(context).height * .94;

    return SizedBox(
      height: sheetHeight,
      child: Stack(
        children: [
          // Photo.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppNetworkImage(
                  url: item.imageUrl,
                  placeholder: const MenuArtworkPlaceholder(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: [Color(0x80000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body sheet overlapping the photo.
          Positioned.fill(
            top: _heroHeight - _bodyOverlap,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.divider,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      key: const PageStorageKey('menu_details_scroll'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.headingText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (altName.isNotEmpty &&
                            altName.toLowerCase() != name.toLowerCase())
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xxs),
                            child: Text(
                              altName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.mutedText,
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              copy.money(item.price),
                              semanticsLabel:
                                  '${copy.price}: ${copy.money(item.price)}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: priceColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item.hasSale) ...[
                              Text(
                                copy.money(item.compareAtPrice),
                                semanticsLabel:
                                    '${copy.previousPrice}: ${copy.money(item.compareAtPrice)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.mutedText,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              _Pill(
                                text: copy.discountPercent(
                                  item.discountPercent,
                                ),
                                background: colors.primary,
                                foreground: colors.onPrimary,
                              ),
                            ],
                          ],
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _ExpandableText(text: description),
                        ],
                        if (item.isSoldByWeight || item.weight != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          MenuItemWeight(item: item),
                        ],
                        if (item.options.isNotEmpty) ...[
                          const _SectionDivider(),
                          _SectionHeader(
                            title: copy.options,
                            subtitle: copy.chooseOne,
                          ),
                          for (final option in item.options)
                            _ChoiceCard(
                              key: ValueKey('menu_option_${option.id}'),
                              label: arabic ? option.nameAr : option.nameEn,
                              priceText: option.price == 0
                                  ? copy.free
                                  : copy.money(option.price),
                              isFree: option.price == 0,
                              selected: _optionId == option.id,
                              multi: false,
                              onTap: () =>
                                  setState(() => _optionId = option.id),
                            ),
                        ],
                        if (item.addons.isNotEmpty) ...[
                          const _SectionDivider(),
                          _SectionHeader(
                            title: copy.addons,
                            subtitle: copy.chooseAny,
                            badge: copy.multipleLabel,
                          ),
                          for (final addon in item.addons)
                            _ChoiceCard(
                              key: ValueKey('menu_addon_${addon.id}'),
                              label: arabic ? addon.nameAr : addon.nameEn,
                              imageUrl: addon.imageUrl,
                              priceText: addon.price == 0
                                  ? copy.free
                                  : copy.money(addon.price),
                              isFree: addon.price == 0,
                              selected: _addonIds.contains(addon.id),
                              multi: true,
                              onTap: () => setState(() {
                                if (!_addonIds.add(addon.id)) {
                                  _addonIds.remove(addon.id);
                                }
                              }),
                            ),
                        ],
                        if (item.options.isEmpty && item.addons.isEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            copy.noCustomizations,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Pinned quantity + add button.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(top: BorderSide(color: colors.divider)),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            _QuantityStepper(
                              quantity: _quantity,
                              onChanged: (value) =>
                                  setState(() => _quantity = value),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: FilledButton(
                                key: const Key('menu_add_to_cart'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.primary,
                                  foregroundColor: colors.onPrimary,
                                  minimumSize: const Size.fromHeight(54),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                // Returns only documented cart selections. The
                                // Cart service supplies the authoritative price.
                                onPressed: () => Navigator.of(context).pop(
                                  MenuItemSelection(
                                    optionId: _optionId,
                                    addonIds: _addonIds,
                                    quantity: _quantity,
                                  ),
                                ),
                                child: Text(
                                  copy.addToCart,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Close button floats over the photo.
          PositionedDirectional(
            top: AppSpacing.sm,
            start: AppSpacing.md,
            child: Material(
              color: Colors.black.withValues(alpha: .45),
              shape: const CircleBorder(),
              child: IconButton(
                key: const Key('menu_details_close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Divider(height: 1, color: colors.divider),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            _Pill(
              text: badge!,
              background: colors.accent.withValues(alpha: .18),
              foreground: colors.link,
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// A tappable card with a radio (single choice) or checkbox (multiple).
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.priceText,
    required this.isFree,
    required this.selected,
    required this.multi,
    required this.onTap,
    this.imageUrl,
    super.key,
  });

  final String label;
  final String priceText;
  final bool isFree;
  final bool selected;
  final bool multi;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    const green = Color(0xFF1E9E63);

    final indicator = multi
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: selected ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: selected ? colors.primary : colors.divider,
                width: 1.6,
              ),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: 16, color: colors.onPrimary)
                : null,
          )
        : Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? colors.primary : colors.divider,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $priceText',
        excludeSemantics: true,
        child: Material(
          color: selected
              ? colors.primary.withValues(alpha: .07)
              : colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected
                  ? colors.primary.withValues(alpha: .55)
                  : colors.border,
            ),
          ),
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  if (imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox.square(
                        dimension: 44,
                        child: AppNetworkImage(
                          url: imageUrl,
                          placeholder: const MenuArtworkPlaceholder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isFree)
                    _Pill(
                      text: priceText,
                      background: green.withValues(alpha: .14),
                      foreground: green,
                    )
                  else
                    Text(
                      priceText,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  indicator,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText({required this.text});
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const int _collapsedLines = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final copy = AppLocalizations.of(context).catalog;
    final style = theme.textTheme.bodyMedium?.copyWith(
      color: colors.mutedText,
      height: 1.6,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : _collapsedLines,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
            if (overflows)
              GestureDetector(
                key: const Key('menu_read_more'),
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xxs),
                  child: Text(
                    _expanded ? copy.readLess : copy.readMore,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.link,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final l10n = AppLocalizations.of(context);

    Widget button(
      IconData icon,
      String tooltip,
      VoidCallback? onTap, {
      required bool filled,
    }) => Tooltip(
      message: tooltip,
      child: Material(
        color: filled ? colors.primary : colors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 38,
            child: Icon(
              icon,
              size: 20,
              color: onTap == null
                  ? colors.mutedText.withValues(alpha: .4)
                  : filled
                  ? colors.onPrimary
                  : colors.headingText,
            ),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? colors.elevatedSurface
            : colors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reading order: minus, number, plus (plus ends up on the left in RTL,
          // as in the design).
          button(
            Icons.remove_rounded,
            l10n.cart.decrease,
            quantity <= 1 ? null : () => onChanged(quantity - 1),
            filled: false,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 32),
            child: Text(
              l10n.catalog.number(quantity),
              key: const Key('menu_quantity'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colors.headingText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          button(
            Icons.add_rounded,
            l10n.cart.increase,
            () => onChanged(quantity + 1),
            filled: true,
          ),
        ],
      ),
    );
  }
}
