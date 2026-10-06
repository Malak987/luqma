import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luqma_app/app/app.dart';
import 'package:luqma_app/core/di/service_locator.dart';
import 'package:luqma_app/core/presentation/cubit/app_settings_cubit.dart';

void main() {
  testWidgets('LuqmaApp builds successfully', (WidgetTester tester) async {
    await configureDependencies();

    await tester.pumpWidget(
      BlocProvider<AppSettingsCubit>.value(
        value: sl<AppSettingsCubit>(),
        child: const LuqmaApp(),
      ),
    );

    expect(find.byType(LuqmaApp), findsOneWidget);
  });
}
