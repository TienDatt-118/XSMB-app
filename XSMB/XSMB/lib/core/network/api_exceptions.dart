import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic responseData;

  ApiException({required this.message, this.statusCode, this.responseData});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  factory ApiException.fromDioError(DioException dioError) {
    String message = 'Đã xảy ra lỗi không xác định';
    int? statusCode = dioError.response?.statusCode;
    dynamic responseData = dioError.response?.data;

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Yêu cầu gửi đi bị quá thời gian.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Nhận phản hồi từ máy chủ bị quá thời gian.';
        break;
      case DioExceptionType.badResponse:
        if (statusCode == 400) {
          message = responseData?['message'] ?? 'Yêu cầu không hợp lệ.';
        } else if (statusCode == 401) {
          message = 'Không có quyền truy cập. Token không hợp lệ.';
        } else if (statusCode == 403) {
          message = 'Tài khoản không có quyền thực hiện thao tác này.';
        } else if (statusCode == 404) {
          message = 'Không tìm thấy dữ liệu yêu cầu.';
        } else if (statusCode == 500) {
          message = 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.';
        } else {
          message = responseData?['message'] ?? 'Máy chủ trả về mã lỗi: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Yêu cầu đã bị hủy.';
        break;
      case DioExceptionType.connectionError:
        message = 'Không có kết nối mạng. Vui lòng kiểm tra Wifi/4G.';
        break;
      case DioExceptionType.unknown:
      default:
        message = dioError.message ?? 'Đã xảy ra lỗi kết nối mạng.';
        break;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      responseData: responseData,
    );
  }
}
