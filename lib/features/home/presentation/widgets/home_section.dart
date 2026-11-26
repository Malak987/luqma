import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_section_feedback.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.seeAllLabel,
    this.onSeeAll,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? seeAllLabel;
  final VoidCallback? onSeeAll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.headingText,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.mutedText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onSeeAll != null && seeAllLabel != null)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSeeAll,
                  borderRadius: AppRadius.pillRadius,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: AppSpacing.sm,
                        end: AppSpacing.xs,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            seeAllLabel!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.link,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Icon(
                            Directionality.of(context) == TextDirection.rtl
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: 18,
                            color: colors.link,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class HomeSectionPlaceholder extends StatelessWidget {
  const HomeSectionPlaceholder({
    required this.icon,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) =>
      AppSectionFeedback(icon: icon, message: message, action: action);
}
