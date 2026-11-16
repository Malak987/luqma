abstract final class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://luqma-api.runasp.net';

  static const String account = '/api/Account';
  static const String address = '/api/Address';
  static const String mainCategory = '/api/MainCategory';
  static const String cart = '/api/Cart';

  // Customer catalog
  static const String getAllMainCategories = '$mainCategory/GetAll';
  static const String getAllCuisines = '/api/Cuisine/GetAll';
  static const String getAllStores = '/api/Store/GetAll';
  static const String getAllMenuCategories = '/api/MenuCategory/GetAll';
  static const String getAllMenuItems = '/api/MenuItem/GetAll';

  // Address
  static const String getMyAddresses = '$address/GetMyAddresses';
  static const String createAddress = '$address/Create';

  // Cart
  static const String addToCart = '$cart/AddToCart';
  static const String updateToCart = '$cart/UpdateToCart';
  static const String getMyCart = '$cart/GetMyCart';
  static const String getCartCount = '$cart/GetCount';

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
