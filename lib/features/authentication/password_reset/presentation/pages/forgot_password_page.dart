import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/localization/validation_messages.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/primary_auth_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../cubit/password_reset_state.dart';

/// Identifies the submit action so tests can target it without matching
/// composed, localized button copy.
@visibleForTesting
const Key kForgotPasswordSubmitKey = Key('forgot-password-submit');

/// Step one of password reset: collect the email and ask the backend to send a
/// reset code. On success the email is handed to the Reset screen.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.email});

  /// Pre-fills the field when the user arrives from somewhere that already
  /// knows their address. Null is the normal case from the Login screen.
  final String? email;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _emailFocusNode = FocusNode();

  /// Mirrors `PasswordResetCubit.requestCooldownRemaining` so the countdown
  /// label repaints without the cubit emitting a state every second.
  late int _cooldownRemaining;
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.email?.trim() ??
          context.read<PasswordResetCubit>().state.email ??
          '',
    );
    // The cubit is a singleton that outlives this page, so a previous visit may
    // have left a success or failure behind. Clear the UI state, but keep the
    // cooldown so re-entering cannot be used to bypass it.
    context.read<PasswordResetCubit>().resetForNewRequest();
    _cooldownRemaining =
        context.read<PasswordResetCubit>().requestCooldownRemaining;
    _startCooldownTicker();
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return BlocListener<PasswordResetCubit, PasswordResetState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failedAction != current.failedAction,
      listener: (context, state) => _onStateChanged(context, l10n, state),
      child: AuthScaffold(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppLogo(semanticLabel: l10n.common.brandName),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.auth.forgotPasswordTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.auth.forgotPasswordSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppTextField(
                controller: _emailController,
                hintText: l10n.auth.email,
                semanticLabel: l10n.auth.emailLabel,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                focusNode: _emailFocusNode,
                validator: (value) =>
                    l10n.validationMessage(Validators.email(value)),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              // The countdown label depends on `_cooldownRemaining`, which the
              // ticker updates with `setState`. A `BlocSelector` would freeze
              // it, because it only rebuilds its child when the selected value
              // changes, so the whole button is rebuilt with the page instead.
              BlocBuilder<PasswordResetCubit, PasswordResetState>(
                builder: (context, state) {
                  final isRequesting = state.isRequesting;
                  final coolingDown = _cooldownRemaining > 0;
                  return PrimaryAuthButton(
                    key: kForgotPasswordSubmitKey,
                    text: coolingDown
                        ? l10n.auth.resendIn(_cooldownRemaining)
                        : l10n.auth.sendResetCode,
                    loading: isRequesting,
                    // Blocked during the cooldown: the backend applies no
                    // throttling, so this is the only spam protection.
                    enabled: !isRequesting && !coolingDown,
                    semanticLabel: isRequesting
                        ? l10n.auth.sendResetCodeLoading
                        : l10n.auth.sendResetCode,
                    onPressed: _submit,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _backToLogin,
                child: Text(l10n.auth.backToLoginFromReset),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _onStateChanged(
    BuildContext context,
    AppLocalizations l10n,
    PasswordResetState state,
  ) {
    if (state.isRequesting) {
      return;
    }

    if (state.hasFailure && state.failedAction == PasswordResetAction.request) {
      _showMessage(context, _failureMessage(l10n, state));
      return;
    }

    if (state.isCodeSent && state.lastAction == PasswordResetAction.request) {
      _showMessage(context, state.message ?? l10n.auth.sendResetCode);
      // Hand the address to the Reset screen. Replacing this route keeps the
      // stack at [Login, Reset] so finishing the reset returns to Login.
      AppRouter.replaceWithNamed(
        context,
        AppRoutes.resetPassword,
        arguments: state.email ?? _emailController.text.trim(),
      );
    }
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<PasswordResetCubit>().requestReset(
          email: _emailController.text,
        );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _backToLogin() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    AppRouter.replaceWithNamed(context, AppRoutes.login);
  }

  void _startCooldownTicker() {
    _cooldownTicker?.cancel();
    // Runs for the page's lifetime rather than cancelling at zero, and only
    // calls `setState` when the displayed number changes, so an idle screen
    // schedules no frames.
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _cooldownTicker?.cancel();
        return;
      }
      final remaining =
          context.read<PasswordResetCubit>().requestCooldownRemaining;
      if (remaining != _cooldownRemaining) {
        setState(() => _cooldownRemaining = remaining);
      }
    });
  }

  /// The backend returns a localised, human-readable reason
  /// ("البريد الإلكتروني غير موجود"), so it is surfaced verbatim; the mapped
  /// code only supplies the fallback.
  String _failureMessage(AppLocalizations l10n, PasswordResetState state) {
    final backendMessage = state.failure?.debugMessage;

    switch (state.failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.validation:
        if (backendMessage != null && backendMessage.trim().isNotEmpty) {
          return backendMessage;
        }
        return l10n.auth.forgotPasswordFailed;
      case FailureCode.invalidCredentials:
      case FailureCode.unknown:
      case null:
        return l10n.auth.unknownError;
    }
  }
}
