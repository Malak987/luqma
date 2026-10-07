import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/password_rules.dart';

/// Live password checklist shown under a "choose a password" field.
///
/// A small panel with a segmented strength bar and the five rules laid out on
/// a tidy two-column grid. Each rule turns green with a check as soon as it is
/// met. It listens to the controller directly, so typing rebuilds only this
/// panel and never the page.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({required this.controller, super.key});

  static const Color _successLight = Color(0xFF2E7D32);
  static const Color _successDark = Color(0xFF81C784);

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final success =
        theme.brightness == Brightness.dark ? _successDark : _successLight;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final rules = PasswordRules.of(value.text);
        // Ordered so each grid row reads as a natural pair.
        final items = <_Rule>[
          _Rule(l10n.auth.passwordRuleLength, rules.hasMinLength),
          _Rule(l10n.auth.passwordRuleDigit, rules.hasDigit),
          _Rule(l10n.auth.passwordRuleUppercase, rules.hasUppercase),
          _Rule(l10n.auth.passwordRuleLowercase, rules.hasLowercase),
          _Rule(l10n.auth.passwordRuleSymbol, rules.hasSymbol),
        ];
        final metCount = items.where((item) => item.met).length;
        final barColor = metCount == items.length ? success : colors.accent;

        return Semantics(
          container: true,
          label: l10n.auth.passwordRequirementsTitle,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: AppRadius.mediumRadius,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        l10n.auth.passwordRequirementsTitle,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.bodyText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$metCount/${items.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                _StrengthBar(
                  filled: metCount,
                  total: items.length,
                  activeColor: barColor,
                  trackColor: colors.border,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < items.length; i += 2) ...<Widget>[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _RuleRow(
                          rule: items[i],
                          successColor: success,
                          mutedColor: colors.mutedText,
                          metLabel: l10n.auth.passwordRuleMet,
                          notMetLabel: l10n.auth.passwordRuleNotMet,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: i + 1 < items.length
                            ? _RuleRow(
                                rule: items[i + 1],
                                successColor: success,
                                mutedColor: colors.mutedText,
                                metLabel: l10n.auth.passwordRuleMet,
                                notMetLabel: l10n.auth.passwordRuleNotMet,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Rule {
  const _Rule(this.label, this.met);

  final String label;
  final bool met;
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({
    required this.filled,
    required this.total,
    required this.activeColor,
    required this.trackColor,
  });

  final int filled;
  final int total;
  final Color activeColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < total; i++) ...<Widget>[
          if (i > 0) const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? activeColor : trackColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({
    required this.rule,
    required this.successColor,
    required this.mutedColor,
    required this.metLabel,
    required this.notMetLabel,
  });

  final _Rule rule;
  final Color successColor;
  final Color mutedColor;
  final String metLabel;
  final String notMetLabel;

  @override
  Widget build(BuildContext context) {
    final color = rule.met ? successColor : mutedColor;

    return Semantics(
      label: '${rule.label}, ${rule.met ? metLabel : notMetLabel}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                rule.met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                key: ValueKey<bool>(rule.met),
                size: 16,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              rule.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontSize: 12,
                    fontWeight: rule.met ? FontWeight.w600 : FontWeight.w400,
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
