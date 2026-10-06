abstract final class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://luqma-api.runasp.net';

  static const String account = '/api/Account';

  // Authentication
  static const String register = '$account/Register';
  static const String login = '$account/Login';
  static const String loginWithFacebook = '$account/LoginWithFacebook';
  static const String loginWithApple = '$account/LoginWithApple';
  static const String loginWithGoogle = '$account/LoginWithGoogle';
  static const String logout = '$account/Logout';

  // Email verification
  static const String confirmEmail = '$account/ConfirmEmail';
  static const String resendOtp = '$account/ResendOtp';

  // Password
  static const String forgotPassword = '$account/ForgotPassword';
  static const String resetPassword = '$account/ResetPassword';

  // Profile
  static const String getProfile = '$account/GetProfile';
  static const String updateProfile = '$account/UpdateProfile';

  // Admin
  static const String getAllUsers = '$account/GetAllUsers';

  static String getUserById(String id) {
    return '$account/GetUserById/$id';
  }

  static String archiveUser(String id) {
    return '$account/ArchiveUser/$id';
  }

  static String unarchiveUser(String id) {
    return '$account/UnarchiveUser/$id';
  }
}
