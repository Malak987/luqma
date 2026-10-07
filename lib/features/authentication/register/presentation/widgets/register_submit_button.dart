import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/app_localizations.dart';
import '../../../shared/widgets/primary_auth_button.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';

/// Rebuilds only when the loading flag flips.
class RegisterSubmitButton extends StatelessWidget {
  const RegisterSubmitButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocSelector<RegisterCubit, RegisterState, bool>(
      selector: (state) => state.isLoading,
      builder: (context, isLoading) {
        return PrimaryAuthButton(
          text: l10n.auth.createAccount,
          loading: isLoading,
          enabled: !isLoading,
          semanticLabel:
              isLoading ? l10n.auth.registerLoading : l10n.auth.createAccount,
          onPressed: onPressed,
        );
      },
    );
  }
}
