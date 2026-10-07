import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/localization/app_localizations.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_logo.dart';
import '../../../shared/widgets/auth_scaffold.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';
import '../widgets/auth_footer.dart';
import '../widgets/forgot_password_button.dart';
import '../widgets/login_email_field.dart';
import '../widgets/login_password_field.dart';
import '../widgets/login_social_section.dart';
import '../widgets/login_submit_button.dart';

/// Owns only the form state and submit logic. Every visual block is its own
/// widget, so typing or a loading flip rebuilds just the piece that changed.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppLogo(semanticLabel: l10n.common.brandName),
              const SizedBox(height: AppSpacing.xl),
              LoginEmailField(
                controller: _emailController,
                onSubmitted: (_) => _passwordFocusNode.requestFocus(),
              ),
              const SizedBox(height: AppSpacing.md),
              LoginPasswordField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                onSubmitted: _submit,
              ),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ForgotPasswordButton(
                  text: l10n.auth.forgotPassword,
                  onPressed: () => AppRouter.pushNamed(
                    context,
                    AppRoutes.forgotPassword,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              LoginSubmitButton(onPressed: _submit),
              const SizedBox(height: AppSpacing.xxl),
              const LoginSocialSection(),
              const SizedBox(height: AppSpacing.xxl),
              AuthFooter(
                onRegister: () => AppRouter.pushNamed(
                  context,
                  AppRoutes.register,
                ),
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

    context.read<LoginCubit>().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
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
