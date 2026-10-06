import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/authentication/login/data/datasources/login_remote_data_source.dart';
import '../../features/authentication/login/data/repositories/login_repository_impl.dart';
import '../../features/authentication/login/domain/repositories/login_repository.dart';
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
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      FlutterSecureStorage.new,
    );
  }

  if (!sl.isRegistered<SecureStorageService>()) {
    sl.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(sl<FlutterSecureStorage>()),
    );
  }

  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(
      () => DioClient(sl<SecureStorageService>()),
    );
  }

  if (!sl.isRegistered<AppSettingsCubit>()) {
    sl.registerLazySingleton<AppSettingsCubit>(AppSettingsCubit.new);
  }

  if (!sl.isRegistered<LoginRemoteDataSource>()) {
    sl.registerLazySingleton<LoginRemoteDataSource>(
      () => LoginRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<LoginRepository>()) {
    sl.registerLazySingleton<LoginRepository>(
      () => LoginRepositoryImpl(
        sl<LoginRemoteDataSource>(),
        sl<SecureStorageService>(),
      ),
    );
  }

  if (!sl.isRegistered<LoginUseCase>()) {
    sl.registerLazySingleton<LoginUseCase>(
      () => LoginUseCase(sl<LoginRepository>()),
    );
  }

  if (!sl.isRegistered<LoginCubit>()) {
    sl.registerFactory<LoginCubit>(
      () => LoginCubit(loginUseCase: sl<LoginUseCase>()),
    );
  }
}
