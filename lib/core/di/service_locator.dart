import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/address/data/datasources/address_remote_data_source.dart';
import '../../features/address/data/repositories/address_repository_impl.dart';
import '../../features/address/domain/repositories/address_repository.dart';
import '../../features/address/domain/usecases/create_address_use_case.dart';
import '../../features/address/domain/usecases/get_my_addresses_use_case.dart';
import '../../features/location/data/datasources/geolocator_location_data_source.dart';
import '../../features/location/data/repositories/location_repository_impl.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/location/domain/usecases/get_current_location_use_case.dart';
import '../../features/location/domain/usecases/request_location_permission_use_case.dart';
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
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../network/dio_client.dart';
import '../presentation/cubit/app_settings_cubit.dart';
import '../storage/preferences_storage_service.dart';
import '../storage/secure_storage_service.dart';
import '../../features/address/presentation/cubit/address_form_cubit.dart';
import '../../features/address/presentation/cubit/address_setup_cubit.dart';
import '../../features/address/presentation/cubit/map_picker_cubit.dart';
import '../../features/location/domain/entities/location_coordinates.dart';
import '../../features/authentication/presentation/cubit/auth_session_cubit.dart';
import '../../features/home/data/datasources/main_category_remote_data_source.dart';
import '../../features/home/data/repositories/main_category_repository_impl.dart';
import '../../features/home/domain/repositories/main_category_repository.dart';
import '../../features/home/domain/usecases/get_all_main_categories_use_case.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/cart/data/datasources/cart_remote_data_source.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/add_to_cart_use_case.dart';
import '../../features/cart/domain/usecases/clear_cart_use_case.dart';
import '../../features/cart/domain/usecases/get_cart_count_use_case.dart';
import '../../features/cart/domain/usecases/get_my_cart_use_case.dart';
import '../../features/cart/domain/usecases/update_to_cart_use_case.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/favorites/data/datasources/favorites_remote_data_source.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/queries/favorite_paging.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/add_to_favorites_use_case.dart';
import '../../features/favorites/domain/usecases/get_favorites_count_use_case.dart';
import '../../features/favorites/domain/usecases/get_my_favorites_use_case.dart';
import '../../features/favorites/domain/usecases/is_favorite_use_case.dart';
import '../../features/favorites/domain/usecases/remove_from_favorites_use_case.dart';
import '../../features/favorites/presentation/cubit/favorites_cubit.dart';
import '../../features/shell/presentation/cubit/main_shell_cubit.dart';
import '../../features/catalog/data/datasources/store_discovery_remote_data_source.dart';
import '../../features/catalog/data/repositories/store_discovery_repository_impl.dart';
import '../../features/catalog/domain/queries/catalog_paging.dart';
import '../../features/catalog/domain/repositories/store_discovery_repository.dart';
import '../../features/catalog/domain/usecases/get_active_cuisines_use_case.dart';
import '../../features/catalog/domain/usecases/get_stores_use_case.dart';
import '../../features/catalog/presentation/cubit/store_discovery_cubit.dart';
import '../../features/catalog/data/datasources/store_menu_remote_data_source.dart';
import '../../features/catalog/data/repositories/store_menu_repository_impl.dart';
import '../../features/catalog/domain/repositories/store_menu_repository.dart';
import '../../features/catalog/domain/usecases/get_active_menu_categories_use_case.dart';
import '../../features/catalog/domain/usecases/get_menu_items_use_case.dart';
import '../../features/catalog/presentation/cubit/store_menu_cubit.dart';

final GetIt sl = GetIt.instance;

