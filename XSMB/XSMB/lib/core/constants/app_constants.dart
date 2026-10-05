class AppConstants {
  static const String appName = 'XSMB Siêu Tốc';
  static const String dbName = 'xsmb_cache.db';
  static const int dbVersion = 3;

  // API Endpoints
  static const String pathLatestResult = '/xsmb/today';
  static const String pathLiveDraw = '/xsmb/live';
  static const String pathAnalysis = '/xsmb/analysis';
  static const String pathLoGan = '/xsmb/logan';
  static const String pathDauDuoi = '/xsmb/dauduoi';
  static const String pathHistory = '/xsmb/history';
  static const String pathAdminCrawl = '/admin/commands/crawl';
  static const String pathAdminCrawlOnce = '/admin/commands/crawl-once';
  static const String pathAdminReloadStats = '/admin/commands/reload-stats';
  static const String pathAdminExtractAnalysis = '/admin/commands/extract-analysis';
  static const String pathAdminCheck = '/admin/auth/check';

  // Prize mapping labels in XSMB
  static const Map<String, String> prizeLabels = {
    'db': 'Đặc Biệt',
    'g1': 'Giải Nhất',
    'g2': 'Giải Nhì',
    'g3': 'Giải Ba',
    'g4': 'Giải Tư',
    'g5': 'Giải Năm',
    'g6': 'Giải Sáu',
    'g7': 'Giải Bảy',
  };

  // Size of prizes (number of elements in each prize)
  static const Map<String, int> prizeCounts = {
    'db': 1, // 1 prize of 5 digits
    'g1': 1, // 1 prize of 5 digits
    'g2': 2, // 2 prizes of 5 digits
    'g3': 6, // 6 prizes of 5 digits
    'g4': 4, // 4 prizes of 4 digits
    'g5': 6, // 6 prizes of 4 digits
    'g6': 3, // 3 prizes of 3 digits
    'g7': 4, // 4 prizes of 2 digits
  };

  static const List<String> prizeOrder = ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'db'];
}
