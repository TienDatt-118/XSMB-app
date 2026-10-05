import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../repository/lottery_repository.dart';
import '../services/pusher_service.dart';
import '../services/notification_service.dart';
import '../models/deep_analysis_model.dart';
import '../models/strategy_analysis_model.dart';
import '../constants/app_constants.dart';
import '../utils/time_utils.dart';
import '../utils/csv_helper.dart';
import '../services/quick_stats_service.dart';
import '../services/soi_cau_service.dart';

class LotteryProvider extends ChangeNotifier {
  final LotteryRepository _repository;
  final PusherService _pusherService;
  final NotificationService _notificationService;

  LotteryProvider(this._repository, this._pusherService, this._notificationService) {
    _startCountdownTimer();
    checkMissingDates();
  }

  PusherService get pusherService => _pusherService;
  final QuickStatsService _quickStatsService = QuickStatsService();
  QuickStatsService get quickStatsService => _quickStatsService;

  final SoiCauService _soiCauService = SoiCauService();
  SoiCauService get soiCauService => _soiCauService;

  QuickStatsData? _quickStatsData;
  QuickStatsData? get quickStatsData => _quickStatsData;
  bool _isLoadingQuickStats = false;
  bool get isLoadingQuickStats => _isLoadingQuickStats;

  List<DateTime> _missingDates = [];
  List<DateTime> get missingDates => _missingDates;
  bool _isSyncingMissingData = false;
  bool get isSyncingMissingData => _isSyncingMissingData;

  // Soi Cầu state
  SoiCauResult? _soiCauResult;
  SoiCauResult? get soiCauResult => _soiCauResult;
  bool _isLoadingSoiCau = false;
  bool get isLoadingSoiCau => _isLoadingSoiCau;

  int _soiCauLimit = 3;
  int get soiCauLimit => _soiCauLimit;
  int _soiCauExactLimit = 0;
  int get soiCauExactLimit => _soiCauExactLimit;
  int _soiCauNhay = 1;
  int get soiCauNhay => _soiCauNhay;
  bool _soiCauIsDb = false;
  bool get soiCauIsDb => _soiCauIsDb;
  bool _soiCauIsLon = true;
  bool get soiCauIsLon => _soiCauIsLon;
  String? _soiCauSearchNum;
  String? get soiCauSearchNum => _soiCauSearchNum;

  CauDetail? _currentCauDetail;
  CauDetail? get currentCauDetail => _currentCauDetail;
  bool _isLoadingCauDetail = false;
  bool get isLoadingCauDetail => _isLoadingCauDetail;

  // Loading States
  bool _isLoadingToday = false;
  bool _isLoadingAnalysis = false;
  bool _isLoadingLoGan = false;
  bool _isLoadingDauDuoi = false;
  bool _isLoadingHistory = false;
  bool _isOffline = false;

  bool get isLoadingToday => _isLoadingToday;
  bool get isLoadingAnalysis => _isLoadingAnalysis;
  bool get isLoadingLoGan => _isLoadingLoGan;
  bool get isLoadingDauDuoi => _isLoadingDauDuoi;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isOffline => _isOffline;
  
  bool _isLoadingDeepAnalysis = false;
  bool get isLoadingDeepAnalysis => _isLoadingDeepAnalysis;

  // --- Lo Top (Yesterday & Today) ---
  List<LoTopItem> _yesterdayTop = [];
  List<LoTopItem> get yesterdayTop => _yesterdayTop;

  List<LoTopItem> _todayTop = [];
  List<LoTopItem> get todayTop => _todayTop;

  bool _isLoadingLoTop = false;
  bool get isLoadingLoTop => _isLoadingLoTop;

  Map<String, int>? _loTopFreqsCache;

  // Data Objects
  LotteryResult? _todayResult;
  LotteryAnalysis? _analysis;
  List<LoGanModel> _loGanList = [];
  Map<String, List<HeadTailModel>> _headTailStats = {};
  final List<LotteryResult> _historyResults = [];
  List<LotteryResult> _rangeHistoryResults = [];
  CauStats? _cauStats;
  ThongKeData? _thongKeData;
  DeepAnalysisData? _deepAnalysisData;

  // Strategy Analysis state
  List<StrategyData>? _strategyData25;
  List<StrategyData>? _strategyData20;
  Map<String, int>? _ganGdbTail;
  bool _isLoadingStrategy = false;

  // History Dates state
  DateTime _historyFromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _historyToDate = DateTime.now();

  DateTime get historyFromDate => _historyFromDate;
  DateTime get historyToDate => _historyToDate;

  void setHistoryDates(DateTime from, DateTime to) {
    _historyFromDate = from;
    _historyToDate = to;
    notifyListeners();
  }
  
  LotteryResult? get todayResult => _todayResult;
  LotteryAnalysis? get analysis => _analysis;
  List<LoGanModel> get loGanList => _loGanList;
  Map<String, List<HeadTailModel>> get headTailStats => _headTailStats;
  List<LotteryResult> get historyResults => _historyResults;
  List<LotteryResult> get rangeHistoryResults => _rangeHistoryResults;
  CauStats? get cauStats => _cauStats;
  ThongKeData? get thongKeData => _thongKeData;
  bool get isLoadingStrategy => _isLoadingStrategy;
  Map<String, int>? get ganGdbTail => _ganGdbTail;
  List<StrategyData>? getStrategyData(int mode) => mode == 25 ? _strategyData25 : _strategyData20;
  DeepAnalysisData? get deepAnalysisData => _deepAnalysisData;

  // Live Draw state
  LotteryResult? _liveResult;
  bool _isLiveDrawing = false;
  String _liveDrawingPrize = '';
  int _liveDrawingIndex = -1;
  String _liveRollingValue = '';
  StreamSubscription? _pusherSubscription;
  Timer? _scrapeTimer;
  bool _isScraping = false;

  LotteryResult? get liveResult => _liveResult;
  bool get isLiveDrawing => _isLiveDrawing;
  String get liveDrawingPrize => _liveDrawingPrize;
  int get liveDrawingIndex => _liveDrawingIndex;
  String get liveRollingValue => _liveRollingValue;

  // Countdown timer till 18:15 today — uses ValueNotifier to avoid
  // rebuilding the entire widget tree every second
  Timer? _countdownTimer;
  final ValueNotifier<String> countdownNotifier = ValueNotifier<String>('00:00:00');
  Duration _timeLeft = Duration.zero;

  Duration get timeLeft => _timeLeft;
  String get countdownString => countdownNotifier.value;

