class AppConfig {
  static const String appName = 'Glasnik';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String apiBaseUrl = 'https://api.glasnik.app';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  
  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableBiometrics = true;
  static const bool enableQrScanner = true;
  
  // Cache Configuration
  static const Duration cacheValidityDuration = Duration(hours: 24);
  static const int maxCacheSize = 50 * 1024 * 1024; // 50 MB
} 