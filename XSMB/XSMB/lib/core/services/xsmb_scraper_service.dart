import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../utils/time_utils.dart';
import '../network/api_exceptions.dart';

class XsmbScraperService {
  final Dio _dio;

  XsmbScraperService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'User-Agent':
                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml',
              },
            ));

  /// Fetch today's result by scraping from minhngoc (stable structure)
  Future<LotteryResult> fetchTodayResult() async {
    try {
      // Dùng URL của minhngoc vì cấu trúc DOM của họ cực kỳ ổn định và dễ bóc tách
      final String targetUrl = 'https://www.minhngoc.net.vn/ket-qua-xo-so/mien-bac.html';
      final String url = kIsWeb ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}' : targetUrl;
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final document = parse(response.data);
        
        // Minh Ngọc thường chứa kết quả trong các class như: giaidb, giai1, giai2...
        String extractPrize(String className) {
          final elements = document.getElementsByClassName(className);
          if (elements.isEmpty) return '';
          // Lấy text và xóa các khoảng trắng thừa
          return elements.first.text.replaceAll('-', ',').replaceAll(' ', '').trim();
        }

        List<String> extractList(String className) {
          final text = extractPrize(className);
          if (text.isEmpty) return [];
          // Các số thường cách nhau bởi dấu phẩy, dấu gạch ngang hoặc khoảng trắng nếu dùng .text
          // Nhưng .text của minhngoc thường dính liền hoặc cách nhau khoảng trắng. 
          // Chúng ta sẽ parse cẩn thận hơn bằng cách tìm tất cả các thẻ <div> chứa số bên trong.
          final elements = document.getElementsByClassName(className);
          if (elements.isEmpty) return [];
          final divs = elements.first.querySelectorAll('div');
          if (divs.isNotEmpty) {
             return divs.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
          }
          // Fallback nếu không có thẻ div con
          return text.split(',').where((e) => e.isNotEmpty).toList();
        }

        // Try parsing date with both '/' and '-'
        String? scrapedDate;
        final titleElements = document.getElementsByClassName('title');
        for (var el in titleElements) {
           final text = el.text;
           final RegExp dateRegExp = RegExp(r'(\d{2})[-/](\d{2})[-/](\d{4})');
           final match = dateRegExp.firstMatch(text);
           if (match != null) {
              scrapedDate = '${match.group(3)}-${match.group(2)}-${match.group(1)}'; // yyyy-MM-dd
              break;
           }
        }
        
        if (scrapedDate == null) {
            throw ApiException(message: 'Không tìm thấy ngày quay trong dữ liệu');
        }

        final db = extractPrize('giaidb');
        final g1 = extractPrize('giai1');
        final g2 = extractList('giai2');
        final g3 = extractList('giai3');
        final g4 = extractList('giai4');
        final g5 = extractList('giai5');
        final g6 = extractList('giai6');
        final g7 = extractList('giai7');

        // Kiểm tra xem có dữ liệu chưa
        // Trong giờ quay (18:15-18:35), cho phép dữ liệu partial (một số giải chưa có)
        final nowVN = TimeUtils.nowVN;
        final isDrawWindow = nowVN.hour == 18 && nowVN.minute >= 15 && nowVN.minute <= 35;
        bool hasData = db.isNotEmpty || g1.isNotEmpty || g2.isNotEmpty || 
                       g3.isNotEmpty || g4.isNotEmpty || g5.isNotEmpty || 
                       g6.isNotEmpty || g7.isNotEmpty;
        
        if (!hasData && !isDrawWindow) {
          throw ApiException(message: 'Chưa có kết quả hoặc web thay đổi giao diện');
        }

        return LotteryResult(
          drawDate: scrapedDate,
          db: db,
          g1: g1,
          g2: g2,
          g3: g3,
          g4: g4,
          g5: g5,
          g6: g6,
          g7: g7,
          isLive: TimeUtils.nowVN.hour == 18 && TimeUtils.nowVN.minute >= 15 && TimeUtils.nowVN.minute <= 35,
          createdAt: TimeUtils.nowVN.toIso8601String(),
        );
      }
      
      throw ApiException(message: 'Không thể kết nối đến trang xổ số');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Lỗi lấy dữ liệu từ web: $e');
    }
  }

  /// Fetch result for a specific date
  Future<LotteryResult> fetchResultByDate(DateTime date) async {
    try {
      final dateStr = '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      final String targetUrl = 'https://www.minhngoc.net.vn/ket-qua-xo-so/mien-bac/$dateStr.html';
      final String url = kIsWeb ? 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(targetUrl)}' : targetUrl;
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final document = parse(response.data);
        
        String extractPrize(String className) {
          final elements = document.getElementsByClassName(className);
          if (elements.isEmpty) return '';
          return elements.first.text.replaceAll('-', ',').replaceAll(' ', '').trim();
        }

        List<String> extractList(String className) {
          final text = extractPrize(className);
          if (text.isEmpty) return [];
          final elements = document.getElementsByClassName(className);
          if (elements.isEmpty) return [];
          final divs = elements.first.querySelectorAll('div');
          if (divs.isNotEmpty) {
             return divs.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
          }
          return text.split(',').where((e) => e.isNotEmpty).toList();
        }

        final db = extractPrize('giaidb');
        final g1 = extractPrize('giai1');
        
        if (db.isEmpty && g1.isEmpty) {
          throw ApiException(message: 'Không có dữ liệu cho ngày này');
        }

        // Kiểm tra xem ngày trên web có đúng với ngày đang yêu cầu không (phòng trường hợp web trả về ngày hôm qua)
        bool dateMatches = false;
        final titleElements = document.getElementsByClassName('title');
        for (var el in titleElements) {
          if (el.text.contains(dateStr.replaceAll('-', '/'))) {
            dateMatches = true;
            break;
          }
        }
        
        if (!dateMatches) {
           throw ApiException(message: 'Chưa có kết quả cho ngày này');
        }

        return LotteryResult(
          drawDate: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          db: db,
          g1: g1,
          g2: extractList('giai2'),
          g3: extractList('giai3'),
          g4: extractList('giai4'),
          g5: extractList('giai5'),
          g6: extractList('giai6'),
          g7: extractList('giai7'),
          isLive: false,
          createdAt: DateTime.now().toIso8601String(),
        );
      }
      throw ApiException(message: 'Lỗi tải trang');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Lỗi parse dữ liệu: $e');
    }
  }
}
