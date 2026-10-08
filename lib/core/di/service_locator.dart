import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/authentication/email_verification/data/datasources/email_verification_remote_data_source.dart';
import '../../features/authentication/email_verification/data/repositories/email_verification_repository_impl.dart';
import '../../features/authentication/email_verification/domain/repositories/email_verification_repository.dart';
import '../../features/authentication/email_verification/domain/usecases/confirm_email_use_case.dart';
import '../../features/authentication/email_verification/domain/usecases/resend_otp_use_case.dart';
import '../../features/authentication/email_verification/presentation/cubit/email_verification_cubit.dart';
import '../../features/authentication/login/data/datasources/login_remote_data_source.dart';
import '../../features/authentication/login/data/repositories/login_repository_impl.dart';
import '../../features/authentication/login/domain/repositories/login_repository.dart';
import '../../features/authentication/login/domain/usecases/login_use_case.dart';
import '../../features/authentication/login/presentation/cubit/login_cubit.dart';
import '../../features/authentication/password_reset/data/datasources/password_reset_remote_data_source.dart';
import '../../features/authentication/password_reset/data/repositories/password_reset_repository_impl.dart';
import '../../features/authentication/password_reset/domain/repositories/password_reset_repository.dart';
import '../../features/authentication/password_reset/domain/usecases/forgot_password_use_case.dart';
import '../../features/authentication/password_reset/domain/usecases/reset_password_use_case.dart';
import '../../features/authentication/password_reset/presentation/cubit/password_reset_cubit.dart';
import '../../features/authentication/register/data/datasources/register_remote_data_source.dart';
import '../../features/authentication/register/data/repositories/register_repository_impl.dart';
import '../../features/authentication/register/domain/repositories/register_repository.dart';
import '../../features/authentication/register/domain/usecases/register_use_case.dart';
import '../../features/authentication/register/presentation/cubit/register_cubit.dart';
import '../network/dio_client.dart';
import '../presentation/cubit/app_settings_cubit.dart';
import '../storage/secure_storage_service.dart';
import '../../features/authentication/presentation/cubit/auth_session_cubit.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';

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

  // ------------------------------------------------------------
  // Authentication - Register
  // ------------------------------------------------------------

  if (!sl.isRegistered<RegisterRemoteDataSource>()) {
    sl.registerLazySingleton<RegisterRemoteDataSource>(
      () => RegisterRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<RegisterRepository>()) {
    sl.registerLazySingleton<RegisterRepository>(
      () => RegisterRepositoryImpl(sl<RegisterRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<RegisterUseCase>()) {
    sl.registerLazySingleton<RegisterUseCase>(
      () => RegisterUseCase(sl<RegisterRepository>()),
    );
  }

  if (!sl.isRegistered<RegisterCubit>()) {
    sl.registerFactory<RegisterCubit>(
      () => RegisterCubit(registerUseCase: sl<RegisterUseCase>()),
    );
  }

  // ------------------------------------------------------------
  // Authentication - Email verification
  // ------------------------------------------------------------

  if (!sl.isRegistered<EmailVerificationRemoteDataSource>()) {
    sl.registerLazySingleton<EmailVerificationRemoteDataSource>(
      () => EmailVerificationRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<EmailVerificationRepository>()) {
    sl.registerLazySingleton<EmailVerificationRepository>(
      () => EmailVerificationRepositoryImpl(
        sl<EmailVerificationRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<ConfirmEmailUseCase>()) {
    sl.registerLazySingleton<ConfirmEmailUseCase>(
      () => ConfirmEmailUseCase(sl<EmailVerificationRepository>()),
    );
  }

  if (!sl.isRegistered<ResendOtpUseCase>()) {
    sl.registerLazySingleton<ResendOtpUseCase>(
      () => ResendOtpUseCase(sl<EmailVerificationRepository>()),
    );
  }

  if (!sl.isRegistered<EmailVerificationCubit>()) {
    sl.registerFactory<EmailVerificationCubit>(
      () => EmailVerificationCubit(
        confirmEmailUseCase: sl<ConfirmEmailUseCase>(),
        resendOtpUseCase: sl<ResendOtpUseCase>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Authentication - Password reset
  // ------------------------------------------------------------

  if (!sl.isRegistered<PasswordResetRemoteDataSource>()) {
    sl.registerLazySingleton<PasswordResetRemoteDataSource>(
      () => PasswordResetRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<PasswordResetRepository>()) {
    sl.registerLazySingleton<PasswordResetRepository>(
      () => PasswordResetRepositoryImpl(sl<PasswordResetRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<ForgotPasswordUseCase>()) {
    sl.registerLazySingleton<ForgotPasswordUseCase>(
      () => ForgotPasswordUseCase(sl<PasswordResetRepository>()),
    );
  }

  if (!sl.isRegistered<ResetPasswordUseCase>()) {
    sl.registerLazySingleton<ResetPasswordUseCase>(
      () => ResetPasswordUseCase(sl<PasswordResetRepository>()),
    );
  }

  // A singleton, not a factory: the cubit spans the Forgot and Reset screens,
  // and the 60-second cooldown is the only protection against repeated reset
  // emails because the backend applies no throttling. Recreating it per page
  // would silently reset that window.
  if (!sl.isRegistered<PasswordResetCubit>()) {
    sl.registerLazySingleton<PasswordResetCubit>(
          () => PasswordResetCubit(
        forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
        resetPasswordUseCase: sl<ResetPasswordUseCase>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Authentication - Session bootstrap
  // ------------------------------------------------------------

  if (!sl.isRegistered<AuthSessionCubit>()) {
    sl.registerLazySingleton<AuthSessionCubit>(
          () => AuthSessionCubit(
        secureStorageService: sl<SecureStorageService>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Home
  // ------------------------------------------------------------

  // A factory, not a singleton: every visit to home loads its own state, so a
  // stale greeting or a stale failure can never leak into the next visit.
  if (!sl.isRegistered<HomeCubit>()) {
    sl.registerFactory<HomeCubit>(
      () => HomeCubit(
        secureStorageService: sl<SecureStorageService>(),
      ),
    );
  }
}