  // Fetch Today's Result
  Future<void> fetchTodayResult({bool silent = false}) async {
    if (!silent) {
      _isLoadingToday = true;
      notifyListeners();
    }

    try {
      _todayResult = await _repository.getTodayResult();
      if (_todayResult != null) {
        await CsvHelper.appendResultToCsv(_todayResult!);
      }
      _updateTodayTopIfNeeded();
      await _calculateCauStats();
      _isOffline = false;
      
      _syncRecentMissingDays();
    } catch (e) {
      _isOffline = true;
      debugPrint('Fetch today result error: $e');
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  Future<void> _syncRecentMissingDays() async {
    try {
      final now = TimeUtils.nowVN;
      bool hasNewData = false;
      for (int i = 1; i <= 5; i++) {
        final d = now.subtract(Duration(days: i));
        final dateStr = d.toIso8601String().substring(0, 10);
        final cached = await _repository.dbHelper.getResultByDate(dateStr);
        if (cached == null) {
          try {
             final result = await _repository.scraperService.fetchResultByDate(d);
             await _repository.saveResult(result);
             await CsvHelper.appendResultToCsv(result);
             hasNewData = true;
          } catch (e) {
             debugPrint('Sync date $dateStr failed: $e');
          }
        }
      }
      if (hasNewData) {
        fetchHistoryRange(now.subtract(const Duration(days: 30)), now);
      }
    } catch (e) {
      debugPrint('Sync missing days error: $e');
    }
  }

  // Fetch Result by Date
  Future<void> fetchResultByDate(DateTime date, {bool silent = false}) async {
    if (!silent) {
      _isLoadingToday = true;
      notifyListeners();
    }

    try {
      final now = TimeUtils.nowVN;
      final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
      
      // Nếu là hôm nay và chưa đến giờ quay, không gọi repository để tránh lấy nhầm dữ liệu hôm qua từ web
      if (isToday && (now.hour < 18 || (now.hour == 18 && now.minute < 15))) {
        _todayResult = null;
        _isOffline = false;
      } else {
        _todayResult = await _repository.getResultByDate(date);
        await _calculateCauStats();
        _isOffline = false;
      }
      fetchQuickStats(date, silent: silent);
      checkMissingDates();
    } catch (e) {
      _todayResult = null; // Clear data on error
      _isOffline = true;
      debugPrint('Fetch result by date error: $e');
    } finally {
      _isLoadingToday = false;
      notifyListeners();
    }
  }

  // Fetch Quick Stats (Hybrid: Web cache + SQLite local fallback)
  Future<void> fetchQuickStats(DateTime date, {bool silent = false}) async {
    if (!silent) {
      _isLoadingQuickStats = true;
      notifyListeners();
    }
    try {
      final historyRaw = await _repository.dbHelper.getResultsHistory(limit: 500);
      final history = historyRaw.map((e) => LotteryResult.fromMap(e)).toList();
      _quickStatsData = await _quickStatsService.getQuickStats(
        date: date,
        localHistory: history,
      );
    } catch (e) {
      debugPrint('Error fetching quick stats: $e');
    } finally {
      _isLoadingQuickStats = false;
      notifyListeners();
    }
  }

  // Check for missing draw dates in the last 30 days (single batch query)
  Future<void> checkMissingDates() async {
    try {
      final now = TimeUtils.nowVN;
      DateTime checkEnd = DateTime(now.year, now.month, now.day);
      if (now.hour < 18 || (now.hour == 18 && now.minute < 15)) {
        checkEnd = checkEnd.subtract(const Duration(days: 1));
      }

      final checkStart = checkEnd.subtract(const Duration(days: 29));
      final fromStr = '${checkStart.year.toString().padLeft(4, '0')}-${checkStart.month.toString().padLeft(2, '0')}-${checkStart.day.toString().padLeft(2, '0')}';
      final toStr = '${checkEnd.year.toString().padLeft(4, '0')}-${checkEnd.month.toString().padLeft(2, '0')}-${checkEnd.day.toString().padLeft(2, '0')}';

      // Single batch query instead of 30 individual queries
      final existingRows = await _repository.dbHelper.getResultsByDateRange(fromStr, toStr);
      final existingDates = existingRows.map((e) => e['draw_date'] as String).toSet();

      final missing = <DateTime>[];
      for (int i = 0; i < 30; i++) {
        final d = checkEnd.subtract(Duration(days: i));
        final dateStr = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (!existingDates.contains(dateStr)) {
          missing.add(d);
        }
      }

      missing.sort((a, b) => a.compareTo(b));
      _missingDates = missing;
      notifyListeners();
    } catch (e) {
      debugPrint('checkMissingDates error: $e');
    }
  }

  // 1-Tap Sync Missing Dates
  Future<void> syncMissingDates() async {
    if (_missingDates.isEmpty || _isSyncingMissingData) return;
    _isSyncingMissingData = true;
    notifyListeners();

    try {
      final toSync = List<DateTime>.from(_missingDates);
      for (final d in toSync) {
        final dateStr =
            "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        try {
          final res = await _repository.scraperService.fetchResultByDate(d);
          await _repository.saveResult(res);
          await CsvHelper.appendResultToCsv(res);
          _missingDates.remove(d);
          notifyListeners();
        } catch (e) {
          debugPrint('Sync missing date $dateStr failed: $e');
        }
      }
      final now = TimeUtils.nowVN;
      fetchHistoryRange(now.subtract(const Duration(days: 30)), now);
      await checkMissingDates();
      if (_todayResult == null) {
        final curDate = TimeUtils.nowVN;
        fetchResultByDate(curDate);
      }
    } catch (e) {
      debugPrint('syncMissingDates error: $e');
    } finally {
      _isSyncingMissingData = false;
      notifyListeners();
    }
  }

  Future<void> _calculateCauStats() async {
    try {
      final historyRaw = await _repository.dbHelper.getResultsHistory(limit: 10);
      if (historyRaw.isEmpty) {
        _cauStats = CauStats(cauLoto: [], cauDacBiet: [], cau2Nhay: []);
        return;
      }
      
      final history = historyRaw.map((e) => LotteryResult.fromMap(e)).toList();
      
      // Calculate Cau Loto (consecutive in last 3 days)
      List<CauLoto> cauLotoList = [];
      if (history.length >= 3) {
        final day0 = history[0].allNumbers.map((s) => s.length >= 2 ? s.substring(s.length - 2) : s).toSet();
        final day1 = history[1].allNumbers.map((s) => s.length >= 2 ? s.substring(s.length - 2) : s).toSet();
        final day2 = history[2].allNumbers.map((s) => s.length >= 2 ? s.substring(s.length - 2) : s).toSet();
        
        final consecutive3 = day0.intersection(day1).intersection(day2);
        for (var num in consecutive3) {
          cauLotoList.add(CauLoto(number: num, consecutiveDays: 3));
        }
        if (cauLotoList.isEmpty) {
          final consecutive2 = day0.intersection(day1);
          for (var num in consecutive2) {
            cauLotoList.add(CauLoto(number: num, consecutiveDays: 2));
          }
        }
      }
      
      // Calculate Cau Dac Biet
      List<CauDacBiet> cauDbList = [];
      Map<String, int> dbCounts = {};
      for (var r in history) {
        if (r.db.length >= 2) {
          final num = r.db.substring(r.db.length - 2);
          dbCounts[num] = (dbCounts[num] ?? 0) + 1;
        }
      }
      // Get DBs from last 3 days
      Set<String> recentDbs = {};
      for (int i = 0; i < (history.length < 3 ? history.length : 3); i++) {
        if (history[i].db.length >= 2) {
          recentDbs.add(history[i].db.substring(history[i].db.length - 2));
        }
      }
      for (var num in recentDbs) {
        cauDbList.add(CauDacBiet(number: num, frequency: '${dbCounts[num]} lần / ${history.length} kỳ'));
      }
      
      // Calculate Cau 2 Nhay
      List<Cau2Nhay> cau2NhayList = [];
      for (int i = 0; i < (history.length < 5 ? history.length : 5); i++) {
        final r = history[i];
        Map<String, int> counts = {};
        for (var fullNum in r.allNumbers) {
          if (fullNum.length >= 2) {
             final pair = fullNum.substring(fullNum.length - 2);
             counts[pair] = (counts[pair] ?? 0) + 1;
          }
        }
        counts.forEach((digits, count) {
          if (count >= 2) {
            if (!cau2NhayList.any((e) => e.number == digits)) {
              String displayDate = r.drawDate;
              try {
                final dt = DateTime.parse(r.drawDate);
                displayDate = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
              } catch (_) {}
              cau2NhayList.add(Cau2Nhay(number: digits, date: displayDate));
            }
          }
        });
        if (cau2NhayList.length >= 5) break;
      }
      
      _cauStats = CauStats(
        cauLoto: cauLotoList.take(5).toList(),
        cauDacBiet: cauDbList.take(5).toList(),
        cau2Nhay: cau2NhayList.take(5).toList(),
      );
    } catch (e) {
      debugPrint('Calculate Cau Stats Error: $e');
      _cauStats = CauStats(cauLoto: [], cauDacBiet: [], cau2Nhay: []);
    }
  }

  // Fetch Analysis Dashboard
  Future<void> fetchAnalysisDashboard({bool silent = false}) async {
    if (!silent) {
      _isLoadingAnalysis = true;
      notifyListeners();
    }

    try {
      _analysis = await _repository.getAnalysisDashboard();
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      debugPrint('Fetch analysis error: $e');
    } finally {
      _isLoadingAnalysis = false;
      notifyListeners();
    }
  }

  // Fetch Deep Analysis (Từ 1996)
  Future<void> fetchDeepAnalysis() async {
    _isLoadingDeepAnalysis = true;
    notifyListeners();

    try {
      // 1. Fetch entire history (1996 to now)
      final allResults = await _repository.getHistoryByDateRange(DateTime(1996, 1, 1), DateTime.now());
      
      // Filter valid DB results
      var validResults = allResults.where((r) => r.db.length >= 2).toList();
      
      // Sort oldest to newest for analysis
      validResults.sort((a, b) => a.drawDate.compareTo(b.drawDate));

      final tt = _analyzeBoSo('Bộ To To (TT)', (s) => int.parse(s[0]) >= 5 && int.parse(s[1]) >= 5, validResults);
      final cc = _analyzeBoSo('Bộ Chẵn Chẵn (CC)', (s) => int.parse(s[0]) % 2 == 0 && int.parse(s[1]) % 2 == 0, validResults);
      final tc = _analyzeBoSo('Bộ To Chẵn (TC)', (s) => int.parse(s[0]) >= 5 && int.parse(s[1]) % 2 == 0, validResults);
      final ct = _analyzeBoSo('Bộ Chẵn To (CT)', (s) => int.parse(s[0]) % 2 == 0 && int.parse(s[1]) >= 5, validResults);
      final du1 = _analyzeBoSo('Bộ Dư 1', (s) => int.parse(s) % 3 == 1, validResults);
      final b0024 = _analyzeBoSo('Bộ 00-24', (s) => int.parse(s) >= 0 && int.parse(s) <= 24, validResults);

      _deepAnalysisData = DeepAnalysisData(analyses: [tt, cc, tc, ct, du1, b0024]);
    } catch (e) {
      debugPrint('Deep analysis error: $e');
    } finally {
      _isLoadingDeepAnalysis = false;
      notifyListeners();
    }
  }

  BoSoAnalysis _analyzeBoSo(String name, bool Function(String) condition, List<LotteryResult> history) {
    int currentInterval = 0;
    int maxGan = 0;
    String maxGanFrom = '';
    String maxGanTo = '';
    String lastHitDate = history.isNotEmpty ? history.first.drawDate : '';
    List<GanInterval> allGans = [];
    int hitCount = 0;

    for (int i = 0; i < history.length; i++) {
      final res = history[i];
      final db = res.db;
      final spec = db.substring(db.length - 2);
      
      if (condition(spec)) {
        hitCount++;
        if (currentInterval > 0) {
          allGans.add(GanInterval(days: currentInterval, fromDate: lastHitDate, toDate: res.drawDate));
          if (currentInterval > maxGan) {
            maxGan = currentInterval;
            maxGanFrom = lastHitDate;
            maxGanTo = res.drawDate;
          }
        }
        currentInterval = 0;
        lastHitDate = res.drawDate;
      } else {
        if (lastHitDate.isEmpty && i == 0) lastHitDate = res.drawDate;
        currentInterval++;
      }
    }
    
    // Reverse to show newest intervals first
    allGans = allGans.reversed.toList();
    List<GanInterval> historicalGans = allGans.where((g) => g.days >= 15).toList();
    
    double ratio = history.isNotEmpty ? (hitCount / history.length * 100) : 0.0;
    String ratioStr = '${ratio.toStringAsFixed(2)}%';

    return BoSoAnalysis(
      name: name,
      currentGan: currentInterval,
      maxGan: maxGan,
      maxGanFrom: maxGanFrom,
      maxGanTo: maxGanTo,
      ratio: ratioStr,
      historicalGans: historicalGans,
      allGans: allGans,
    );
  }

  // Fetch Thong Ke History (Grid)
  Future<void> fetchThongKeHistory(DateTime fromDate, DateTime toDate) async {
    _isLoadingAnalysis = true;
    notifyListeners();

    try {
      List<LotteryResult> filtered = await _repository.getHistoryByDateRange(fromDate, toDate);
      
      // Inject today if within range but missing in filtered
      final nowVN = TimeUtils.nowVN;
      final todayStr = nowVN.toIso8601String().substring(0, 10);
      final fromStr = fromDate.toIso8601String().substring(0, 10);
      final toStr = toDate.toIso8601String().substring(0, 10);
      
      if (todayStr.compareTo(fromStr) >= 0 && todayStr.compareTo(toStr) <= 0) {
        LotteryResult? currentResult = _isLiveDrawing ? _liveResult : _todayResult;
        int idx = filtered.indexWhere((r) => r.drawDate == todayStr);
        if (idx != -1) {
           if (currentResult != null && currentResult.drawDate == todayStr) {
             filtered[idx] = currentResult;
           }
        } else {
           if (currentResult != null && currentResult.drawDate == todayStr) {
             filtered.add(currentResult);
           }
        }
      }

      // Ensure `toStr` exists if not present
      if (!filtered.any((r) => r.drawDate == toStr)) {
         filtered.add(LotteryResult(
            drawDate: toStr,
            db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [],
            isLive: false, createdAt: nowVN.toIso8601String(),
         ));
      }

      // Sort descending
      filtered.sort((a, b) => b.drawDate.compareTo(a.drawDate));

      // Lọc bỏ những kết quả hoàn toàn trống (chưa có số nào), trừ ngày toStr để giữ 1 dòng chờ kết quả
      filtered.removeWhere((r) => r.allNumbers.isEmpty && r.drawDate != toStr);

      Map<String, int> freqs = {};
      int maxFreq = 0;
      for (int i = 0; i < 100; i++) {
        freqs[i.toString().padLeft(2, '0')] = 0;
      }

      for (var r in filtered) {
        for (var num in r.allNumbers) {
          if (num.length >= 2) {
            String tail = num.substring(num.length - 2);
            freqs[tail] = (freqs[tail] ?? 0) + 1;
            if (freqs[tail]! > maxFreq) {
              maxFreq = freqs[tail]!;
            }
          }
        }
      }

      _thongKeData = ThongKeData(
        history: filtered,
        frequencies: freqs,
        maxFrequency: maxFreq,
      );
    } catch (e) {
      debugPrint('Fetch Thong Ke Error: $e');
      _thongKeData = null;
    } finally {
      _isLoadingAnalysis = false;
      notifyListeners();
    }
  }

  // Fetch Lo Gan List
  Future<void> fetchLoGanList({bool silent = false}) async {
    if (!silent) {
      _isLoadingLoGan = true;
      notifyListeners();
    }

    try {
      _loGanList = await _repository.getLoGanList();
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      debugPrint('Fetch lo gan list error: $e');
    } finally {
      _isLoadingLoGan = false;
      notifyListeners();
    }
  }

  // Fetch Dau Duoi Stats
  Future<void> fetchDauDuoiStats({bool silent = false}) async {
    if (!silent) {
      _isLoadingDauDuoi = true;
      notifyListeners();
    }

    try {
      _headTailStats = await _repository.getHeadTailStats();
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      debugPrint('Fetch dau duoi stats error: $e');
    } finally {
      _isLoadingDauDuoi = false;
      notifyListeners();
    }
  }

  // Fetch paginated history
  int _historyPage = 1;
  bool _hasMoreHistory = true;
  
  bool get hasMoreHistory => _hasMoreHistory;

  Future<void> fetchHistoryRange(DateTime fromDate, DateTime toDate) async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      List<LotteryResult> filtered = await _repository.getHistoryByDateRange(fromDate, toDate);
      
      final nowVN = TimeUtils.nowVN;
      final todayStr = nowVN.toIso8601String().substring(0, 10);

      // Scrub corrupted data if it mistakenly saved yesterday's result as today's
      if (filtered.isNotEmpty && filtered.first.drawDate == todayStr) {
         if (filtered.length > 1 && filtered[0].db == filtered[1].db && filtered[0].db.isNotEmpty) {
             await _repository.cleanPollutedData(todayStr);
             filtered.removeAt(0); // Remove from current list
         }
      }

      // Ensure all dates in range are present (fill missing with blank results)
      final fromStr = fromDate.toIso8601String().substring(0, 10);
      final toStr = toDate.toIso8601String().substring(0, 10);

      Map<String, LotteryResult> resultMap = {
        for (var item in filtered) item.drawDate: item
      };

      LotteryResult? currentResult = _isLiveDrawing ? _liveResult : _todayResult;
      if (currentResult != null && currentResult.drawDate == todayStr && todayStr.compareTo(fromStr) >= 0 && todayStr.compareTo(toStr) <= 0) {
          resultMap[todayStr] = currentResult;
      }

      List<LotteryResult> completeList = [];
      DateTime startD = DateTime(fromDate.year, fromDate.month, fromDate.day);
      DateTime endD = DateTime(toDate.year, toDate.month, toDate.day);
      DateTime current = endD;
      
      while (current.compareTo(startD) >= 0) {
        String dStr = current.toIso8601String().substring(0, 10);
        if (resultMap.containsKey(dStr)) {
          final res = resultMap[dStr]!;
          if (res.allNumbers.isNotEmpty || dStr == todayStr) {
            completeList.add(res);
          }
        } else if (dStr == todayStr) {
          completeList.add(LotteryResult(
            drawDate: dStr,
            db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [],
            isLive: false, createdAt: nowVN.toIso8601String(),
          ));
        }
        current = current.subtract(const Duration(days: 1));
      }

      _rangeHistoryResults = completeList;
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      debugPrint('Fetch history range error: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> fetchHistory({bool isRefresh = false}) async {
    if (isRefresh) {
      _historyPage = 1;
      _hasMoreHistory = true;
      _historyResults.clear();
    }

    if (!_hasMoreHistory || _isLoadingHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

    try {
      final results = await _repository.getHistoryResults(page: _historyPage);
      if (results.isEmpty) {
        _hasMoreHistory = false;
      } else {
        _historyResults.addAll(results);
        _historyPage++;
      }
      _isOffline = false;
    } catch (e) {
      _isOffline = true;
      debugPrint('Fetch history error: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // Subscribe to real websocket connection
  void startWebSocketLiveDraw() {
    _pusherSubscription?.cancel();
    _isLiveDrawing = true;
    _liveResult = LotteryResult(
      drawDate: DateTime.now().toIso8601String().substring(0, 10),
      db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [],
      isLive: true,
      createdAt: DateTime.now().toIso8601String(),
    );
    notifyListeners();

    _pusherSubscription = _pusherService.getLiveDrawStream().listen((data) {
      _updateLiveState(data);
    });
  }

  // Start Simulated WebSockets Live Draw (mock)
  void startSimulatedLiveDraw() {
    _pusherSubscription?.cancel();
    _isLiveDrawing = true;
    
    _notificationService.showResultNotification(
      id: 101,
      title: '🔴 Bắt đầu Quay thưởng XSMB!',
      body: 'Buổi quay số mở thưởng trực tiếp XSMB hôm nay đã bắt đầu.',
    );

    _pusherSubscription = _pusherService.startMockLiveDraw().listen((data) {
      _updateLiveState(data);
    });
  }

  void stopLiveDraw() {
    _pusherSubscription?.cancel();
    _pusherSubscription = null;
    _scrapeTimer?.cancel();
    _scrapeTimer = null;
    _isScraping = false;
    _isLiveDrawing = false;
    _liveResult = null;
    _liveDrawingPrize = '';
    _liveDrawingIndex = -1;
    _liveRollingValue = '';
    notifyListeners();
  }

  // ======= SCRAPE-BASED LIVE DRAW (follows real broadcast) =======

  /// Start live draw by polling the lottery website every 3 seconds.
  /// This follows the real XSMB broadcast — no server/WebSocket needed.
  void startScrapeLiveDraw() {
    _pusherSubscription?.cancel();
    _scrapeTimer?.cancel();

    _isLiveDrawing = true;
    _isScraping = false;
    _liveResult = LotteryResult(
      drawDate: DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String().substring(0, 10),
      db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [],
      isLive: true,
      createdAt: DateTime.now().toIso8601String(),
    );
    _liveDrawingPrize = 'g1';
    _liveDrawingIndex = 0;
    _liveRollingValue = '';
    notifyListeners();

    _notificationService.showResultNotification(
      id: 101,
      title: '🔴 Bắt đầu tường thuật XSMB!',
      body: 'Đang theo dõi kết quả trực tiếp từ đài quay...',
    );

    // First tick immediately, then poll every 3 seconds
    _scrapeLiveTick();
    _scrapeTimer = Timer.periodic(const Duration(seconds: 3), (_) => _scrapeLiveTick());
  }

  Future<void> _scrapeLiveTick() async {
    if (_isScraping || !_isLiveDrawing) return;
    _isScraping = true;

    final today = DateTime.now().toUtc().add(const Duration(hours: 7))
        .toIso8601String().substring(0, 10);

    try {
      final result = await _repository.scrapeLatestResult();

      // If the page still shows yesterday's result, keep waiting
      if (result.drawDate != today) {
        _isScraping = false;
        return;
      }

      // Determine which prize is currently being drawn
      const drawOrder = ['g1', 'g2', 'g3', 'g4', 'g5', 'g6', 'g7', 'db'];
      String newDrawingPrize = '';
      int newDrawingIndex = -1;
      bool allComplete = true;

      for (String prize in drawOrder) {
        int expectedCount = AppConstants.prizeCounts[prize] ?? 1;
        List<String> currentNumbers = _getPrizeNumbers(result, prize);
        int filledCount = currentNumbers.where((n) => n.isNotEmpty).length;

        if (filledCount < expectedCount) {
          newDrawingPrize = prize;
          newDrawingIndex = filledCount;
          allComplete = false;
          break;
        }
      }

      if (allComplete && result.db.isNotEmpty) {
        // ✅ Draw is finished!
        _scrapeTimer?.cancel();
        _scrapeTimer = null;
        _isLiveDrawing = false;
        _todayResult = result;
        _liveResult = null;
        _liveDrawingPrize = '';
        _liveDrawingIndex = -1;
        _liveRollingValue = '';

        _repository.saveResult(result);
        CsvHelper.appendResultToCsv(result);
        _updateTodayTopIfNeeded();
        await _calculateCauStats();

        fetchThongKeHistory(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        );
        fetchLoGanList();
        
        fetchHistoryRange(
          DateTime.now().subtract(const Duration(days: 30)),
          DateTime.now(),
        );
        computeStrategyAnalysis(silent: true);

        _notificationService.showResultNotification(
          id: 102,
          title: '🎉 XSMB đã có kết quả đầy đủ!',
          body: 'Giải Đặc Biệt hôm nay: ${result.db}. Bấm để xem chi tiết.',
        );
      } else {
        // 🔄 Still drawing — update state
        _liveResult = result;
        _liveDrawingPrize = newDrawingPrize;
        _liveDrawingIndex = newDrawingIndex;
        // Keep rolling value empty → RollingNumberBall handles its own animation
        _liveRollingValue = '';
        
        // Tự động cập nhật vào danh sách lịch sử nếu đang live
        if (_rangeHistoryResults.isNotEmpty && _rangeHistoryResults.first.drawDate == today) {
           _rangeHistoryResults[0] = result;
        } else if (result.allNumbers.isNotEmpty) {
           _rangeHistoryResults.insert(0, result);
        }

        if (_thongKeData != null && _thongKeData!.history.isNotEmpty) {
           if (_thongKeData!.history.first.drawDate == today) {
             _thongKeData!.history[0] = result;
           } else if (result.allNumbers.isNotEmpty && _thongKeData!.history.first.drawDate.compareTo(today) < 0) {
             _thongKeData!.history.insert(0, result);
           }
        }
        
        if (_strategyData25 != null) {
           computeStrategyAnalysis(silent: true);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Scrape live draw error: $e');
      // Network error — just skip this tick, try again in 3s
    } finally {
      _isScraping = false;
    }
  }

  List<String> _getPrizeNumbers(LotteryResult result, String prizeCode) {
    switch (prizeCode) {
      case 'db': return [result.db];
      case 'g1': return [result.g1];
      case 'g2': return result.g2;
      case 'g3': return result.g3;
      case 'g4': return result.g4;
      case 'g5': return result.g5;
      case 'g6': return result.g6;
      case 'g7': return result.g7;
      default: return [];
    }
  }

  void _updateLiveState(Map<String, dynamic> data) {
    final status = data['status'] as String;
    if (status == 'finished') {
      _isLiveDrawing = false;
      _liveDrawingPrize = '';
      _liveDrawingIndex = -1;
      _liveRollingValue = '';
      _todayResult = LotteryResult.fromJson(data);
      _updateTodayTopIfNeeded();
      _repository.saveResult(_todayResult!); // Cache final results

      // Re-fetch thong ke and lo gan to update stats
      fetchThongKeHistory(
        DateTime.now().subtract(const Duration(days: 30)), 
        DateTime.now()
      );
      fetchLoGanList();
      
      fetchHistoryRange(
        DateTime.now().subtract(const Duration(days: 30)), 
        DateTime.now()
      );

      _notificationService.showResultNotification(
        id: 102,
        title: '🎉 XSMB đã có kết quả đầy đủ!',
        body: 'Giải Đặc Biệt hôm nay về số: ${_todayResult!.db}. Click để xem chi tiết.',
      );
    } else {
      _isLiveDrawing = true;
      _liveResult = LotteryResult.fromJson(data);
      _liveDrawingPrize = data['drawing_prize']?.toString() ?? '';
      _liveDrawingIndex = data['drawing_index'] as int? ?? -1;
      _liveRollingValue = data['rolling_value']?.toString() ?? '';
      
      final today = DateTime.now().toUtc().add(const Duration(hours: 7)).toIso8601String().substring(0, 10);
      if (_rangeHistoryResults.isNotEmpty && _rangeHistoryResults.first.drawDate == today) {
         _rangeHistoryResults[0] = _liveResult!;
      } else if (_liveResult!.allNumbers.isNotEmpty) {
         _rangeHistoryResults.insert(0, _liveResult!);
      }

      if (_thongKeData != null && _thongKeData!.history.isNotEmpty) {
         if (_thongKeData!.history.first.drawDate == today) {
           _thongKeData!.history[0] = _liveResult!;
         } else if (_liveResult!.allNumbers.isNotEmpty && _thongKeData!.history.first.drawDate.compareTo(today) < 0) {
           _thongKeData!.history.insert(0, _liveResult!);
         }
      }

      if (_strategyData25 != null) {
         computeStrategyAnalysis(silent: true);
      }
    }
    notifyListeners();
  }

  // Countdown timer to 18:15
  bool _autoStartTriggeredToday = false; // Prevent re-trigger if user stopped manually

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = TimeUtils.nowVN;
      
      var target = DateTime.utc(now.year, now.month, now.day, 18, 15);
      if (now.isAfter(target)) {
        target = target.add(const Duration(days: 1));
      }

      _timeLeft = target.difference(now);
      
      final hours = _timeLeft.inHours.toString().padLeft(2, '0');
      final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
      
      // Chỉ cập nhật ValueNotifier — không gọi notifyListeners()
      // Chỉ widget countdown mới rebuild, không phải toàn bộ app
      countdownNotifier.value = '$hours:$minutes:$seconds';

      // Auto-start live draw at 18:15-18:35 VN time
      final isDrawWindow = now.hour == 18 && now.minute >= 15 && now.minute <= 35;
      if (isDrawWindow && !_isLiveDrawing && !_autoStartTriggeredToday) {
        _autoStartTriggeredToday = true;
        startScrapeLiveDraw();
      }
      if (now.hour == 18 && now.minute > 35 || now.hour > 18 || now.hour < 18) {
        _autoStartTriggeredToday = false;
      }
    });
  }

  // ==========================================
  // Manual Crawl (Cập nhật dữ liệu từ Server/Scraper)
  // ==========================================
  
  bool _isCrawling = false;
  bool get isCrawling => _isCrawling;
  String _crawlStatus = '';
  String get crawlStatus => _crawlStatus;

  Future<void> manualCrawlDateRange(DateTime start, DateTime end) async {
    _isCrawling = true;
    _crawlStatus = 'Đang chuẩn bị...';
    notifyListeners();

    try {
      int successCount = 0;
      int errorCount = 0;
      LotteryResult? lastResult;
      
      // Loop through dates
      for (DateTime d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        _crawlStatus = 'Đang cào: ${d.day}/${d.month}/${d.year}';
        notifyListeners();
        
        try {
          final result = await _repository.scraperService.fetchResultByDate(d);
          // Save to SQLite
          await _repository.dbHelper.insertResult(result.toMap());
          // Save to CSV
          await CsvHelper.appendResultToCsv(result);
          lastResult = result;
          successCount++;
        } catch (e) {
          errorCount++;
        }
        
        // Anti-spam delay
        await Future.delayed(const Duration(milliseconds: 500));
      }

      _crawlStatus = 'Xong! Thành công: $successCount, Lỗi: $errorCount';
      
      if (lastResult != null) {
        _todayResult = lastResult;
        _updateTodayTopIfNeeded();
      }
      
      // Reload history and analysis to reflect new data
      fetchHistory(isRefresh: true);
      fetchAnalysisDashboard();
      fetchLoGanList();
      fetchDauDuoiStats();
      
    } catch (e) {
      _crawlStatus = 'Lỗi hệ thống: $e';
    } finally {
      _isCrawling = false;
      notifyListeners();
    }
  }

  // Fetch Lo Top (Hôm qua, Hôm nay)
  Future<void> fetchLoTopData() async {
    _isLoadingLoTop = true;
    notifyListeners();

    try {
      if (_loTopFreqsCache == null) {
        // 1. Try loading from SQLite stats_cache first (< 2ms)
        final cachedJson = await _repository.dbHelper.getStatsCache('lo_top_freqs');
        if (cachedJson != null && cachedJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
            _loTopFreqsCache = decoded.map((k, v) => MapEntry(k, v as int));
          } catch (_) {
            _loTopFreqsCache = null;
          }
        }

        // 2. If not cached yet, compute and persist
        if (_loTopFreqsCache == null) {
          final allResults = await _repository.getHistoryByDateRange(
            DateTime.now().subtract(const Duration(days: 365 * 10)),
            DateTime.now(),
          );

          Map<String, int> totalFreqs = {};
          for (var r in allResults) {
            for (var s in r.allLast2Digits) {
              totalFreqs[s] = (totalFreqs[s] ?? 0) + 1;
            }
          }
          _loTopFreqsCache = totalFreqs;
          // Persist asynchronously to avoid re-calculating on next launch
          _repository.dbHelper.saveStatsCache('lo_top_freqs', jsonEncode(totalFreqs));
        }
      }

      final now = TimeUtils.nowVN;
      final todayStr = now.toIso8601String().substring(0, 10);
      final yesterdayStr = now.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);

      LotteryResult? todayRes = _todayResult?.drawDate == todayStr ? _todayResult : null;
      LotteryResult? yesterdayRes;
      
      // We don't want to re-query history if we already cached freqs, so just fetch yesterday's from recent
      if (_historyResults.isNotEmpty) {
        for (var r in _historyResults) {
          if (r.drawDate == yesterdayStr) {
            yesterdayRes = r;
            break;
          }
        }
      }
      // If still not found, fetch it specifically
      yesterdayRes ??= await _repository.getResultByDate(now.subtract(const Duration(days: 1)));

      _todayTop = _extractLoTop(todayRes, _loTopFreqsCache!);
      _yesterdayTop = _extractLoTop(yesterdayRes, _loTopFreqsCache!);

    } catch (e) {
      debugPrint('Error fetchLoTopData: $e');
    } finally {
      _isLoadingLoTop = false;
      notifyListeners();
    }
  }

  void _updateTodayTopIfNeeded() {
    if (_loTopFreqsCache != null && _todayResult != null) {
      final now = TimeUtils.nowVN;
      final todayStr = now.toIso8601String().substring(0, 10);
      if (_todayResult!.drawDate == todayStr) {
        _todayTop = _extractLoTop(_todayResult, _loTopFreqsCache!);
      }
    }
  }

  List<LoTopItem> _extractLoTop(LotteryResult? result, Map<String, int> totalFreqs) {
    if (result == null || result.db.isEmpty) return [];

    Map<String, int> hits = {};
    Map<String, List<String>> prizes = {};

    void addHit(String prizeName, String number) {
      if (number.length >= 2) {
        final val = number.substring(number.length - 2);
        hits[val] = (hits[val] ?? 0) + 1;
        prizes[val] ??= [];
        prizes[val]!.add(prizeName);
      }
    }

    addHit('GĐB', result.db);
    if (result.g1.isNotEmpty) addHit('G1', result.g1);
    for (var n in result.g2) {
      addHit('G2', n);
    }
    for (var n in result.g3) {
      addHit('G3', n);
    }
    for (var n in result.g4) {
      addHit('G4', n);
    }
    for (var n in result.g5) {
      addHit('G5', n);
    }
    for (var n in result.g6) {
      addHit('G6', n);
    }
    for (var n in result.g7) {
      addHit('G7', n);
    }

    List<LoTopItem> list = [];
    hits.forEach((numberStr, count) {
      list.add(LoTopItem(
        number: numberStr,
        hitCount: count,
        prizes: prizes[numberStr] ?? [],
        totalHistoricalHits: totalFreqs[numberStr] ?? 0,
      ));
    });

    list.sort((a, b) {
      int cmp = b.hitCount.compareTo(a.hitCount);
      if (cmp != 0) return cmp;
      return b.totalHistoricalHits.compareTo(a.totalHistoricalHits);
    });

    return list;
  }

  // ==========================================
  // STRATEGY ANALYSIS (Phân Tích Chiến Lược)
  // ==========================================

  Future<void> computeStrategyAnalysis({bool silent = false, DateTime? fromDate, DateTime? toDate}) async {
    if (!silent) {
      _isLoadingStrategy = true;
      notifyListeners();
    }

    try {
      final allResults = await _repository.getHistoryByDateRange(
        DateTime(2005, 10, 1), DateTime.now(),
      );
      
      final todayStr = TimeUtils.nowVN.toIso8601String().substring(0, 10);
      LotteryResult? currentResult = _isLiveDrawing ? _liveResult : _todayResult;

      DateTime from = fromDate ?? DateTime.now().subtract(const Duration(days: 30));
      DateTime to = toDate ?? DateTime.now();
      String toStr = to.toIso8601String().substring(0, 10);

      // Filter valid results OR today's empty/partial result
      List<LotteryResult> validResults = allResults.where((r) => 
        (r.db.length >= 2) || (r.drawDate == todayStr)
      ).toList();

      // Inject today if missing and today <= toStr
      if (todayStr.compareTo(toStr) <= 0) {
        if (validResults.isEmpty || !validResults.any((r) => r.drawDate == todayStr)) {
          if (currentResult != null && currentResult.drawDate == todayStr) {
            validResults.add(currentResult);
          } else {
            validResults.add(LotteryResult(
              drawDate: todayStr,
              db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [],
              isLive: false, createdAt: TimeUtils.nowVN.toIso8601String(),
            ));
          }
        } else if (currentResult != null && currentResult.drawDate == todayStr) {
          int idx = validResults.indexWhere((r) => r.drawDate == todayStr);
          if (idx != -1) {
            validResults[idx] = currentResult;
          }
        }
      }

      // Remove any results strictly after toStr so we only compute up to toDate
      validResults.removeWhere((r) => r.drawDate.compareTo(toStr) > 0);

      validResults.sort((a, b) => a.drawDate.compareTo(b.drawDate));

      // Fill missing dates
      if (validResults.isNotEmpty) {
        DateTime startDate = DateTime.parse(validResults.first.drawDate);
        DateTime endDate = DateTime.parse(validResults.last.drawDate);
        if (to.compareTo(endDate) > 0) {
          endDate = to; // Fill up to 'to' date if it's later
        }
        
        List<LotteryResult> filledResults = [];
        Map<String, LotteryResult> resultMap = { for (var r in validResults) r.drawDate : r };
        
        for (DateTime d = startDate; d.compareTo(endDate) <= 0; d = d.add(const Duration(days: 1))) {
          String dStr = d.toIso8601String().substring(0, 10);
          if (resultMap.containsKey(dStr)) {
            filledResults.add(resultMap[dStr]!);
          } else {
            filledResults.add(LotteryResult(
              drawDate: dStr,
              db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [],
              isLive: false, createdAt: dStr,
            ));
          }
        }
        validResults = filledResults;
      }

      // Compute Mode 25 (4 bộ)
      _strategyData25 = _computeStrategies(_getMode25Defs(), validResults, from, to);
      // Compute Mode 20 (5 bộ)
      _strategyData20 = _computeStrategies(_getMode20Defs(), validResults, from, to);
      // Compute Gan GDB Tail
      _ganGdbTail = _computeGanGdbTail(validResults);
    } catch (e) {
      debugPrint('Strategy analysis error: $e');
    } finally {
      if (!silent) {
        _isLoadingStrategy = false;
      }
      notifyListeners();
    }
  }

  // --- Strategy definitions ---
  List<_StratDef> _getMode25Defs() => [
    _StratDef('To / Nhỏ', 'tn', ['TT','NN','TN','NT'], _clsTN),
    _StratDef('Chẵn / Lẻ', 'cl', ['CC','LL','LC','CL'], _clsCL),
    _StratDef('To-Nhỏ / Chẵn-Lẻ', 'tn_cl', ['TC','TL','NC','NL'], _clsTNCL),
    _StratDef('Chẵn-Lẻ / To-Nhỏ', 'cl_tn', ['CT','LT','CN','LN'], _clsCLTN),
    _StratDef('Chia 4', 'mod4', ['Dư 0','Dư 1','Dư 2','Dư 3'], _clsMod4),
    _StratDef('Dải 25', 'range', ['00-24','25-49','50-74','75-99'], _clsRange25),
  ];

  List<_StratDef> _getMode20Defs() => [
    _StratDef('Dải Số', 'dai_so', ['D0_19','D20_39','D40_59','D60_79','D80_99'], _clsDaiSo),
    _StratDef('Chia 5', 'mod_5', ['DU0','DU1','DU2','DU3','DU4'], _clsMod5),
    _StratDef('Bóng Đầu', 'bong_dau', ['DAU05','DAU16','DAU27','DAU38','DAU49'], _clsBongDau),
    _StratDef('Bóng Đuôi', 'bong_duoi', ['DUOI05','DUOI16','DUOI27','DUOI38','DUOI49'], _clsBongDuoi),
    _StratDef('Bóng Tổng', 'bong_tong', ['TONG05','TONG16','TONG27','TONG38','TONG49'], _clsBongTong),
    _StratDef('Bóng Hiệu', 'bong_hieu', ['HIEU05','HIEU19','HIEU28','HIEU37','HIEU46'], _clsBongHieu),
  ];

  // --- Classification functions ---
  static String _clsTN(String v) {
    int h = int.parse(v[0]), t = int.parse(v[1]);
    return '${h >= 5 ? 'T' : 'N'}${t >= 5 ? 'T' : 'N'}';
  }
  static String _clsCL(String v) {
    int h = int.parse(v[0]), t = int.parse(v[1]);
    return '${h % 2 == 0 ? 'C' : 'L'}${t % 2 == 0 ? 'C' : 'L'}';
  }
  static String _clsTNCL(String v) {
    int h = int.parse(v[0]), t = int.parse(v[1]);
    return '${h >= 5 ? 'T' : 'N'}${t % 2 == 0 ? 'C' : 'L'}';
  }
  static String _clsCLTN(String v) {
    int h = int.parse(v[0]), t = int.parse(v[1]);
    return '${h % 2 == 0 ? 'C' : 'L'}${t >= 5 ? 'T' : 'N'}';
  }
  static String _clsMod4(String v) => 'Dư ${int.parse(v) % 4}';
  static String _clsRange25(String v) {
    int n = int.parse(v);
    if (n <= 24) return '00-24';
    if (n <= 49) return '25-49';
    if (n <= 74) return '50-74';
    return '75-99';
  }
  static String _clsDaiSo(String v) {
    int n = int.parse(v);
    if (n <= 19) return 'D0_19';
    if (n <= 39) return 'D20_39';
    if (n <= 59) return 'D40_59';
    if (n <= 79) return 'D60_79';
    return 'D80_99';
  }
  static String _clsMod5(String v) => 'DU${int.parse(v) % 5}';
  static String _clsBongDau(String v) {
    int r = int.parse(v[0]) % 5;
    return 'DAU$r${r + 5}';
  }
  static String _clsBongDuoi(String v) {
    int r = int.parse(v[1]) % 5;
    return 'DUOI$r${r + 5}';
  }
  static String _clsBongTong(String v) {
    int s = (int.parse(v[0]) + int.parse(v[1])) % 10;
    int r = s % 5;
    return 'TONG$r${r + 5}';
  }
  static String _clsBongHieu(String v) {
    int d = (int.parse(v[0]) - int.parse(v[1])).abs();
    int c = d <= 5 ? d : 10 - d;
    switch (c) {
      case 0: case 5: return 'HIEU05';
      case 1: return 'HIEU19';
      case 2: return 'HIEU28';
      case 3: return 'HIEU37';
      case 4: return 'HIEU46';
      default: return 'HIEU05';
    }
  }

  // --- Core computation ---
  List<StrategyData> _computeStrategies(List<_StratDef> defs, List<LotteryResult> sorted, DateTime from, DateTime to) {
    return defs.map((d) => _computeOneStrategy(d, sorted, from, to)).toList();
  }

  StrategyData _computeOneStrategy(_StratDef def, List<LotteryResult> sorted, DateTime from, DateTime to) {
    const fieldKeys = ['gdb_first2', 'gdb_last2', 'g1_first2', 'g1_last2'];
    const fieldNames = ['ĐẦU ĐẶC BIỆT', 'CUỐI ĐẶC BIỆT', 'ĐẦU GIẢI NHẤT', 'CUỐI GIẢI NHẤT'];

    Map<String, FieldAnalysis> fields = {};
    for (int fi = 0; fi < fieldKeys.length; fi++) {
      fields[fieldKeys[fi]] = _computeField(fieldKeys[fi], fieldNames[fi], def, sorted, from, to);
    }

    return StrategyData(name: def.name, strKey: def.strKey, cols: def.cols, fields: fields);
  }

  String _extractVal(LotteryResult r, String fieldKey) {
    switch (fieldKey) {
      case 'gdb_first2': return r.db.length >= 2 ? r.db.substring(0, 2) : '';
      case 'gdb_last2':  return r.db.length >= 2 ? r.db.substring(r.db.length - 2) : '';
      case 'g1_first2':  return r.g1.length >= 2 ? r.g1.substring(0, 2) : '';
      case 'g1_last2':   return r.g1.length >= 2 ? r.g1.substring(r.g1.length - 2) : '';
      default: return '';
    }
  }

  String _fmtDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return isoDate; }
  }

