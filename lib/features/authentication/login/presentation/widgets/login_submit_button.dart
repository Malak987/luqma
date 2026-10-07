import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/primary_auth_button.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

/// Rebuilds only when the loading flag flips, not on every cubit emission.
class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.isLoading,
      builder: (context, isLoading) {
        return PrimaryAuthButton(
          text: l10n.auth.login,
          loading: isLoading,
          enabled: !isLoading,
          semanticLabel: isLoading ? l10n.auth.loginLoading : l10n.auth.login,
          onPressed: onPressed,
        );
      },
    );
  }
}
