import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luqma_app/app/app.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';
import 'package:luqma_app/features/authentication/presentation/cubit/auth_session_cubit.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  testWidgets('LuqmaApp builds successfully', (tester) async {
    await tester.pumpWidget(
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

    await tester.pump();

    expect(find.byType(LuqmaApp), findsOneWidget);
  });
}