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
import '../../../../../core/utils/validators.dart';
import '../../../../../core/widgets/app_text_field.dart';
import '../../../../../core/widgets/brand_icon.dart';
import '../../../../../core/widgets/social_login_button.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_footer.dart';
import '../widgets/auth_logo.dart';
import '../widgets/auth_password_field.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/forgot_password_button.dart';
import '../widgets/primary_auth_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final semanticColors =
        theme.extension<AppSemanticColors>() ?? AppSemanticColors.light;
    final metrics =
        theme.extension<AppLayoutMetrics>() ?? AppLayoutMetrics.light;

    return BlocListener<LoginCubit, LoginState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.isSuccess) {
          AppRouter.replaceWithNamed(context, AppRoutes.home);
        } else if (state.hasFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(_failureMessage(l10n, state.failure))),
            );
        }
      },
      child: AuthScaffold(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AuthLogo(
                brandName: l10n.common.brandName,
                tagline: l10n.common.brandTagline,
              ),
              SizedBox(height: metrics.authLogoToForm),
              _UsernameField(
                controller: _usernameController,
                validator: (value) => _validationMessage(
                  l10n,
                  Validators.usernameOrEmail(value),
                ),
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthPasswordField(
                controller: _passwordController,
                hintText: l10n.auth.password,
                lockTooltip: l10n.auth.password,
                validator: (value) => _validationMessage(
                  l10n,
                  Validators.password(value),
                ),
                focusNode: _passwordFocusNode,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              BlocSelector<LoginCubit, LoginState, bool>(
                selector: (state) => state.isLoading,
                builder: (context, isLoading) {
                  return PrimaryAuthButton(
                    text: l10n.auth.login,
                    loading: isLoading,
                    enabled: !isLoading,
                    semanticLabel:
                        isLoading ? l10n.auth.loginLoading : l10n.auth.login,
                    onPressed: _submit,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(child: ForgotPasswordButton(
                text: l10n.auth.forgotPassword,
                onPressed: () => AppRouter.pushNamed(
                  context,
                  AppRoutes.forgotPassword,
                ),
              )),
              SizedBox(height: metrics.authForgotToDivider),
              AuthDivider(label: l10n.auth.continueWith),
              const SizedBox(height: AppSpacing.xl),
              SocialLoginRow(
                providers: <SocialLoginConfig>[
                  SocialLoginConfig(
                    provider: SocialProvider.apple,
                    tooltip: l10n.auth.appleLogin,
                    iconColor: semanticColors.bodyText,
                    onPressed: () => _showSocialMessage(
                      context,
                      l10n.auth.appleLogin,
                    ),
                  ),
                  SocialLoginConfig(
                    provider: SocialProvider.facebook,
                    tooltip: l10n.auth.facebookLogin,
                    iconColor: const Color(0xFF1877F2),
                    onPressed: () => _showSocialMessage(
                      context,
                      l10n.auth.facebookLogin,
                    ),
                  ),
                  SocialLoginConfig(
                    provider: SocialProvider.google,
                    tooltip: l10n.auth.googleLogin,
                    onPressed: () => _showSocialMessage(
                      context,
                      l10n.auth.googleLogin,
                    ),
                  ),
                ],
              ),
              SizedBox(height: metrics.authSocialToFooter),
              Center(child: AuthFooter(
                onRegister: () => AppRouter.pushNamed(
                  context,
                  AppRoutes.register,
                ),
              )),
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

    context.read<LoginCubit>().login(
          email: _usernameController.text,
          password: _passwordController.text,
        );
  }

  void _showSocialMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validationMessage(
    AppLocalizations l10n,
    ValidationErrorKey? error,
  ) {
    switch (error) {
      case ValidationErrorKey.requiredField:
        return l10n.common.validationRequired;
      case ValidationErrorKey.invalidUsernameOrEmail:
        return l10n.common.validationUsernameOrEmail;
      case ValidationErrorKey.passwordTooShort:
        return l10n.common.validationPasswordLength;
      case null:
        return null;
    }
  }

  String _failureMessage(AppLocalizations l10n, Failure? failure) {
    switch (failure?.code) {
      case FailureCode.network:
        return l10n.auth.networkError;
      case FailureCode.invalidCredentials:
        return l10n.auth.invalidCredentials;
      case FailureCode.validation:
        return l10n.auth.loginFailed;
      case FailureCode.unknown:
      case null:
        return l10n.auth.unknownError;
    }
  }
}

class _UsernameField extends StatelessWidget {
  const _UsernameField({
    required this.controller,
    required this.validator,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semanticColors = Theme.of(context).extension<AppSemanticColors>() ??
        AppSemanticColors.light;
    final icon = Tooltip(
      message: l10n.auth.usernameOrEmailLabel,
      child: const Icon(Icons.person_outline_rounded),
    );

    return AppTextField(
      controller: controller,
      hintText: l10n.auth.emailOrUsername,
      semanticLabel: l10n.auth.usernameOrEmailLabel,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: validator,
      onSubmitted: onSubmitted,
      prefixIcon: icon,
      iconColor: semanticColors.mutedText,
      iconSize: AppSizes.iconMedium,
    );
  }
}
