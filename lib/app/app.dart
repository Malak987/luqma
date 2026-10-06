import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/extensions/locale_extensions.dart';
import '../core/localization/app_localizations.dart';
import '../core/presentation/cubit/app_settings_cubit.dart';
import '../core/presentation/cubit/app_settings_state.dart';
import '../core/routing/app_router.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_theme.dart';

class LuqmaApp extends StatelessWidget {
  const LuqmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, settings) {
        return MaterialApp(
          title: AppConstants.applicationName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeResolutionCallback: (locale, supportedLocales) {
            final languageCode = locale?.languageCode;
            return supportedLocales.firstWhere(
              (supported) => supported.languageCode == languageCode,
              orElse: () => supportedLocales.first,
            );
          },
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRouter.onGenerateRoute,
          builder: (context, child) {
            final direction = settings.locale.textDirection;
            return Directionality(
              textDirection: direction,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
