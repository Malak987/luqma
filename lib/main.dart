import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'core/di/service_locator.dart';
import 'core/presentation/cubit/app_settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  runApp(
    BlocProvider<AppSettingsCubit>.value(
      value: sl<AppSettingsCubit>(),
      child: const LuqmaApp(),
    ),
  );
}
