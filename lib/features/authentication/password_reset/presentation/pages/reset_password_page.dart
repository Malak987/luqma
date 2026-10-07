import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_layout_metrics.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../login/presentation/widgets/auth_logo.dart';
import '../../../login/presentation/widgets/auth_scaffold.dart';
import '../../../login/presentation/widgets/primary_auth_button.dart';
import '../cubit/password_reset_cubit.dart';
import '../cubit/password_reset_state.dart';
import '../utils/password_reset_validators.dart';

/// Identifies the actions so tests can target them without matching composed,
/// localized button copy.
@visibleForTesting
const Key kResetPasswordSubmitKey = Key('reset-password-submit');
@visibleForTesting
const Key kResetPasswordResendKey = Key('reset-password-resend');

/// Step two of password reset: enter the emailed code and a new password.
///
/// [email] is normally handed over by the Forgot screen. When it is missing the
/// cubit's last known address is used, and failing that the user is asked.
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key, this.email});

  final String? email;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _otpFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  late int _cooldownRemaining;
  Timer? _cooldownTicker;

  /// The email is fixed once the Forgot screen handed it over; the user must
  /// not be able to reset a different account's password from this screen.
  bool get _emailIsFixed => _resolvedEmail.trim().isNotEmpty;

  String get _resolvedEmail =>
      widget.email?.trim() ??
      context.read<PasswordResetCubit>().state.email ??
      '';

  @override
  void initState() {
    super.initState();
    final cubit = context.read<PasswordResetCubit>();
    _emailController = TextEditingController(
      text: widget.email?.trim() ?? cubit.state.email ?? '',
    );
    _cooldownRemaining = cubit.requestCooldownRemaining;
    _startCooldownTicker();
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _otpFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final metrics =
        theme.extension<AppLayoutMetrics>() ?? AppLayoutMetrics.light;

    return BlocListener<PasswordResetCubit, PasswordResetState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failedAction != current.failedAction ||
          previous.isResending != current.isResending,
      listener: (context, state) => _onStateChanged(context, l10n, state),
      child: AuthScaffold(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AuthLogo(
                brandName: l10n.common.brandName,
                tagline: l10n.common.brandTagline,
              ),
              SizedBox(height: metrics.authLogoToForm),
              Text(
                l10n.auth.resetPasswordTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _emailIsFixed
                    ? '${l10n.auth.resetCodeSentTo} $_resolvedEmail'
                    : l10n.auth.resetCodeSentTo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.mutedText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (!_emailIsFixed) ...<Widget>[
                AppTextField(
                  controller: _emailController,
                  hintText: l10n.auth.email,
                  semanticLabel: l10n.auth.emailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.center,
                  validator: (value) => _validationMessage(
                    l10n,
                    PasswordResetValidators.email(value),
                  ),
                  onSubmitted: (_) => _otpFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _otpController,
                hintText: l10n.auth.resetOtp,
                semanticLabel: l10n.auth.resetOtpLabel,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.center,
                focusNode: _otpFocusNode,
                maxLength: PasswordResetValidators.otpLength,
                validator: (value) => _validationMessage(
                  l10n,
                  PasswordResetValidators.otp(value),
                ),
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _newPasswordController,
                hintText: l10n.auth.newPassword,
                semanticLabel: l10n.auth.newPasswordLabel,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                textAlign: TextAlign.center,
                focusNode: _passwordFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  PasswordResetValidators.newPassword(value),
                ),
                onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _confirmPasswordController,
                hintText: l10n.auth.confirmNewPassword,
                semanticLabel: l10n.auth.confirmNewPasswordLabel,
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                focusNode: _confirmPasswordFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  PasswordResetValidators.confirmPassword(
                    value,
                    _newPasswordController.text,
                  ),
                ),
                onSubmitted: (_) => _submitReset(),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocSelector<PasswordResetCubit, PasswordResetState, bool>(
                selector: (state) => state.isResetting,
                builder: (context, isResetting) {
                  return PrimaryAuthButton(
                    key: kResetPasswordSubmitKey,
                    text: l10n.auth.resetPasswordAction,
                    loading: isResetting,
                    enabled: !isResetting,
                    semanticLabel: isResetting
                        ? l10n.auth.resetPasswordLoading
                        : l10n.auth.resetPasswordAction,
                    onPressed: _submitReset,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              // Rebuilt with the page, not by a `BlocSelector`: the countdown
              // text comes from `_cooldownRemaining`, which the ticker updates
              // with `setState`, and a selector would leave it stale because it
              // only rebuilds when its selected value changes.
              BlocBuilder<PasswordResetCubit, PasswordResetState>(
                builder: (context, state) {
                  final isResending = state.isResending;
                  final coolingDown = _cooldownRemaining > 0;
                  return AppButton(
                    key: kResetPasswordResendKey,
                    text: coolingDown
                        ? l10n.auth.resendIn(_cooldownRemaining)
                        : '${l10n.auth.didNotReceiveResetCode} '
                            '${l10n.auth.resendResetCode}',
                    width: double.infinity,
                    loading: isResending,
                    enabled: !isResending && !coolingDown,
                    semanticLabel: l10n.auth.resendResetCode,
                    onPressed: _submitResend,
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
    if (state.hasFailure) {
      _showMessage(context, _failureMessage(l10n, state));
      return;
    }

    if (state.isBusy) {
      return;
    }

    if (state.isResetDone) {
      _showMessage(context, state.message ?? l10n.auth.resetPasswordSuccess);
      // Resetting a password issues no token, so the user signs in next.
      // Popping returns to whatever launched this screen; replacing covers the
      // deep-link case where this page is the root of the stack.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        AppRouter.replaceWithNamed(context, AppRoutes.login);
      }
      return;
    }

    if (state.isCodeSent &&
        state.lastAction == PasswordResetAction.resend &&
        state.message != null) {
      _showMessage(context, state.message!);
    }
  }

  void _submitReset() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<PasswordResetCubit>().resetPassword(
          email: _emailController.text,
          otp: _otpController.text,
          newPassword: _newPasswordController.text,
        );
  }

  void _submitResend() {
    final cubit = context.read<PasswordResetCubit>();
    if (!cubit.canRequest) {
      return;
    }
    // Only validate the address when it is editable; otherwise a fixed email
    // that came from the previous screen would block the resend.
    if (!_emailIsFixed &&
        PasswordResetValidators.email(_emailController.text) != null) {
      _formKey.currentState?.validate();
      return;
    }

    // There is no dedicated resend endpoint, so this re-requests the code.
    cubit.resendCode(email: _emailController.text);
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

  String? _validationMessage(
    AppLocalizations l10n,
    PasswordResetValidationErrorKey? error,
  ) {
    switch (error) {
      case PasswordResetValidationErrorKey.requiredField:
        return l10n.common.validationRequired;
      case PasswordResetValidationErrorKey.invalidEmail:
        return l10n.auth.validationEmail;
      case PasswordResetValidationErrorKey.otpInvalid:
        return l10n.auth.validationOtpFormat;
      case PasswordResetValidationErrorKey.passwordTooShort:
        return l10n.auth.validationNewPasswordLength;
      case PasswordResetValidationErrorKey.passwordMissingUppercase:
        return l10n.auth.validationPasswordUppercase;
      case PasswordResetValidationErrorKey.passwordMissingLowercase:
        return l10n.auth.validationPasswordLowercase;
      case PasswordResetValidationErrorKey.passwordMissingDigit:
        return l10n.auth.validationPasswordDigit;
      case PasswordResetValidationErrorKey.passwordMissingSymbol:
        return l10n.auth.validationPasswordSymbol;
      case PasswordResetValidationErrorKey.passwordMismatch:
        return l10n.auth.validationNewPasswordMismatch;
      case null:
        return null;
    }
  }

  /// The backend's Arabic message is the only description of the failure
  /// ("رمز التحقق غير صحيح أو منتهي الصلاحية", or the password-rule text), so it
  /// is surfaced verbatim; the mapped code only supplies the fallback.
  String _failureMessage(AppLocalizations l10n, PasswordResetState state) {
    final backendMessage = state.failure?.debugMessage;
    final isResend = state.failedAction == PasswordResetAction.resend;
    final isRequest = state.failedAction == PasswordResetAction.request;

    switch (state.failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.validation:
        if (backendMessage != null && backendMessage.trim().isNotEmpty) {
          return backendMessage;
        }
        if (isResend || isRequest) {
          return l10n.auth.forgotPasswordFailed;
        }
        return l10n.auth.resetPasswordFailed;
      case FailureCode.invalidCredentials:
      case FailureCode.unknown:
      case null:
        return l10n.auth.unknownError;
    }
  }
}
