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
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../../../shared/widgets/primary_auth_button.dart';
import '../cubit/email_verification_cubit.dart';
import '../cubit/email_verification_state.dart';

/// Identifies the resend action so tests can target it without matching
/// composed, localized button copy.
@visibleForTesting
const Key kEmailVerificationResendButtonKey =
    Key('email-verification-resend-button');

/// Email confirmation screen.
///
/// [email] is normally supplied by the Register flow, which already triggered
/// the first OTP. When it is null — for example on a deep link — the user is
/// asked for it.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, this.email});

  final String? email;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  static const int _otpLength = 6;
  static final RegExp _digitsOnly = RegExp(r'^[0-9]{6}$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();

  /// Mirrors `EmailVerificationCubit.resendCooldownRemaining` so the countdown
  /// label repaints without the cubit emitting a state every second.
  late int _cooldownRemaining;
  Timer? _cooldownTicker;

  /// True when the email arrived from Register and must not be edited.
  bool get _emailIsFixed => (widget.email ?? '').trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email?.trim() ?? '');
    _cooldownRemaining = _cubit.resendCooldownRemaining;
    _startCooldownTicker();
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  EmailVerificationCubit get _cubit => context.read<EmailVerificationCubit>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;

    return BlocListener<EmailVerificationCubit, EmailVerificationState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.failedAction != current.failedAction ||
          previous.isResending != current.isResending,
      listener: (context, state) {
        _onStateChanged(context, l10n, state);
      },
      child: AuthScaffold(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppLogo(semanticLabel: l10n.common.brandName),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.auth.verifyEmailTitle,
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _emailIsFixed
                    ? '${l10n.auth.sentCodeTo} ${widget.email!.trim()}'
                    : l10n.auth.sentCodeTo,
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
                  semanticLabel: l10n.auth.verificationEmailLabel,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.center,
                  validator: (value) =>
                      l10n.validationMessage(Validators.email(value)),
                  onSubmitted: (_) => _otpFocusNode.requestFocus(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppTextField(
                controller: _otpController,
                hintText: l10n.auth.otp,
                semanticLabel: l10n.auth.otpLabel,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                focusNode: _otpFocusNode,
                maxLength: _otpLength,
                validator: _otpError,
                onSubmitted: (_) => _submitConfirm(),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocSelector<EmailVerificationCubit, EmailVerificationState,
                  bool>(
                selector: (state) => state.isConfirming,
                builder: (context, isConfirming) {
                  return PrimaryAuthButton(
                    text: l10n.auth.confirm,
                    loading: isConfirming,
                    enabled: !isConfirming,
                    semanticLabel: isConfirming
                        ? l10n.auth.confirmLoading
                        : l10n.auth.confirm,
                    onPressed: _submitConfirm,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _ResendButton(
                key: kEmailVerificationResendButtonKey,
                remaining: _cooldownRemaining,
                onResend: _submitResend,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _backToLogin,
                child: Text(l10n.auth.backToLoginFromVerification),
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
    EmailVerificationState state,
  ) {
    if (state.hasFailure) {
      _showMessage(context, _failureMessage(l10n, state));
      return;
    }

    if (state.isResending) {
      return;
    }

    if (state.isConfirmed) {
      _showMessage(context, state.message ?? l10n.auth.verificationSuccess);
      // Confirming an email issues no token, so there is no session to
      // continue with: the user signs in next.
      _backToLogin();
      return;
    }

    if (state.lastAction == EmailVerificationAction.resend &&
        state.message != null) {
      _showMessage(context, state.message!);
    }
  }

  void _submitConfirm() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<EmailVerificationCubit>().confirm(
          email: _emailController.text,
          otp: _otpController.text,
        );
  }

  void _submitResend() {
    final cubit = context.read<EmailVerificationCubit>();
    if (!cubit.canResend) {
      return;
    }
    if (!_emailIsFixed && Validators.email(_emailController.text) != null) {
      _formKey.currentState?.validate();
      return;
    }

    cubit.resend(email: _emailController.text);
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
    // The ticker runs for the lifetime of the page rather than cancelling at
    // zero: a successful resend restarts the cooldown, and the label has to
    // pick that up. It only calls `setState` when the displayed number changes,
    // so an idle screen schedules no frames.
    _cooldownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _cooldownTicker?.cancel();
        return;
      }
      final remaining = _cubit.resendCooldownRemaining;
      if (remaining != _cooldownRemaining) {
        setState(() => _cooldownRemaining = remaining);
      }
    });
  }

  String? _otpError(String? value) {
    final l10n = AppLocalizations.of(context);
    final input = value ?? '';
    if (input.isEmpty) {
      return l10n.auth.validationOtpRequired;
    }
    // The backend OTP is numeric. Rejecting anything else here avoids a round
    // trip that would only return the generic invalid-code message.
    if (input.length != _otpLength || !_digitsOnly.hasMatch(input)) {
      return l10n.auth.validationOtpLength;
    }
    return null;
  }

  /// The backend already returns a localised, human-readable reason
  /// ("رمز التحقق غير صحيح أو منتهي الصلاحية"), so it is surfaced verbatim; the
  /// mapped code only supplies the fallback.
  String _failureMessage(
    AppLocalizations l10n,
    EmailVerificationState state,
  ) {
    final backendMessage = state.failure?.debugMessage;

    if (backendMessage == null || backendMessage.trim().isEmpty) {
      return _fallbackFailureMessage(l10n, state);
    }

    // Only show text the backend actually produced for this feature. Generic
    // internal messages are replaced by the localized fallback.
    switch (state.failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.validation:
        return backendMessage;
      case FailureCode.invalidCredentials:
      case FailureCode.unknown:
      case null:
        return _fallbackFailureMessage(l10n, state);
    }
  }

  String _fallbackFailureMessage(
    AppLocalizations l10n,
    EmailVerificationState state,
  ) {
    switch (state.failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.validation:
        return state.failedAction == EmailVerificationAction.resend
            ? l10n.auth.resendOtpFailed
            : l10n.auth.verificationFailed;
      case FailureCode.invalidCredentials:
      case FailureCode.unknown:
      case null:
        return l10n.auth.unknownError;
    }
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({
    required this.remaining,
    required this.onResend,
    super.key,
  });

  final int remaining;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCoolingDown = remaining > 0;

    return BlocSelector<EmailVerificationCubit, EmailVerificationState, bool>(
      selector: (state) => state.isResending,
      builder: (context, isResending) {
        return AppButton(
          text: isCoolingDown
              ? l10n.auth.resendIn(remaining)
              : '${l10n.auth.didNotReceiveCode} ${l10n.auth.resendOtp}',
          width: double.infinity,
          loading: isResending,
          enabled: !isResending && !isCoolingDown,
          semanticLabel: l10n.auth.resendOtp,
          onPressed: onResend,
        );
      },
    );
  }
}
