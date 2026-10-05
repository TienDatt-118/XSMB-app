import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import '../models/models.dart';
import '../network/api_client.dart';
import '../network/api_exceptions.dart';
import '../services/database_helper.dart';
import '../services/xsmb_scraper_service.dart';

class LotteryRepository {
  final ApiClient _apiClient;
  final DatabaseHelper _dbHelper;
  final XsmbScraperService _scraperService;

  LotteryRepository(this._apiClient, this._dbHelper, this._scraperService);

  ApiClient get apiClient => _apiClient;
  DatabaseHelper get dbHelper => _dbHelper;
  XsmbScraperService get scraperService => _scraperService;

  // Fetch today's result (with local SQLite cache fallback)
  Future<LotteryResult> getTodayResult() async {
    try {
      // Scrape data directly from website instead of backend API
      final result = await _scraperService.fetchTodayResult();
        
      // Cache to SQLite
      await _dbHelper.insertResult(result.toMap());
      return result;
    } catch (e) {
      debugPrint("Repository getTodayResult Scraper Error, loading cache: $e");
      
      // Fallback to SQLite cache (load newest cached result)
      final cachedResults = await _dbHelper.getResultsHistory(limit: 1);
      if (cachedResults.isNotEmpty) {
        return LotteryResult.fromMap(cachedResults.first);
      }
      
      // Fallback: Read directly from CSV if DB is empty
      try {
        final csvString = await rootBundle.loadString('assets/db/xsmb_history.csv');
        final rows = const CsvToListConverter().convert(csvString, eol: '\n');
        if (rows.length > 1) {
          final row = rows[1]; // First row after header
          if (row.length >= 28) {
            String p2 = '${row[3]},${row[4]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
            String p3 = '${row[5]},${row[6]},${row[7]},${row[8]},${row[9]},${row[10]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
            String p4 = '${row[11]},${row[12]},${row[13]},${row[14]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
            String p5 = '${row[15]},${row[16]},${row[17]},${row[18]},${row[19]},${row[20]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
            String p6 = '${row[21]},${row[22]},${row[23]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
            String p7 = '${row[24]},${row[25]},${row[26]},${row[27]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');

            return LotteryResult(
              drawDate: row[0].toString(),
              db: row[1].toString(),
              g1: row[2].toString(),
              g2: p2.split(','),
              g3: p3.split(','),
              g4: p4.split(','),
              g5: p5.split(','),
              g6: p6.split(','),
              g7: p7.split(','),
              isLive: false,
              createdAt: DateTime.now().toIso8601String(),
            );
          }
        }
      } catch (csvError) {
        debugPrint("CSV Fallback error: $csvError");
      }
      
      // If absolutely no local cache, throw network exception
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Không có kết nối mạng và không có dữ liệu cache.');
    }
  }

  // Cleanup polluted data from DB
  Future<void> cleanPollutedData(String date) async {
    try {
      final db = await _dbHelper.database;
      await db.delete('lottery_results', where: 'draw_date = ?', whereArgs: [date]);
    } catch (e) {
      debugPrint("Cleanup error: $e");
    }
  }

  // Fetch result for a specific date
  Future<LotteryResult> getResultByDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().substring(0, 10);
      
      // Try local cache first
      final cachedResult = await _dbHelper.getResultByDate(dateStr);
      if (cachedResult != null) {
        return LotteryResult.fromMap(cachedResult);
      }

      // If not in cache, fetch from scraper
      final result = await _scraperService.fetchResultByDate(date);
      await _dbHelper.insertResult(result.toMap());
      return result;
    } catch (e) {
      debugPrint("Repository getResultByDate Error: $e");
      throw ApiException(message: 'Không thể lấy dữ liệu cho ngày này.');
    }
  }

  // Save result to local SQLite database cache
  Future<void> saveResult(LotteryResult result) async {
    await _dbHelper.insertResult(result.toMap());
  }

  // Scrape latest result directly from website (no cache fallback)
  // Used for live draw polling to get the freshest data
  Future<LotteryResult> scrapeLatestResult() async {
    return await _scraperService.fetchTodayResult();
  }

  // Get history filtered by date range (fallback to CSV if not found in SQLite)
  Future<List<LotteryResult>> getHistoryByDateRange(DateTime from, DateTime to) async {
    final fromStr = from.toIso8601String().substring(0, 10);
    final toStr = to.toIso8601String().substring(0, 10);

    // 1. Query SQLite directly with date range (efficient WHERE clause)
    final rawResults = await _dbHelper.getResultsByDateRange(fromStr, toStr);
    List<LotteryResult> results = rawResults.map((e) => LotteryResult.fromMap(e)).toList();
    
    // Estimate expected days (approximate)
    int expectedDays = to.difference(from).inDays + 1;
    
    // 2. If SQLite doesn't have enough data, read from CSV as fallback
    if (results.length < expectedDays) {
      try {
        final csvString = await rootBundle.loadString('assets/db/xsmb_history.csv');
        final rows = const CsvToListConverter().convert(csvString, eol: '\n');
        
        Set<String> existingDates = results.map((e) => e.drawDate).toSet();
        
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length >= 28) {
            String date = row[0].toString();
            // Check if within range and not already in results
            if (date.compareTo(fromStr) >= 0 && date.compareTo(toStr) <= 0 && !existingDates.contains(date)) {
              String p2 = '${row[3]},${row[4]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
              String p3 = '${row[5]},${row[6]},${row[7]},${row[8]},${row[9]},${row[10]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
              String p4 = '${row[11]},${row[12]},${row[13]},${row[14]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
              String p5 = '${row[15]},${row[16]},${row[17]},${row[18]},${row[19]},${row[20]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
              String p6 = '${row[21]},${row[22]},${row[23]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');
              String p7 = '${row[24]},${row[25]},${row[26]},${row[27]}'.split(',').where((e) => e.trim().isNotEmpty).join(',');

              results.add(LotteryResult(
                drawDate: date,
                db: row[1].toString(),
                g1: row[2].toString(),
                g2: p2.split(','),
                g3: p3.split(','),
                g4: p4.split(','),
                g5: p5.split(','),
                g6: p6.split(','),
                g7: p7.split(','),
                isLive: false,
                createdAt: DateTime.now().toIso8601String(),
              ));
              existingDates.add(date);
            }
          }
        }
      } catch (e) {
        debugPrint("CSV Fallback error in getHistoryByDateRange: $e");
      }
    }
    
    // Sort descending by date (newest first)
    results.sort((a, b) => b.drawDate.compareTo(a.drawDate));
    return results;
  }

  // Calculate analysis data locally (Top numbers in last 30 days)
  Future<LotteryAnalysis> getAnalysisDashboard() async {
    final rawResults = await _dbHelper.getResultsHistory(limit: 30);
    final results = rawResults.map((e) => LotteryResult.fromMap(e)).toList();
    
    if (results.isEmpty) {
      throw ApiException(message: 'Không có dữ liệu lịch sử để phân tích');
    }

    final Map<String, List<int>> frequencies = {};
    final Map<String, int> counts = {};
    for (int i = 0; i < 100; i++) {
      final numStr = i.toString().padLeft(2, '0');
      frequencies[numStr] = [];
      counts[numStr] = 0;
    }

    final Map<String, int> modulo4 = {'mod_0': 0, 'mod_1': 0, 'mod_2': 0, 'mod_3': 0};

    // Calculate occurrences
    for (var result in results) {
      for (var numStr in result.allNumbers) {
        if (numStr.length >= 2) {
          final last2Str = numStr.substring(numStr.length - 2);
          final last2Val = int.parse(last2Str);
          
          if (counts.containsKey(last2Str)) {
            counts[last2Str] = counts[last2Str]! + 1;
          }
          
          final rem = last2Val % 4;
          modulo4['mod_$rem'] = (modulo4['mod_$rem'] ?? 0) + 1;
        }
      }
    }

    // Sort numbers by occurrence count
    final sortedNumbers = counts.keys.toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    final List<String> numbers25 = sortedNumbers.take(25).toList();
    final List<String> numbers20 = sortedNumbers.take(20).toList();
    final List<String> hotNumbers = sortedNumbers.take(5).toList();
    final List<String> coldNumbers = sortedNumbers.reversed.take(5).toList();

    final List<String> set4 = ['01, 10, 25, 52', '08, 80, 45, 54', '12, 21, 68, 86', '37, 73, 19, 91'];
    final List<String> set5 = ['02, 20, 35, 53, 09', '14, 41, 78, 87, 23', '07, 70, 89, 98, 56'];

    final String matrixHeatmapJson = jsonEncode(counts);

    final List<String> suggestions = [
      'Cặp số ${hotNumbers.isNotEmpty ? hotNumbers[0] : "00"} xuất hiện nhiều nhất trong 30 ngày qua.',
      'Bộ số ${coldNumbers.isNotEmpty ? coldNumbers[0] : "99"} hiện đang ít xuất hiện nhất (lô khan).',
      'Thống kê Modulo 4 cho thấy nhóm Dư ${modulo4.entries.reduce((a, b) => a.value > b.value ? a : b).key.split('_')[1]} chiếm ưu thế.',
    ];

    return LotteryAnalysis(
      frequencies: frequencies,
      numbers25: numbers25,
      numbers20: numbers20,
      set4: set4,
      set5: set5,
      modulo4: modulo4,
      hotNumbers: hotNumbers,
      coldNumbers: coldNumbers,
      suggestions: suggestions,
      matrixHeatmapJson: matrixHeatmapJson,
    );
  }

  // Calculate Lo Gan (Max missing days for 00-99)
  Future<List<LoGanModel>> getLoGanList() async {
    final rawResults = await _dbHelper.getResultsHistory(limit: 1000);
    final results = rawResults.map((e) => LotteryResult.fromMap(e)).toList();
    
    if (results.isEmpty) {
      throw ApiException(message: 'Chưa có dữ liệu để tính Lô gan');
    }

    Map<String, int> ganCount = {};
    for (int i = 0; i < 100; i++) {
      ganCount[i.toString().padLeft(2, '0')] = 0;
    }

    Map<String, bool> found = {};
    for (var result in results) {
      final tails = result.allLast2Digits; // O(1) set lookup
      for (int i = 0; i < 100; i++) {
        String numStr = i.toString().padLeft(2, '0');
        if (!found.containsKey(numStr)) {
          if (tails.contains(numStr)) {
            found[numStr] = true;
          } else {
            ganCount[numStr] = ganCount[numStr]! + 1;
          }
        }
      }
      if (found.length == 100) break;
    }

    List<LoGanModel> list = [];
    ganCount.forEach((number, days) {
      if (days > 5) {
        list.add(LoGanModel(
          number: number,
          missingDays: days,
          maxMissingDays: days + 5,
          lastDrawnDate: '',
        ));
      }
    });

    list.sort((a, b) => b.missingDays.compareTo(a.missingDays));
    return list;
  }

  // Calculate Head-Tail frequency locally
  Future<Map<String, List<HeadTailModel>>> getHeadTailStats() async {
    final rawResults = await _dbHelper.getResultsHistory(limit: 30);
    final results = rawResults.map((e) => LotteryResult.fromMap(e)).toList();
    
    Map<String, List<HeadTailModel>> stats = {
      'head': [],
      'tail': []
    };

    if (results.isEmpty) return stats;

    List<int> headCounts = List.filled(10, 0);
    List<int> tailCounts = List.filled(10, 0);
    int totalPrizes = 0;

    for (var result in results) {
      final allLoto = result.allNumbers;
      for (String loto in allLoto) {
        if (loto.length >= 2) {
          int h = int.parse(loto[loto.length - 2]);
          int t = int.parse(loto[loto.length - 1]);
          headCounts[h]++;
          tailCounts[t]++;
          totalPrizes++;
        }
      }
    }

    for (int i = 0; i < 10; i++) {
      stats['head']!.add(HeadTailModel(
        digit: i,
        count: headCounts[i],
        percentage: totalPrizes > 0 ? (headCounts[i] / totalPrizes * 100) : 0,
      ));
      stats['tail']!.add(HeadTailModel(
        digit: i,
        count: tailCounts[i],
        percentage: totalPrizes > 0 ? (tailCounts[i] / totalPrizes * 100) : 0,
      ));
    }

    return stats;
  }

  // Fetch draw history directly from SQLite
  Future<List<LotteryResult>> getHistoryResults({required int page, int limit = 20}) async {
    final offset = (page - 1) * limit;
    final cachedList = await _dbHelper.getResultsHistory(limit: limit, offset: offset);
    return cachedList.map((map) => LotteryResult.fromMap(map)).toList();
  }
}
