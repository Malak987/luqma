import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../cubit/register_cubit.dart';
import '../cubit/register_state.dart';
import '../widgets/register_password_section.dart';
import '../widgets/register_submit_button.dart';
import '../widgets/register_text_field.dart';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppLogo(semanticLabel: l10n.common.brandName),
              const SizedBox(height: AppSpacing.lg),
              RegisterTextField(
                controller: _userNameController,
                hintText: l10n.auth.userName,
                semanticLabel: l10n.auth.userNameLabel,
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                validator: Validators.username,
                onSubmitted: (_) => _emailFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              RegisterTextField(
                controller: _emailController,
                hintText: l10n.auth.email,
                semanticLabel: l10n.auth.emailLabel,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocusNode,
                autofillHints: const <String>[AutofillHints.email],
                validator: Validators.email,
                onSubmitted: (_) => _phoneFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              RegisterTextField(
                controller: _phoneController,
                hintText: l10n.auth.phoneNumber,
                semanticLabel: l10n.auth.phoneNumberLabel,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                focusNode: _phoneFocusNode,
                validator: Validators.phoneNumber,
                onSubmitted: (_) => _addressFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              RegisterTextField(
                controller: _addressController,
                hintText: l10n.auth.address,
                semanticLabel: l10n.auth.addressLabel,
                icon: Icons.location_on_outlined,
                keyboardType: TextInputType.streetAddress,
                focusNode: _addressFocusNode,
                validator: Validators.requiredText,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              RegisterPasswordSection(
                passwordController: _passwordController,
                confirmController: _confirmPasswordController,
                passwordFocusNode: _passwordFocusNode,
                confirmFocusNode: _confirmPasswordFocusNode,
                onSubmit: _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              RegisterSubmitButton(onPressed: _submit),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => _backToLogin(context),
                child: Text(l10n.auth.backToLogin),
              ),
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

    // Registration issues no token, so there is no session to continue with.
    // Hand the registered email to the verification screen, which confirms the
    // OTP that the backend already emailed. Replacing this route means the back
    // button leaves the completed form instead of returning to it.
    if (isSuccess) {
      AppRouter.replaceWithNamed(
        context,
        AppRoutes.verification,
        arguments: _emailController.text.trim(),
      );
    }
  }

  void _backToLogin(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    AppRouter.replaceWithNamed(context, AppRoutes.login);
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
