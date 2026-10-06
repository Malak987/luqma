import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/authentication/login/data/datasources/login_remote_data_source.dart';
import '../../features/authentication/login/data/repositories/authentication_repository_impl.dart';
import '../../features/authentication/login/domain/repositories/authentication_repository.dart';
import '../../features/authentication/login/domain/usecases/login_use_case.dart';
import '../../features/authentication/login/presentation/cubit/login_cubit.dart';
import '../network/dio_client.dart';
import '../presentation/cubit/app_settings_cubit.dart';
import '../storage/secure_storage_service.dart';

final GetIt sl = GetIt.instance;

/// Composition root for the application.
///
/// Dependencies are registered here so that presentation and domain
/// layers don't construct infrastructure implementations directly.
Future<void> configureDependencies() async {
  if (sl.isRegistered<AppSettingsCubit>()) {
    return;
  }

  // ------------------------------------------------------------
  // Core
  // ------------------------------------------------------------

  sl.registerLazySingleton<FlutterSecureStorage>(
    FlutterSecureStorage.new,
  );

  sl.registerLazySingleton<SecureStorageService>(
        () => SecureStorageService(
      sl<FlutterSecureStorage>(),
    ),
  );

  sl.registerLazySingleton<DioClient>(
        () => DioClient(
      sl<SecureStorageService>(),
    ),
  );

  // ------------------------------------------------------------
  // App Settings
  // ------------------------------------------------------------

  sl.registerLazySingleton<AppSettingsCubit>(
    AppSettingsCubit.new,
  );

  // ------------------------------------------------------------
  // Authentication - Login
  // ------------------------------------------------------------

  sl.registerLazySingleton<LoginRemoteDataSource>(
        () => LoginRemoteDataSourceImpl(
      sl<DioClient>(),
    ),
  );

  sl.registerLazySingleton<AuthenticationRepository>(
        () => AuthenticationRepositoryImpl(
      sl<LoginRemoteDataSource>(),
      sl<SecureStorageService>(),
    ),
  );

  sl.registerLazySingleton<LoginUseCase>(
        () => LoginUseCase(
      sl<AuthenticationRepository>(),
    ),
  );

  sl.registerFactory<LoginCubit>(
        () => LoginCubit(
      loginUseCase: sl<LoginUseCase>(),
    ),
  );
}