  FieldAnalysis _computeField(String fieldKey, String fieldName, _StratDef def, List<LotteryResult> sorted, DateTime from, DateTime to) {
    Map<String, int> curGan = {};
    Map<String, int> mxGan = {};
    Map<String, String> mxDates = {};
    Map<String, String> lastHit = {};
    Map<String, List<StrategyGanCycle>> cycles = {};

    for (var col in def.cols) {
      curGan[col] = 0; mxGan[col] = 0; mxDates[col] = ''; lastHit[col] = ''; cycles[col] = [];
    }

    List<StrategyHistoryRow> recentHistory = [];
    String fromStr = from.toIso8601String().substring(0, 10);
    String toStr = to.toIso8601String().substring(0, 10);

    for (var result in sorted) {
      String val = _extractVal(result, fieldKey);
      String dStr = _fmtDate(result.drawDate);

      bool isWithinRange = result.drawDate.compareTo(fromStr) >= 0 && result.drawDate.compareTo(toStr) <= 0;

      if (val.length < 2) {
        if (isWithinRange) {
          recentHistory.add(StrategyHistoryRow(date: dStr, val: val, pattern: ''));
        }
        continue;
      }

      String pattern = def.classifier(val);

      for (var col in def.cols) {
        if (pattern == col) {
          if (curGan[col]! > 0 && lastHit[col]!.isNotEmpty) {
            cycles[col]!.add(StrategyGanCycle(length: curGan[col]!, from: lastHit[col]!, to: dStr));
            if (curGan[col]! > mxGan[col]!) {
              mxGan[col] = curGan[col]!;
              mxDates[col] = '${lastHit[col]} - $dStr';
            }
          }
          curGan[col] = 0;
          lastHit[col] = dStr;
        } else {
          if (lastHit[col]!.isEmpty) lastHit[col] = dStr;
          curGan[col] = curGan[col]! + 1;
        }
      }

      if (isWithinRange) {
        recentHistory.add(StrategyHistoryRow(date: dStr, val: val, pattern: pattern));
      }
    }

    recentHistory = recentHistory.reversed.toList();

    // Reverse cycles: newest first
    for (var col in def.cols) {
      cycles[col] = cycles[col]!.reversed.toList();
    }

    return FieldAnalysis(
      name: fieldName, fieldKey: fieldKey,
      gan: curGan, maxGan: mxGan, maxGanDates: mxDates,
      history: recentHistory, ganCycles: cycles,
    );
  }

