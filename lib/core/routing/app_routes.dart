abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verification = '/verification';
  static const String home = '/home';
  static const String storeDiscovery = '/stores';
  static const String storeDetails = '/store-details';
  static const String addressSetup = '/address-setup';
  static const String mapPicker = '/map-picker';
  static const String addressDetails = '/address-details';

  /// Edits an existing address (`PUT /api/Address/Update/{id}`); the argument is
  /// the stored `Address` and the route result is the updated one.
  static const String addressEdit = '/address-edit';
}
