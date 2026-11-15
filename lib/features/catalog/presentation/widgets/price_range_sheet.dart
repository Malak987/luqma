import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/queries/store_filters.dart';

/// Bottom sheet that picks the upper bound of a price band on a stepped track.
///
/// The lower bound is the first stop; moving the thumb moves the upper bound.
/// Returns the chosen [StorePriceRange] when applied, or null when dismissed.
class PriceRangeSheet extends StatefulWidget {
  const PriceRangeSheet({this.initial, super.key});

  /// The stops the track snaps to.
  static const List<int> stops = <int>[99, 500, 1000, 2500, 5000, 10000];

  final StorePriceRange? initial;

  static Future<StorePriceRange?> show(
    BuildContext context, {
    StorePriceRange? initial,
  }) {
    return showModalBottomSheet<StorePriceRange>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PriceRangeSheet(initial: initial),
    );
  }

  @override
  State<PriceRangeSheet> createState() => _PriceRangeSheetState();
}

class _PriceRangeSheetState extends State<PriceRangeSheet> {
  late int _index;

  @override
  void initState() {
    super.initState();
    final max = widget.initial?.max;
    var index = PriceRangeSheet.stops.length - 1;
    if (max != null) {
      // Snap a stored value to the nearest stop.
      var best = 0;
      for (var i = 0; i < PriceRangeSheet.stops.length; i++) {
        if ((PriceRangeSheet.stops[i] - max).abs() <
            (PriceRangeSheet.stops[best] - max).abs()) {
          best = i;
        }
      }
      index = best;
    }
    _index = index;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final isDark = theme.brightness == Brightness.dark;
    final copy = AppLocalizations.of(context).catalog;
    final stops = PriceRangeSheet.stops;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.divider,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _RoundIconButton(
                    key: const Key('price_range_close'),
                    icon: Icons.close_rounded,
                    tooltip: copy.close,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  Text(
                    copy.setPriceRange,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: isDark ? colors.accent : colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Summary of the chosen band.
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.elevatedSurface
                      : colors.background.withValues(alpha: .7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? colors.accent.withValues(alpha: .45)
                        : colors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 18, color: colors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      isDark ? copy.currentRange : copy.selectedBudget,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.mutedText),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Container(
                        key: const Key('price_range_summary'),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.transparent : colors.surface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          copy.priceRangeText(stops.first, stops[_index]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isDark ? colors.accent : colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _SteppedTrack(
                stops: stops,
                index: _index,
                colors: colors,
                labelFor: copy.grouped,
                currency: copy.currency,
                onChanged: (value) => setState(() => _index = value),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                key: const Key('price_range_apply'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: () => Navigator.of(context).pop(
                  StorePriceRange(min: stops.first, max: stops[_index]),
                ),
                icon: Icon(Icons.check_rounded, color: colors.accent),
                label: Text(
                  copy.applyPriceRange,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? colors.elevatedSurface
            : colors.background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, size: 20, color: colors.headingText),
          ),
        ),
      ),
    );
  }
}

/// Dots joined by segments; everything up to the thumb is filled. Tapping or
/// dragging anywhere on the track snaps to the nearest stop. Direction aware:
/// the first stop sits at the reading start (right in Arabic).
class _SteppedTrack extends StatelessWidget {
  const _SteppedTrack({
    required this.stops,
    required this.index,
    required this.colors,
    required this.labelFor,
    required this.currency,
    required this.onChanged,
  });

  final List<int> stops;
  final int index;
  final AppSemanticColors colors;
  final String Function(num) labelFor;
  final String currency;
  final ValueChanged<int> onChanged;

  static const double _thumb = 26;
  static const double _dot = 14;

  /// Half the label box minus half a dot, so dots sit above their labels.
  static const double _pad = 15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final filled = colors.primary;
    final idle = isDark ? colors.divider : colors.border;

    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      void pick(double dx) {
        final fraction = ((dx - _pad) / (width - _pad * 2)).clamp(0.0, 1.0);
        final ordered = rtl ? 1 - fraction : fraction;
        onChanged((ordered * (stops.length - 1)).round());
      }

      return Semantics(
        slider: true,
        value: labelFor(stops[index]),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => pick(details.localPosition.dx),
          onHorizontalDragUpdate: (details) => pick(details.localPosition.dx),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _pad),
                  child: Row(
                  children: [
                    for (var i = 0; i < stops.length; i++) ...[
                      _Dot(
                        size: i == index ? _thumb : _dot,
                        color: i <= index ? filled : idle,
                        ring: i == index ? colors.accent : null,
                      ),
                      if (i < stops.length - 1)
                        Expanded(
                          child: Container(
                            height: 4,
                            color: i < index ? filled : idle,
                          ),
                        ),
                    ],
                  ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < stops.length; i++)
                    SizedBox(
                      width: 44,
                      child: Column(
                        children: [
                          Text(
                            labelFor(stops[i]),
                            maxLines: 1,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: i == index
                                  ? (isDark ? colors.accent : colors.primary)
                                  : colors.mutedText,
                              fontWeight:
                                  i == index ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                          Text(
                            currency,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.mutedText.withValues(alpha: .8),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color, this.ring});

  final double size;
  final Color color;
  final Color? ring;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: ring == null ? null : Border.all(color: ring!, width: 3),
          boxShadow: ring == null
              ? null
              : [
                  BoxShadow(
                    color: color.withValues(alpha: .35),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
      );
}
