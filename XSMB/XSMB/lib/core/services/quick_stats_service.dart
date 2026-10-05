import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' show parse;
import '../models/models.dart';

class QuickStatsService {
  final Dio _dio;

  QuickStatsService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                },
              ),
            );

  /// Fetch Quick Stats from RongBachKim cache HTML
  Future<QuickStatsData?> fetchFromWeb(DateTime date) async {
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final url = 'https://rongbachkim.net/cache/tknhanh/tknhanh_$dateStr.htm';

    try {
      final response = await _dio.get(url);
      if (response.statusCode == 200 && response.data != null) {
        final htmlContent = response.data.toString();
        if (htmlContent.contains('THỐNG KÊ NHANH')) {
          return _parseWebHtml(htmlContent, dateStr);
        }
      }
    } catch (e) {
      debugPrint('QuickStatsService: fetchFromWeb error for $dateStr: $e');
    }
    return null;
  }

  /// Parse the HTML returned by RongBachKim's tknhanh
  QuickStatsData _parseWebHtml(String htmlString, String targetDate) {
    final document = parse(htmlString);

    // 1. Target date headline
    String displayDate = targetDate;
    final headline = document.querySelector('div[style*="background:#3a8de0"]');
    if (headline != null) {
      displayDate = headline.text.replaceAll('THỐNG KÊ NHANH CHO NGÀY', '').trim();
    }

    // 2. Lotto gan & Frequency
    final lotoGanList = <LotoGanItem>[];
    final lotoFreqList = <LotoFrequencyItem>[];
    final deGanList = <DeGanItem>[];

    // Distinguish tables based on their preceding headers
    final contentText = document.body?.innerHtml ?? '';

    // Split content by major sections
    final ganSection = _extractSection(contentText, 'Lotto lâu chưa ra', 'Lotto ra nhiều');
    final freqSection = _extractSection(contentText, 'Lotto ra nhiều', 'Các cặp lotto dẫn đầu');
    final deGanSection = _extractSection(contentText, 'Đặc biệt lâu chưa ra', 'Thống kê gan đặc biệt theo tổng');

    // Parse Lotto Gan
    if (ganSection.isNotEmpty) {
      final docGan = parse(ganSection);
      for (var row in docGan.querySelectorAll('tr')) {
        final col1 = row.querySelector('.col1')?.text.trim();
        final col2 = row.querySelector('.col2')?.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
        if (col1 != null && col1.isNotEmpty && col2 != null && col2.isNotEmpty) {
          lotoGanList.add(LotoGanItem(number: col1, days: int.tryParse(col2) ?? 0));
        }
      }
    }

    // Parse Lotto Frequency
    if (freqSection.isNotEmpty) {
      final docFreq = parse(freqSection);
      for (var row in docFreq.querySelectorAll('tr')) {
        final col1 = row.querySelector('.col1')?.text.trim();
        final col2 = row.querySelector('.col2')?.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
        if (col1 != null && col1.isNotEmpty && col2 != null && col2.isNotEmpty) {
          lotoFreqList.add(LotoFrequencyItem(number: col1, count: int.tryParse(col2) ?? 0));
        }
      }
    }

    // Parse Leading Gan
    LeadingGanItem? leadingGan;
    final maxGanEl = document.querySelector('.maxganhilight');
    if (maxGanEl != null) {
      final text = maxGanEl.text;
      // "Cặp số 58 đã 19 ngày chưa ra, cực đại là 35 ngày (từ 02/01/2018 đến 05/02/2018)"
      final numMatch = RegExp(r'Cặp số\s*([0-9]+)').firstMatch(text);
      final daysMatch = RegExp(r'đã\s*([0-9]+)\s*ngày').firstMatch(text);
      final maxMatch = RegExp(r'cực đại là\s*([0-9]+)\s*ngày').firstMatch(text);
      final dateRangeMatch = RegExp(r'từ\s*([0-9/]+)\s*đến\s*([0-9/]+)').firstMatch(text);

      leadingGan = LeadingGanItem(
        number: numMatch?.group(1) ?? (lotoGanList.isNotEmpty ? lotoGanList.first.number : ''),
        currentDays: int.tryParse(daysMatch?.group(1) ?? '') ?? (lotoGanList.isNotEmpty ? lotoGanList.first.days : 0),
        maxDays: int.tryParse(maxMatch?.group(1) ?? '') ?? 0,
        fromDate: dateRangeMatch?.group(1) ?? '',
        toDate: dateRangeMatch?.group(2) ?? '',
      );
    }

    // Parse De Gan
    if (deGanSection.isNotEmpty) {
      final docDeGan = parse(deGanSection);
      for (var row in docDeGan.querySelectorAll('tr')) {
        final col1 = row.querySelector('.col1')?.text.trim();
        final col2 = row.querySelector('.col2')?.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
        if (col1 != null && col1.isNotEmpty && col2 != null && col2.isNotEmpty) {
          deGanList.add(DeGanItem(number: col1, days: int.tryParse(col2) ?? 0));
        }
      }
    }

    // Parse Gan Tong & Gan Cham charts
    final ganTongList = <GanTongItem>[];
    final ganChamList = <GanChamItem>[];
    String topTongDesc = '';
    String topChamDesc = '';

    final tongSection = _extractSection(contentText, 'Thống kê gan đặc biệt theo tổng', 'Thống kê gan đặc biệt theo chạm');
    final chamSection = _extractSection(contentText, 'Thống kê gan đặc biệt theo chạm', '</div></div>');

    if (tongSection.isNotEmpty) {
      final docTong = parse(tongSection);
      final tables = docTong.querySelectorAll('table[style*="display:inline-block"]');
      for (var t in tables) {
        final daysText = t.querySelector('.gandiv2')?.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
        final tongText = t.querySelector('.tongnum')?.text.trim();
        if (daysText != null && tongText != null) {
          final tVal = int.tryParse(tongText) ?? 0;
          ganTongList.add(GanTongItem(
            tong: tVal,
            days: int.tryParse(daysText) ?? 0,
            numbers: _generateNumbersForTong(tVal),
          ));
        }
      }
      topTongDesc = docTong.body?.text.split('Thống kê cho thấy').last.trim() ?? '';
      if (topTongDesc.isNotEmpty) topTongDesc = 'Thống kê cho thấy $topTongDesc';
    }

    if (chamSection.isNotEmpty) {
      final docCham = parse(chamSection);
      final tables = docCham.querySelectorAll('table[style*="display:inline-block"]');
      for (var t in tables) {
        final daysText = t.querySelector('.gandiv2')?.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
        final chamText = t.querySelector('.tongnum')?.text.trim();
        if (daysText != null && chamText != null) {
          final cVal = int.tryParse(chamText) ?? 0;
          ganChamList.add(GanChamItem(
            cham: cVal,
            days: int.tryParse(daysText) ?? 0,
            numbers: _generateNumbersForCham(cVal),
          ));
        }
      }
      topChamDesc = docCham.body?.text.split('Thống kê cho thấy').last.trim() ?? '';
      if (topChamDesc.isNotEmpty) topChamDesc = 'Thống kê cho thấy $topChamDesc';
    }

    // Sort chart lists descending by days
    ganTongList.sort((a, b) => b.days.compareTo(a.days));
    ganChamList.sort((a, b) => b.days.compareTo(a.days));

    return QuickStatsData(
      targetDate: displayDate,
      lotoGanList: lotoGanList,
      lotoFrequencyList: lotoFreqList,
      leadingGan: leadingGan,
      deGanList: deGanList,
      ganTongList: ganTongList,
      ganChamList: ganChamList,
      topTongDesc: topTongDesc,
      topChamDesc: topChamDesc,
      isFromWeb: true,
    );
  }

  String _extractSection(String fullHtml, String startMarker, String endMarker) {
    final startIdx = fullHtml.indexOf(startMarker);
    if (startIdx == -1) return '';
    final endIdx = fullHtml.indexOf(endMarker, startIdx + startMarker.length);
    if (endIdx == -1) return fullHtml.substring(startIdx);
    return fullHtml.substring(startIdx, endIdx);
  }

  /// Generate 10 pairs for a sum/tong (0..9)
  static List<String> _generateNumbersForTong(int tong) {
    final list = <String>[];
    for (int i = 0; i <= 99; i++) {
      final s = i.toString().padLeft(2, '0');
      final d1 = int.parse(s[0]);
      final d2 = int.parse(s[1]);
      if ((d1 + d2) % 10 == tong) {
        list.add(s);
      }
    }
    return list;
  }

  /// Generate 19 pairs for a touch/cham (0..9)
  static List<String> _generateNumbersForCham(int cham) {
    final list = <String>[];
    final cChar = cham.toString();
    for (int i = 0; i <= 99; i++) {
      final s = i.toString().padLeft(2, '0');
      if (s.contains(cChar)) {
        list.add(s);
      }
    }
    return list;
  }

  /// Offline local computation from SQLite database history (synchronous)
  QuickStatsData computeFromLocal({
    required DateTime targetDate,
    required List<LotteryResult> allHistory,
  }) {
    return computeFromLocalStatic(
      QuickStatsComputeParams(
        targetDate: targetDate,
        allHistory: allHistory,
      ),
    );
  }

  /// Offline local computation on background Isolate using Flutter's compute()
  Future<QuickStatsData> computeFromLocalAsync({
    required DateTime targetDate,
    required List<LotteryResult> allHistory,
  }) async {
    return compute(
      _computeQuickStatsWorker,
      QuickStatsComputeParams(
        targetDate: targetDate,
        allHistory: allHistory,
      ),
    );
  }

  /// Static worker function for offline QuickStats calculation
  static QuickStatsData computeFromLocalStatic(QuickStatsComputeParams params) {
    final targetDate = params.targetDate;
    final allHistory = params.allHistory;

    final dateStr =
        "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    // Filter draws on or before targetDate, sorted by date descending
    final history = allHistory.where((d) => d.drawDate.compareTo(dateStr) <= 0).toList();
    history.sort((a, b) => b.drawDate.compareTo(a.drawDate));

    if (history.isEmpty) {
      return QuickStatsData(
        targetDate: dateStr,
        lotoGanList: [],
        lotoFrequencyList: [],
        deGanList: [],
        ganTongList: [],
        ganChamList: [],
        topTongDesc: '',
        topChamDesc: '',
        isFromWeb: false,
      );
    }

    // 1. Compute Loto Gan (days since last appeared in any prize)
    final lotoGanMap = <String, int>{};
    for (int i = 0; i < 100; i++) {
      final numStr = i.toString().padLeft(2, '0');
      int days = 0;

      for (var draw in history) {
        if (draw.allLast2Digits.contains(numStr)) {
          break;
        }
        days++;
      }
      if (days >= 5) {
        lotoGanMap[numStr] = days;
      }
    }

    final lotoGanList = lotoGanMap.entries
        .map((e) => LotoGanItem(number: e.key, days: e.value))
        .toList();
    lotoGanList.sort((a, b) => b.days.compareTo(a.days));

    // 2. Compute Lotto Frequency in the last 30 draws
    final last30Draws = history.take(30).toList();
    final lotoFreqMap = <String, int>{};

    for (var draw in last30Draws) {
      for (var prize in draw.allNumbers) {
        if (prize.length >= 2) {
          final s2 = prize.substring(prize.length - 2);
          lotoFreqMap[s2] = (lotoFreqMap[s2] ?? 0) + 1;
        }
      }
    }

    final lotoFreqList = lotoFreqMap.entries
        .map((e) => LotoFrequencyItem(number: e.key, count: e.value))
        .where((e) => e.count >= 10)
        .toList();
    lotoFreqList.sort((a, b) => b.count.compareTo(a.count));

    // 3. Leading Gan & Historical Max Gan
    LeadingGanItem? leadingGan;
    if (lotoGanList.isNotEmpty) {
      final topNumber = lotoGanList.first.number;
      final currentDays = lotoGanList.first.days;

      // Scan all history to find max consecutive days for this number
      int maxGap = 0;
      int curGap = 0;
      String fromDate = '';
      String toDate = '';
      String tempStart = '';

      for (int i = history.length - 1; i >= 0; i--) {
        final draw = history[i];
        final hit = draw.allLast2Digits.contains(topNumber);
        if (hit) {
          if (curGap > maxGap) {
            maxGap = curGap;
            fromDate = tempStart;
            toDate = draw.drawDate;
          }
          curGap = 0;
          tempStart = draw.drawDate;
        } else {
          curGap++;
        }
      }
      if (curGap > maxGap) maxGap = curGap;

      leadingGan = LeadingGanItem(
        number: topNumber,
        currentDays: currentDays,
        maxDays: maxGap > currentDays ? maxGap : currentDays + 5,
        fromDate: fromDate,
        toDate: toDate,
      );
    }

    // 4. Compute De Gan (Special Prize 2 last digits)
    final deGanMap = <String, int>{};
    for (int i = 0; i < 100; i++) {
      final numStr = i.toString().padLeft(2, '0');
      int days = 0;
      for (var draw in history) {
        if (draw.db.length >= 2) {
          final deStr = draw.db.substring(draw.db.length - 2);
          if (deStr == numStr) {
            break;
          }
        }
        days++;
      }
      if (days >= 100) {
        deGanMap[numStr] = days;
      }
    }

    final deGanList = deGanMap.entries
        .map((e) => DeGanItem(number: e.key, days: e.value))
        .toList();
    deGanList.sort((a, b) => b.days.compareTo(a.days));

    // 5. Gan Special by Tong (0..9)
    final ganTongList = <GanTongItem>[];
    for (int t = 0; t <= 9; t++) {
      int days = 0;
      for (var draw in history) {
        if (draw.db.length >= 2) {
          final d1 = int.tryParse(draw.db[draw.db.length - 2]) ?? 0;
          final d2 = int.tryParse(draw.db[draw.db.length - 1]) ?? 0;
          if ((d1 + d2) % 10 == t) {
            break;
          }
        }
        days++;
      }
      ganTongList.add(GanTongItem(
        tong: t,
        days: days,
        numbers: _generateNumbersForTong(t),
      ));
    }
    ganTongList.sort((a, b) => b.days.compareTo(a.days));
    final topTong = ganTongList.isNotEmpty ? ganTongList.first : null;
    final topTongDesc = topTong != null
        ? "Thống kê cho thấy tổng đề lâu chưa xuất hiện nhất là tổng ${topTong.tong} (bao gồm 10 cặp số: ${topTong.numbers.join(', ')}) đã ${topTong.days} ngày chưa ra."
        : '';

    // 6. Gan Special by Cham (0..9)
    final ganChamList = <GanChamItem>[];
    for (int c = 0; c <= 9; c++) {
      final cChar = c.toString();
      int days = 0;
      for (var draw in history) {
        if (draw.db.length >= 2) {
          final s2 = draw.db.substring(draw.db.length - 2);
          if (s2.contains(cChar)) {
            break;
          }
        }
        days++;
      }
      ganChamList.add(GanChamItem(
        cham: c,
        days: days,
        numbers: _generateNumbersForCham(c),
      ));
    }
    ganChamList.sort((a, b) => b.days.compareTo(a.days));
    final topCham = ganChamList.isNotEmpty ? ganChamList.first : null;
    final topChamDesc = topCham != null
        ? 'Thống kê cho thấy chạm đề lâu chưa xuất hiện nhất là chạm ${topCham.cham} (bao gồm 19 cặp số có chứa số ${topCham.cham}) đã ${topCham.days} ngày chưa ra.'
        : '';

    final formattedDate =
        "${targetDate.day.toString().padLeft(2, '0')}/${targetDate.month.toString().padLeft(2, '0')}/${targetDate.year}";

    return QuickStatsData(
      targetDate: formattedDate,
      lotoGanList: lotoGanList,
      lotoFrequencyList: lotoFreqList,
      leadingGan: leadingGan,
      deGanList: deGanList,
      ganTongList: ganTongList,
      ganChamList: ganChamList,
      topTongDesc: topTongDesc,
      topChamDesc: topChamDesc,
      isFromWeb: false,
    );
  }

  /// Hybrid helper: Tries web first; falls back to local computation on background isolate
  Future<QuickStatsData> getQuickStats({
    required DateTime date,
    required List<LotteryResult> localHistory,
  }) async {
    // 1. Try web cache
    final webData = await fetchFromWeb(date);
    if (webData != null && webData.lotoGanList.isNotEmpty) {
      return webData;
    }

    // 2. Fallback to background isolate computation
    return computeFromLocalAsync(targetDate: date, allHistory: localHistory);
  }
}

/// Top-level worker for compute() running QuickStats in background isolate
QuickStatsData _computeQuickStatsWorker(QuickStatsComputeParams params) {
  return QuickStatsService.computeFromLocalStatic(params);
}

/// Parameter container for QuickStats isolate execution
class QuickStatsComputeParams {
  final DateTime targetDate;
  final List<LotteryResult> allHistory;

  const QuickStatsComputeParams({
    required this.targetDate,
    required this.allHistory,
  });
}