  Map<String, int> _computeGanGdbTail(List<LotteryResult> sorted) {
    // sorted is oldest-first; reverse to newest-first
    final rev = sorted.reversed.toList();
    Map<String, int> result = {};
    Set<String> found = {};
    for (int i = 0; i < 100; i++) {
      result[i.toString().padLeft(2, '0')] = rev.length;
    }

    for (int i = 0; i < rev.length; i++) {
      String db = rev[i].db;
      if (db.length >= 2) {
        String tail = db.substring(db.length - 2);
        if (!found.contains(tail)) {
          result[tail] = i;
          found.add(tail);
        }
      }
      if (found.length == 100) break;
    }
    return result;
  }

  // --- SOI CẦU ACTIONS ---
  Future<void> fetchSoiCau({
    DateTime? date,
    int? limit,
    int? exactLimit,
    int? nhay,
    bool? isDb,
    bool? isLon,
    String? searchNum,
    bool silent = false,
  }) async {
    final targetDate = date ?? TimeUtils.nowVN;
    if (limit != null) _soiCauLimit = limit;
    if (exactLimit != null) _soiCauExactLimit = exactLimit;
    if (nhay != null) _soiCauNhay = nhay;
    if (isDb != null) _soiCauIsDb = isDb;
    if (isLon != null) _soiCauIsLon = isLon;
    _soiCauSearchNum = searchNum;

    if (!silent) {
      _isLoadingSoiCau = true;
      notifyListeners();
    }

    try {
      // 1. Try web scraping from RongBachKim
      SoiCauResult? result = await _soiCauService.fetchSoiCauFromWeb(
        date: targetDate,
        limit: _soiCauLimit,
        exactLimit: _soiCauExactLimit,
        nhay: _soiCauNhay,
        isDb: _soiCauIsDb,
        isLon: _soiCauIsLon,
        searchNum: _soiCauSearchNum,
      );

      // 2. Fallback to local SQLite matrix computation on background isolate if web returns null
      if (result == null) {
        final historyRaw = await _repository.dbHelper.getResultsHistory(limit: 100);
        final history = historyRaw.map((e) => LotteryResult.fromMap(e)).toList();
        result = await _soiCauService.computeFromLocalAsync(
          history: history,
          date: targetDate,
          limitDays: _soiCauLimit,
          exactLimit: _soiCauExactLimit,
          nhay: _soiCauNhay,
          isDb: _soiCauIsDb,
          isLon: _soiCauIsLon,
          searchNum: _soiCauSearchNum,
        );
      }

      _soiCauResult = result;
    } catch (e) {
      debugPrint('fetchSoiCau error: $e');
    } finally {
      _isLoadingSoiCau = false;
      notifyListeners();
    }
  }

