import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/constants/app_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/presentation/cubit/app_settings_cubit.dart';
import '../core/presentation/cubit/app_settings_state.dart';
import '../core/routing/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/authentication/login/presentation/cubit/login_cubit.dart';
import '../features/authentication/login/presentation/pages/login_page.dart';
import '../features/authentication/presentation/cubit/auth_session_cubit.dart';
import '../features/authentication/presentation/cubit/auth_session_state.dart';
import '../features/home/presentation/cubit/home_cubit.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../features/onboarding/presentation/cubit/onboarding_state.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/splash/presentation/pages/splash_page.dart';
import '../core/di/service_locator.dart';

class LuqmaApp extends StatefulWidget {
  const LuqmaApp({super.key});

  @override
  State<LuqmaApp> createState() => _LuqmaAppState();
}

class _LuqmaAppState extends State<LuqmaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<AuthSessionCubit>().checkSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = WidgetsBinding.instance.platformDispatcher
            .accessibilityFeatures.disableAnimations ||
        (MediaQuery.maybeDisableAnimationsOf(context) ?? false);
    final themeAnimationDuration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 300);

    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      buildWhen: (previous, current) => previous != current,
      builder: (context, settings) {
        return MaterialApp(
          title: AppConstants.applicationName,
          debugShowCheckedModeBanner: false,

          // ------------------------------------------------------------
          // Theme
          // ------------------------------------------------------------

          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          themeAnimationDuration: themeAnimationDuration,

          // ------------------------------------------------------------
          // Localization
          // ------------------------------------------------------------

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

          // ------------------------------------------------------------
          // Routing
          // ------------------------------------------------------------

          onGenerateRoute: AppRouter.onGenerateRoute,

          // ------------------------------------------------------------
          // Initial screen
          // ------------------------------------------------------------

          home: const _AppStartupGate(),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Loading Screen
// -----------------------------------------------------------------------------

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: isDark
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Authenticated Home
// -----------------------------------------------------------------------------

class _AuthenticatedHomeScreen extends StatelessWidget {
  const _AuthenticatedHomeScreen();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (_) => sl<HomeCubit>(),
      child: const HomePage(),
    );
  }
}

// -----------------------------------------------------------------------------
// App Startup Gate
// -----------------------------------------------------------------------------

class _AppStartupGate extends StatefulWidget {
  const _AppStartupGate();

  @override
  State<_AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<_AppStartupGate> {
  bool _hasCompletedSplash = false;

  void _onSplashCompleted() {
    if (mounted && !_hasCompletedSplash) {
      setState(() {
        _hasCompletedSplash = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCompletedSplash) {
      return SplashPage(
        onSplashCompleted: _onSplashCompleted,
      );
    }

    return const _RootFlowGate();
  }
}

// -----------------------------------------------------------------------------
// Root Flow Gate
// -----------------------------------------------------------------------------

class _RootFlowGate extends StatelessWidget {
  const _RootFlowGate();

  @override
  Widget build(BuildContext context) {
    final rootContent = BlocBuilder<OnboardingCubit, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.isCompleted != current.isCompleted ||
          previous.isReviewMode != current.isReviewMode,
      builder: (context, onboardingState) {
        if (!onboardingState.isCompleted && !onboardingState.isReviewMode) {
          return const OnboardingPage();
        }

        return BlocBuilder<AuthSessionCubit, AuthSessionState>(
          buildWhen: (previous, current) => previous.status != current.status,
          builder: (context, authState) {
            switch (authState.status) {
              case AuthSessionStatus.initial:
              case AuthSessionStatus.checking:
                return const _AuthLoadingScreen();

              case AuthSessionStatus.unauthenticated:
                return BlocProvider<LoginCubit>(
                  create: (_) => sl<LoginCubit>(),
                  child: const LoginPage(),
                );

              case AuthSessionStatus.authenticated:
                return const _AuthenticatedHomeScreen();
            }
          },
        );
      },
    );

    try {
      context.read<OnboardingCubit>();
      return rootContent;
    } catch (_) {
      return BlocProvider<OnboardingCubit>(
        create: (_) => sl<OnboardingCubit>(),
        child: rootContent,
      );
    }
  }
}
