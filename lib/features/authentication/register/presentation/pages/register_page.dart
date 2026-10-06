import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_layout_metrics.dart';
import '../../../../../core/theme/app_sizes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../login/presentation/widgets/auth_logo.dart';
import '../../../login/presentation/widgets/auth_password_field.dart';
import '../../../login/presentation/widgets/auth_scaffold.dart';
import '../../../login/presentation/widgets/primary_auth_button.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';
import '../utils/register_validators.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _addressFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final metrics =
        theme.extension<AppLayoutMetrics>() ?? AppLayoutMetrics.light;

    return BlocListener<RegisterCubit, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.isSuccess) {
          _showOutcome(context, state.message ?? l10n.auth.createAccount, true);
        } else if (state.hasFailure) {
          _showOutcome(context, _failureMessage(l10n, state.failure), false);
        }
      },
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
              _RegisterTextField(
                controller: _userNameController,
                hintText: l10n.auth.userName,
                semanticLabel: l10n.auth.userNameLabel,
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: (value) => _validationMessage(
                  l10n,
                  RegisterValidators.username(value),
                ),
                onSubmitted: (_) => _emailFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _RegisterTextField(
                controller: _emailController,
                hintText: l10n.auth.email,
                semanticLabel: l10n.auth.emailLabel,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                focusNode: _emailFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  RegisterValidators.email(value),
                ),
                onSubmitted: (_) => _phoneFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _RegisterTextField(
                controller: _phoneController,
                hintText: l10n.auth.phoneNumber,
                semanticLabel: l10n.auth.phoneNumberLabel,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                focusNode: _phoneFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  RegisterValidators.phoneNumber(value),
                ),
                onSubmitted: (_) => _addressFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              _RegisterTextField(
                controller: _addressController,
                hintText: l10n.auth.address,
                semanticLabel: l10n.auth.addressLabel,
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
                textInputAction: TextInputAction.next,
                focusNode: _addressFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  RegisterValidators.requiredText(value),
                ),
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthPasswordField(
                controller: _passwordController,
                hintText: l10n.auth.password,
                lockTooltip: l10n.auth.password,
                focusNode: _passwordFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  RegisterValidators.strongPassword(value),
                ),
                onSubmitted: (_) => _confirmPasswordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthPasswordField(
                controller: _confirmPasswordController,
                hintText: l10n.auth.confirmPassword,
                lockTooltip: l10n.auth.confirmPasswordLabel,
                focusNode: _confirmPasswordFocusNode,
                validator: (value) => _validationMessage(
                  l10n,
                  RegisterValidators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),
              BlocSelector<RegisterCubit, RegisterState, bool>(
                selector: (state) => state.isLoading,
                builder: (context, isLoading) {
                  return PrimaryAuthButton(
                    text: l10n.auth.createAccount,
                    loading: isLoading,
                    enabled: !isLoading,
                    semanticLabel: isLoading
                        ? l10n.auth.registerLoading
                        : l10n.auth.createAccount,
                    onPressed: _submit,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _backToLogin(context),
                child: Text(l10n.auth.backToLogin),
              ),
              SizedBox(height: MediaQuery.paddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context.read<RegisterCubit>().register(
          userName: _userNameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          phoneNumber: _phoneController.text,
          address: _addressController.text,
        );
  }

  void _showOutcome(BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

    // Registration requires email confirmation, so there is no session to
    // continue with. Return the user to the sign-in screen.
    if (isSuccess) {
      _backToLogin(context);
    }
  }

  void _backToLogin(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    AppRouter.replaceWithNamed(context, AppRoutes.login);
  }

  String? _validationMessage(
    AppLocalizations l10n,
    RegisterValidationErrorKey? error,
  ) {
    switch (error) {
      case RegisterValidationErrorKey.requiredField:
        return l10n.common.validationRequired;
      case RegisterValidationErrorKey.passwordTooShort:
        return l10n.common.validationPasswordLength;
      case RegisterValidationErrorKey.invalidUsername:
        return l10n.auth.validationUsername;
      case RegisterValidationErrorKey.invalidEmail:
        return l10n.auth.validationEmail;
      case RegisterValidationErrorKey.passwordMissingUppercase:
        return l10n.auth.validationPasswordUppercase;
      case RegisterValidationErrorKey.passwordMissingLowercase:
        return l10n.auth.validationPasswordLowercase;
      case RegisterValidationErrorKey.passwordMissingDigit:
        return l10n.auth.validationPasswordDigit;
      case RegisterValidationErrorKey.passwordMissingSymbol:
        return l10n.auth.validationPasswordSymbol;
      case RegisterValidationErrorKey.passwordMismatch:
        return l10n.auth.validationPasswordMismatch;
      case RegisterValidationErrorKey.invalidPhoneNumber:
        return l10n.auth.validationPhoneNumber;
      case null:
        return null;
    }
  }

  /// The backend already returns a localised, human-readable reason for a
  /// rejected registration ("هذا البريد مستخدم بالفعل"), so it is surfaced
  /// verbatim; the mapped code only supplies the fallback.
  String _failureMessage(AppLocalizations l10n, Failure? failure) {
    final backendMessage = failure?.debugMessage;
    if (backendMessage != null && backendMessage.trim().isNotEmpty) {
      return backendMessage;
    }

    switch (failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.validation:
        return l10n.auth.registerFailed;
      case FailureCode.invalidCredentials:
      case FailureCode.unknown:
      case null:
        return l10n.auth.unknownError;
    }
  }
}

class _RegisterTextField extends StatelessWidget {
  const _RegisterTextField({
    required this.controller,
    required this.hintText,
    required this.semanticLabel,
    required this.icon,
    required this.keyboardType,
    required this.textInputAction,
    required this.validator,
    required this.onSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String hintText;
  final String semanticLabel;
  final IconData icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final semanticColors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final leading = Icon(icon);

    return AppTextField(
      controller: controller,
      hintText: hintText,
      semanticLabel: semanticLabel,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textAlign: TextAlign.center,
      validator: validator,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      prefixIcon: isRtl ? leading : null,
      suffixIcon: isRtl ? null : leading,
      iconColor: semanticColors.mutedText,
      iconSize: AppSizes.iconMedium,
    );
  }
}