  Future<void> fetchCauDetail(String position, {DateTime? date}) async {
    final targetDate = date ?? TimeUtils.nowVN;

    _isLoadingCauDetail = true;
    _currentCauDetail = null;
    notifyListeners();

    try {
      _currentCauDetail = await _soiCauService.fetchCauDetailFromWeb(
        position: position,
        date: targetDate,
        limit: _soiCauLimit,
        exactLimit: _soiCauExactLimit,
        nhay: _soiCauNhay,
        isDb: _soiCauIsDb,
        isLon: _soiCauIsLon,
      );

      // Offline fallback on background isolate if web detail is unavailable
      if (_currentCauDetail == null) {
        final historyRaw = await _repository.dbHelper.getResultsHistory(limit: 100);
        final history = historyRaw.map((e) => LotteryResult.fromMap(e)).toList();
        _currentCauDetail = await _soiCauService.computeCauDetailOfflineAsync(
          history: history,
          position: position,
          date: targetDate,
          limitDays: _soiCauLimit,
          isLon: _soiCauIsLon,
          isDb: _soiCauIsDb,
          nhay: _soiCauNhay,
        );
      }
    } catch (e) {
      debugPrint('fetchCauDetail error: $e');
    } finally {
      _isLoadingCauDetail = false;
      notifyListeners();
    }
  }

  void clearCauDetail() {
    _currentCauDetail = null;
    notifyListeners();
  }

  void setSoiCauLimit(int limit, {DateTime? date}) {
    if (_soiCauLimit == limit) return;
    _soiCauLimit = limit;
    fetchSoiCau(date: date, limit: limit);
  }

  void setSoiCauType({required int nhay, required bool isDb, DateTime? date}) {
    _soiCauNhay = nhay;
    _soiCauIsDb = isDb;
    fetchSoiCau(date: date, nhay: nhay, isDb: isDb);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    countdownNotifier.dispose();
    _pusherSubscription?.cancel();
    _scrapeTimer?.cancel();
    super.dispose();
  }
}

/// Internal helper class for strategy definition
class _StratDef {
  final String name;
  final String strKey;
  final List<String> cols;
  final String Function(String) classifier;
  _StratDef(this.name, this.strKey, this.cols, this.classifier);
}
