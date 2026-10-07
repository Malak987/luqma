import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_text_styles.dart';

class AuthFooter extends StatefulWidget {
  const AuthFooter({required this.onRegister, super.key});

  final VoidCallback onRegister;

  @override
  State<AuthFooter> createState() => _AuthFooterState();
}

class _AuthFooterState extends State<AuthFooter> {
  late final TapGestureRecognizer _registerRecognizer;

  @override
  void initState() {
    super.initState();
    _registerRecognizer = TapGestureRecognizer()..onTap = widget.onRegister;
  }

  @override
  void didUpdateWidget(covariant AuthFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _registerRecognizer.onTap = widget.onRegister;
  }

  @override
  void dispose() {
    _registerRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final bodyStyle = AppTextStyles.withArabicFallback(
      fontSize: 12,
      color: colors.mutedText,
      height: 1.4,
    );
    final linkStyle = bodyStyle.copyWith(
      color: colors.link,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      container: true,
      label: '${l10n.auth.dontHaveAccount} ${l10n.auth.registerNow}',
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(text: l10n.auth.dontHaveAccount, style: bodyStyle),
            const TextSpan(text: ' '),
            TextSpan(
              text: l10n.auth.registerNow,
              style: linkStyle,
              recognizer: _registerRecognizer,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
      ),
    );
  }
}
