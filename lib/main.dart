import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'core/di/service_locator.dart';
import 'core/network/api_constants.dart';
import 'core/network/dio_client.dart';
import 'core/network/retry_interceptor.dart';
import 'core/presentation/cubit/app_settings_cubit.dart';
import 'features/authentication/presentation/cubit/auth_session_cubit.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  // Fire-and-forget: wakes the sleeping backend and opens the TLS connection
  // while the splash/onboarding/login screens are shown, so the first real
  // request (login, address, home) no longer pays the cold-start cost.
  unawaited(_warmUpBackend());

  runApp(
    MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AppSettingsCubit>.value(
          value: sl<AppSettingsCubit>(),
        ),
        BlocProvider<AuthSessionCubit>.value(
          value: sl<AuthSessionCubit>(),
        ),
        BlocProvider<OnboardingCubit>(
          create: (_) => sl<OnboardingCubit>(),
        ),
      ],
      child: const LuqmaApp(),
    ),
  );
}

Future<void> _warmUpBackend() async {
  try {
    await sl<DioClient>().dio.get<Object?>(
          ApiConstants.getAllMainCategories,
          options: Options(
            extra: <String, dynamic>{
              DioClient.requiresAuthenticationExtraKey: false,
              RetryInterceptor.disableKey: true,
            },
          ),
        );
  } catch (_) {
    // Best effort only; real requests handle their own errors.
  }
}
