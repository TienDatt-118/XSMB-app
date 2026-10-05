import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storageService;

  Dio get dio => _dio;

  ApiClient(this._storageService)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.baseUrl,
            connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
            receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _initInterceptors();
  }

  void _initInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Dynamic baseUrl update (in case custom base url was configured by the user/admin)
          options.baseUrl = AppConfig.baseUrl;

          // Inject admin token if exists in storage
          final token = await _storageService.getAdminToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final apiException = ApiException.fromDioError(error);
          return handler.next(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: apiException,
              message: apiException.message,
            ),
          );
        },
      ),
    );
  }

  // Generic Get request wrapper
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Đã xảy ra lỗi khi tải dữ liệu');
    } catch (e) {
      throw ApiException(message: 'Lỗi hệ thống: $e');
    }
  }

  // Generic Post request wrapper
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      if (e.error is ApiException) {
        throw e.error as ApiException;
      }
      throw ApiException(message: e.message ?? 'Đã xảy ra lỗi khi gửi yêu cầu');
    } catch (e) {
      throw ApiException(message: 'Lỗi hệ thống: $e');
    }
  }
}