/// Composition root for the application.
///
/// Dependencies are registered here so that presentation and domain
/// layers don't construct infrastructure implementations directly.
Future<void> configureDependencies({SharedPreferences? preferences}) async {
  if (!sl.isRegistered<SharedPreferences>()) {
    if (preferences != null) {
      sl.registerSingleton<SharedPreferences>(preferences);
    } else {
      final sharedPreferences = await SharedPreferences.getInstance();
      sl.registerSingleton<SharedPreferences>(sharedPreferences);
    }
  }

  if (!sl.isRegistered<PreferencesStorageService>()) {
    sl.registerLazySingleton<PreferencesStorageService>(
      () => PreferencesStorageService(sl<SharedPreferences>()),
    );
  }

  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          resetOnError: false,
          migrateOnAlgorithmChange: true,
          migrateWithBackup: false,
        ),
      ),
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
    sl.registerLazySingleton<AppSettingsCubit>(
      () => AppSettingsCubit(
        preferencesStorageService: sl<PreferencesStorageService>(),
      ),
    );
  }

  if (!sl.isRegistered<OnboardingCubit>()) {
    sl.registerFactory<OnboardingCubit>(
      () => OnboardingCubit(
        preferencesStorageService: sl<PreferencesStorageService>(),
      ),
    );
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
      () => AuthSessionCubit(secureStorageService: sl<SecureStorageService>()),
    );
  }

  // ------------------------------------------------------------
  // Home
  // ------------------------------------------------------------

  if (!sl.isRegistered<MainCategoryRemoteDataSource>()) {
    sl.registerLazySingleton<MainCategoryRemoteDataSource>(
      () => MainCategoryRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<MainCategoryRepository>()) {
    sl.registerLazySingleton<MainCategoryRepository>(
      () => MainCategoryRepositoryImpl(sl<MainCategoryRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetAllMainCategoriesUseCase>()) {
    sl.registerLazySingleton<GetAllMainCategoriesUseCase>(
      () => GetAllMainCategoriesUseCase(sl<MainCategoryRepository>()),
    );
  }

  // A factory, not a singleton: every visit to home loads its own state, so a
  // stale greeting or a stale failure can never leak into the next visit.
  if (!sl.isRegistered<HomeCubit>()) {
    sl.registerFactory<HomeCubit>(
      () => HomeCubit(
        secureStorageService: sl<SecureStorageService>(),
        getAllMainCategoriesUseCase: sl<GetAllMainCategoriesUseCase>(),
        getStoresUseCase: sl<GetStoresUseCase>(),
        catalogPaging: sl<CatalogPaging>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // App shell (persistent bottom navigation)
  // ------------------------------------------------------------

  // A factory: each authenticated session starts on the Home tab.
  if (!sl.isRegistered<MainShellCubit>()) {
    sl.registerFactory<MainShellCubit>(() => MainShellCubit());
  }

  // ------------------------------------------------------------
  // Cart
  // ------------------------------------------------------------

  if (!sl.isRegistered<CartRemoteDataSource>()) {
    sl.registerLazySingleton<CartRemoteDataSource>(
      () => CartRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<CartRepository>()) {
    sl.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(sl<CartRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<AddToCartUseCase>()) {
    sl.registerLazySingleton<AddToCartUseCase>(
      () => AddToCartUseCase(sl<CartRepository>()),
    );
  }

  if (!sl.isRegistered<UpdateToCartUseCase>()) {
    sl.registerLazySingleton<UpdateToCartUseCase>(
      () => UpdateToCartUseCase(sl<CartRepository>()),
    );
  }

  if (!sl.isRegistered<ClearCartUseCase>()) {
    sl.registerLazySingleton<ClearCartUseCase>(
      () => ClearCartUseCase(sl<CartRepository>()),
    );
  }

  if (!sl.isRegistered<GetMyCartUseCase>()) {
    sl.registerLazySingleton<GetMyCartUseCase>(
      () => GetMyCartUseCase(sl<CartRepository>()),
    );
  }

  if (!sl.isRegistered<GetCartCountUseCase>()) {
    sl.registerLazySingleton<GetCartCountUseCase>(
      () => GetCartCountUseCase(sl<CartRepository>()),
    );
  }

  // A factory: one API-backed cart cubit is owned by every authenticated shell.
  // When that shell is disposed on logout/account switching, its snapshot is
  // disposed too and cannot leak into the next session.
  if (!sl.isRegistered<CartCubit>()) {
    sl.registerFactory<CartCubit>(
      () => CartCubit(
        addToCartUseCase: sl<AddToCartUseCase>(),
        updateToCartUseCase: sl<UpdateToCartUseCase>(),
        clearCartUseCase: sl<ClearCartUseCase>(),
        getMyCartUseCase: sl<GetMyCartUseCase>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Favorites
  // ------------------------------------------------------------

  if (!sl.isRegistered<FavoritePaging>()) {
    sl.registerLazySingleton<FavoritePaging>(
      () => const FavoritePaging(
        firstPage: int.fromEnvironment(
          'LUQMA_FAVORITES_FIRST_PAGE',
          defaultValue: 1,
        ),
        pageSize: int.fromEnvironment(
          'LUQMA_FAVORITES_PAGE_SIZE',
          defaultValue: 20,
        ),
      ),
    );
  }

  if (!sl.isRegistered<FavoritesRemoteDataSource>()) {
    sl.registerLazySingleton<FavoritesRemoteDataSource>(
      () => FavoritesRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<FavoritesRepository>()) {
    sl.registerLazySingleton<FavoritesRepository>(
      () => FavoritesRepositoryImpl(
        sl<FavoritesRemoteDataSource>(),
        sl<PreferencesStorageService>(),
      ),
    );
  }

  if (!sl.isRegistered<AddToFavoritesUseCase>()) {
    sl.registerLazySingleton<AddToFavoritesUseCase>(
      () => AddToFavoritesUseCase(sl<FavoritesRepository>()),
    );
  }

  if (!sl.isRegistered<RemoveFromFavoritesUseCase>()) {
    sl.registerLazySingleton<RemoveFromFavoritesUseCase>(
      () => RemoveFromFavoritesUseCase(sl<FavoritesRepository>()),
    );
  }

  if (!sl.isRegistered<GetMyFavoritesUseCase>()) {
    sl.registerLazySingleton<GetMyFavoritesUseCase>(
      () => GetMyFavoritesUseCase(sl<FavoritesRepository>()),
    );
  }

  if (!sl.isRegistered<IsFavoriteUseCase>()) {
    sl.registerLazySingleton<IsFavoriteUseCase>(
      () => IsFavoriteUseCase(sl<FavoritesRepository>()),
    );
  }

  if (!sl.isRegistered<GetFavoritesCountUseCase>()) {
    sl.registerLazySingleton<GetFavoritesCountUseCase>(
      () => GetFavoritesCountUseCase(sl<FavoritesRepository>()),
    );
  }

  // A shell-local factory prevents Favorites data crossing logout or account
  // changes, while all visible hearts share one instance in that shell.
  if (!sl.isRegistered<FavoritesCubit>()) {
    sl.registerFactory<FavoritesCubit>(
      () => FavoritesCubit(
        addToFavoritesUseCase: sl<AddToFavoritesUseCase>(),
        removeFromFavoritesUseCase: sl<RemoveFromFavoritesUseCase>(),
        getMyFavoritesUseCase: sl<GetMyFavoritesUseCase>(),
        paging: sl<FavoritePaging>(),
        repository: sl<FavoritesRepository>(),
        getAuthenticatedUserId: sl<SecureStorageService>().getUserId,
      ),
    );
  }

  // ------------------------------------------------------------
  // Public customer catalog (independent of the existing startup gates)
  // ------------------------------------------------------------

  if (!sl.isRegistered<CatalogPaging>()) {
    sl.registerLazySingleton<CatalogPaging>(
      () => const CatalogPaging(
        firstPage: int.fromEnvironment(
          'LUQMA_CATALOG_FIRST_PAGE',
          defaultValue: 1,
        ),
        pageSize: int.fromEnvironment(
          'LUQMA_CATALOG_PAGE_SIZE',
          defaultValue: 20,
        ),
      ),
    );
  }

  if (!sl.isRegistered<StoreDiscoveryRemoteDataSource>()) {
    sl.registerLazySingleton<StoreDiscoveryRemoteDataSource>(
      () => StoreDiscoveryRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<StoreDiscoveryRepository>()) {
    sl.registerLazySingleton<StoreDiscoveryRepository>(
      () => StoreDiscoveryRepositoryImpl(sl<StoreDiscoveryRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetActiveCuisinesUseCase>()) {
    sl.registerLazySingleton<GetActiveCuisinesUseCase>(
      () => GetActiveCuisinesUseCase(sl<StoreDiscoveryRepository>()),
    );
  }

  if (!sl.isRegistered<GetStoresUseCase>()) {
    sl.registerLazySingleton<GetStoresUseCase>(
      () => GetStoresUseCase(sl<StoreDiscoveryRepository>()),
    );
  }

  if (!sl.isRegistered<StoreDiscoveryCubit>()) {
    sl.registerFactoryParam<StoreDiscoveryCubit, String, void>(
      (mainCategoryId, _) => StoreDiscoveryCubit(
        mainCategoryId: mainCategoryId,
        getActiveCuisines: sl<GetActiveCuisinesUseCase>(),
        getStores: sl<GetStoresUseCase>(),
        paging: sl<CatalogPaging>(),
      ),
    );
  }

  if (!sl.isRegistered<StoreMenuRemoteDataSource>()) {
    sl.registerLazySingleton<StoreMenuRemoteDataSource>(
      () => StoreMenuRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<StoreMenuRepository>()) {
    sl.registerLazySingleton<StoreMenuRepository>(
      () => StoreMenuRepositoryImpl(sl<StoreMenuRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetActiveMenuCategoriesUseCase>()) {
    sl.registerLazySingleton<GetActiveMenuCategoriesUseCase>(
      () => GetActiveMenuCategoriesUseCase(sl<StoreMenuRepository>()),
    );
  }

  if (!sl.isRegistered<GetMenuItemsUseCase>()) {
    sl.registerLazySingleton<GetMenuItemsUseCase>(
      () => GetMenuItemsUseCase(sl<StoreMenuRepository>()),
    );
  }

  if (!sl.isRegistered<StoreMenuCubit>()) {
    sl.registerFactoryParam<StoreMenuCubit, String, void>(
      (storeId, _) => StoreMenuCubit(
        storeId: storeId,
        getCategories: sl<GetActiveMenuCategoriesUseCase>(),
        getItems: sl<GetMenuItemsUseCase>(),
        paging: sl<CatalogPaging>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Address
  // ------------------------------------------------------------

  if (!sl.isRegistered<AddressRemoteDataSource>()) {
    sl.registerLazySingleton<AddressRemoteDataSource>(
      () => AddressRemoteDataSourceImpl(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<AddressRepository>()) {
    sl.registerLazySingleton<AddressRepository>(
      () => AddressRepositoryImpl(sl<AddressRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetMyAddressesUseCase>()) {
    sl.registerLazySingleton<GetMyAddressesUseCase>(
      () => GetMyAddressesUseCase(sl<AddressRepository>()),
    );
  }

  if (!sl.isRegistered<CreateAddressUseCase>()) {
    sl.registerLazySingleton<CreateAddressUseCase>(
      () => CreateAddressUseCase(sl<AddressRepository>()),
    );
  }

  // ------------------------------------------------------------
  // Location foundation
  // ------------------------------------------------------------

  if (!sl.isRegistered<LocationDataSource>()) {
    sl.registerLazySingleton<LocationDataSource>(
      GeolocatorLocationDataSource.new,
    );
  }

  if (!sl.isRegistered<LocationRepository>()) {
    sl.registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(
        dataSource: sl<LocationDataSource>(),
        preferencesStorageService: sl<PreferencesStorageService>(),
      ),
    );
  }

  if (!sl.isRegistered<GetCurrentLocationUseCase>()) {
    sl.registerLazySingleton<GetCurrentLocationUseCase>(
      () => GetCurrentLocationUseCase(sl<LocationRepository>()),
    );
  }

  if (!sl.isRegistered<RequestLocationPermissionUseCase>()) {
    sl.registerLazySingleton<RequestLocationPermissionUseCase>(
      () => RequestLocationPermissionUseCase(sl<LocationRepository>()),
    );
  }

  // ------------------------------------------------------------
  // Address Setup Gate (Phase 3 Step 2)
  // ------------------------------------------------------------

  if (!sl.isRegistered<AddressSetupCubit>()) {
    sl.registerFactory<AddressSetupCubit>(
      () =>
          AddressSetupCubit(getMyAddressesUseCase: sl<GetMyAddressesUseCase>()),
    );
  }

  // ------------------------------------------------------------
  // Map Location Picker (Phase 3 Step 3)
  // ------------------------------------------------------------

  if (!sl.isRegistered<MapPickerCubit>()) {
    sl.registerFactory<MapPickerCubit>(
      () => MapPickerCubit(
        getCurrentLocationUseCase: sl<GetCurrentLocationUseCase>(),
        requestLocationPermissionUseCase:
            sl<RequestLocationPermissionUseCase>(),
      ),
    );
  }

  // ------------------------------------------------------------
  // Address Details (Phase C)
  // ------------------------------------------------------------

  if (!sl.isRegistered<AddressFormCubit>()) {
    sl.registerFactoryParam<AddressFormCubit, LocationCoordinates, void>(
      (coordinates, _) => AddressFormCubit(
        createAddressUseCase: sl<CreateAddressUseCase>(),
        coordinates: coordinates,
      ),
    );
  }
}
