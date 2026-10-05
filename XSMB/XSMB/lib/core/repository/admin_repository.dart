import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../constants/app_constants.dart';

class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  // Validate admin token
  Future<bool> checkAdminPermission(String token) async {
    try {
      final response = await _apiClient.post(
        AppConstants.pathAdminCheck,
        data: {'token': token},
      );
      if (response.statusCode == 200) {
        final data = response.data;
        return data['is_admin'] == true;
      }
      return false;
    } catch (e) {
      // If server doesn't respond or offline, assume false
      return false;
    }
  }

  // Trigger artisan commands on Laravel
  Future<String> executeCommand(String cmd) async {
    String path = '';
    switch (cmd) {
      case 'xsmb:live-watch':
        path = AppConstants.pathAdminCrawl;
        break;
      case 'crawl:today':
        path = AppConstants.pathAdminCrawlOnce;
        break;
      case 'stat:calculate':
        path = AppConstants.pathAdminReloadStats;
        break;
      case 'xsmb:extract-analysis':
        path = AppConstants.pathAdminExtractAnalysis;
        break;
      default:
        throw ApiException(message: 'Lệnh không hợp lệ: $cmd');
    }

    try {
      final response = await _apiClient.post(path);
      if (response.statusCode == 200) {
        return response.data['message'] ?? 'Thực hiện lệnh thành công';
      }
      throw ApiException(message: 'Lỗi thực thi lệnh admin');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Không thể kết nối đến máy chủ để chạy lệnh.');
    }
  }
}
