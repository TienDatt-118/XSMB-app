import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class TimeUtils {
  static bool _initialized = false;

  static Future<void> init() async {
    if (!_initialized) {
      await initializeDateFormatting('vi_VN', null);
      _initialized = true;
    }
  }

  /// Get current time in Vietnam timezone (UTC+7)
  static DateTime get nowVN {
    // Luôn lấy UTC rồi cộng thêm 7 tiếng bất chấp thiết bị đang ở đâu
    return DateTime.now().toUtc().add(const Duration(hours: 7));
  }

  /// Check if current time is after today's draw time (e.g. 18:30)
  static bool get isAfterTodayDraw {
    final now = nowVN;
    // Quay lúc 18h15 - 18h30. Coi 18:30 là xong.
    if (now.hour > 18 || (now.hour == 18 && now.minute >= 30)) {
      return true;
    }
    return false;
  }

  /// Format date to yyyy-MM-dd using VN time
  static String formatToYYYYMMDD(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Return today's string format (e.g., "2026-06-25")
  static String get todayString {
    return formatToYYYYMMDD(nowVN);
  }

  /// Convert any date string (yyyy-MM-dd or dd-MM-yyyy) to display format (dd/MM/yyyy)
  static String formatDisplayDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      if (dateStr.contains('/')) return dateStr;
      List<String> parts = dateStr.split('-');
      if (parts.length == 3) {
        if (parts[0].length == 4) {
          // yyyy-MM-dd -> dd/MM/yyyy
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        } else {
          // dd-MM-yyyy -> dd/MM/yyyy
          return '${parts[0]}/${parts[1]}/${parts[2]}';
        }
      }
    } catch (_) {}
    return dateStr;
  }
}
