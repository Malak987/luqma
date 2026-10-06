import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/service_locator.dart';
import '../localization/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_routes.dart';
import '../../features/authentication/login/presentation/cubit/login_cubit.dart';
import '../../features/authentication/login/presentation/pages/login_page.dart';
import '../../features/authentication/register/presentation/cubit/register_cubit.dart';
import '../../features/authentication/register/presentation/pages/register_page.dart';

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
        return _comingSoonRoute(
          settings,
          (l10n) => l10n.common.forgotPassword,
        );
      case AppRoutes.resetPassword:
        return _comingSoonRoute(
          settings,
          (l10n) => l10n.common.resetPassword,
        );
      case AppRoutes.verification:
        return _comingSoonRoute(
          settings,
          (l10n) => l10n.common.verification,
        );
      case AppRoutes.home:
        return _comingSoonRoute(settings, (l10n) => l10n.common.home);
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
    String routeName,
  ) {
    return Navigator.of(context).pushNamed<T>(routeName);
  }

  static Future<T?> replaceWithNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    TO? result,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      result: result,
    );
  }

  static MaterialPageRoute<void> _comingSoonRoute(
    RouteSettings settings,
    String Function(AppLocalizations) titleBuilder,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => _ComingSoonPage(titleBuilder: titleBuilder),
    );
  }
}

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage({required this.titleBuilder});

  final String Function(AppLocalizations) titleBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors =
        Theme.of(context).extension<AppSemanticColors>() ?? AppSemanticColors.light;
    return Scaffold(
      appBar: AppBar(
        title: Text(titleBuilder(l10n)),
        backgroundColor: colors.background,
        foregroundColor: colors.headingText,
      ),
      backgroundColor: colors.background,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(AppSpacing.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(
              l10n.common.comingSoon,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
