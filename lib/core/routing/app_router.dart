import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/service_locator.dart';
import 'app_routes.dart';
import '../../features/authentication/email_verification/presentation/cubit/email_verification_cubit.dart';
import '../../features/authentication/email_verification/presentation/pages/email_verification_page.dart';
import '../../features/authentication/login/presentation/cubit/login_cubit.dart';
import '../../features/authentication/login/presentation/pages/login_page.dart';
import '../../features/authentication/password_reset/presentation/cubit/password_reset_cubit.dart';
import '../../features/authentication/password_reset/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/password_reset/presentation/pages/reset_password_page.dart';
import '../../features/authentication/register/presentation/cubit/register_cubit.dart';
import '../../features/authentication/register/presentation/pages/register_page.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/pages/home_page.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<LoginCubit>(
            create: (_) => sl<LoginCubit>(),
            child: const LoginPage(),
          ),
        );
      case AppRoutes.register:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<RegisterCubit>(
            create: (_) => sl<RegisterCubit>(),
            child: const RegisterPage(),
          ),
        );
      case AppRoutes.forgotPassword:
        // Both password-reset routes share ONE cubit instance, so the 60-second
        // cooldown and the pending email survive the Forgot → Reset hop. The
        // cubit is a singleton in DI; `BlocProvider.value` only exposes it, and
        // never closes it, so leaving the route keeps the cooldown intact.
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<PasswordResetCubit>.value(
            value: sl<PasswordResetCubit>(),
            child: ForgotPasswordPage(email: _emailArgument(settings)),
          ),
        );
      case AppRoutes.resetPassword:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<PasswordResetCubit>.value(
            value: sl<PasswordResetCubit>(),
            child: ResetPasswordPage(email: _emailArgument(settings)),
          ),
        );
      case AppRoutes.verification:
        // The registered email is passed through `arguments` so the user does
        // not have to retype it. Null is valid: the page then asks for it.
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) {
            final argument = settings.arguments;
            final email = argument is String && argument.trim().isNotEmpty
                ? argument.trim()
                : null;
            return BlocProvider<EmailVerificationCubit>(
              create: (_) => sl<EmailVerificationCubit>(),
              child: EmailVerificationPage(email: email),
            );
          },
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => BlocProvider<HomeCubit>(
            create: (_) => sl<HomeCubit>(),
            child: const HomePage(),
          ),
        );
      default:
        return MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.login),
          builder: (_) => BlocProvider<LoginCubit>(
            create: (_) => sl<LoginCubit>(),
            child: const LoginPage(),
          ),
        );
    }
  }

  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> replaceWithNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
      arguments: arguments,
    );
  }

  /// Reads the email handed over through route arguments.
  ///
  /// Anything that is not a non-blank string (null, an unexpected type, an
  /// empty or whitespace-only value) yields null, so a malformed deep link
  /// degrades to a page that simply asks for the address.
  static String? _emailArgument(RouteSettings settings) {
    final argument = settings.arguments;
    if (argument is! String) {
      return null;
    }
    final trimmed = argument.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

}
