import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'core/di/service_locator.dart';
import 'core/presentation/cubit/app_settings_cubit.dart';
import 'features/authentication/presentation/cubit/auth_session_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(
    MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<AppSettingsCubit>.value(
          value: sl<AppSettingsCubit>(),
        ),
        BlocProvider<AuthSessionCubit>.value(
          value: sl<AuthSessionCubit>(),
        ),
      ],
      child: const LuqmaApp(),
    ),
  );
}