import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_divider.dart';
import '../../../../../core/widgets/brand_icon.dart';
import '../../../../../core/widgets/social_login_button.dart';

/// "Or continue with" divider plus the Apple / Facebook / Google row.
class LoginSocialSection extends StatelessWidget {
  const LoginSocialSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;

    void notify(String message) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppLabeledDivider(label: l10n.auth.continueWith),
        const SizedBox(height: AppSpacing.xl),
        SocialLoginRow(
          providers: <SocialLoginConfig>[
            SocialLoginConfig(
              provider: SocialProvider.apple,
              tooltip: l10n.auth.appleLogin,
              iconColor: colors.bodyText,
              onPressed: () => notify(l10n.auth.appleLogin),
            ),
            SocialLoginConfig(
              provider: SocialProvider.facebook,
              tooltip: l10n.auth.facebookLogin,
              iconColor: const Color(0xFF1877F2),
              onPressed: () => notify(l10n.auth.facebookLogin),
            ),
            SocialLoginConfig(
              provider: SocialProvider.google,
              tooltip: l10n.auth.googleLogin,
              onPressed: () => notify(l10n.auth.googleLogin),
            ),
          ],
        ),
      ],
    );
  }
}
