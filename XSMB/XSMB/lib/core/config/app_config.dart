class AppConfig {
  // API URL Config
  static const String defaultBaseUrl = 'https://xsmbsieutoc.vn/api';
  
  // Custom API override stored in SharedPreferences (for testing/development)
  static String baseUrl = defaultBaseUrl;

  // Pusher / WebSocket Config
  static const String pusherAppKey = 'xsmb_pusher_key_123';
  static const String pusherCluster = 'ap1';
  static const String liveDrawChannel = 'xsmb-live-channel';
  static const String liveDrawEvent = 'live-draw-event';

  // Network Settings
  static const int connectTimeoutMs = 15000; // 15 seconds
  static const int receiveTimeoutMs = 15000; // 15 seconds

  // Shared Preferences Keys
  static const String keyBaseUrlOverride = 'api_base_url_override';
  static const String keyAdminToken = 'admin_auth_token';
  static const String keyThemeMode = 'app_theme_mode';
  static const String keyResultsCache = 'results_cache';
  
  // App Version Info
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
}
