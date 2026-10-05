import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/lottery_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../widgets/date_navigator.dart';
import '../utils/csv_helper.dart';
import '../widgets/quick_stats_section.dart';
import '../widgets/missing_data_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = TimeUtils.nowVN;
    final today = DateTime.utc(now.year, now.month, now.day);
    // Nếu chưa tới 18h15 thì mặc định hiển thị ngày hôm qua
    if (now.hour < 18 || (now.hour == 18 && now.minute < 15)) {
      _selectedDate = today.subtract(const Duration(days: 1));
    } else {
      _selectedDate = today;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataForDate(_selectedDate);
    });
  }

  void _loadDataForDate(DateTime date) {
    final provider = context.read<LotteryProvider>();
    // fetchResultByDate đã gọi fetchQuickStats + checkMissingDates bên trong
    provider.fetchResultByDate(date);
  }

  void _onPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadDataForDate(_selectedDate);
  }

  void _onNextDay() {
    final now = TimeUtils.nowVN;
    final today = DateTime.utc(now.year, now.month, now.day);
    final maxDate = today.add(const Duration(days: 1)); // Cho phép chuyển sang ngày mai
    final nextDate = _selectedDate.add(const Duration(days: 1));
    if (nextDate.isAfter(maxDate)) return;

    setState(() {
      _selectedDate = nextDate;
    });
    _loadDataForDate(_selectedDate);
  }

  void _onSelectToday() {
    final now = TimeUtils.nowVN;
    setState(() {
      _selectedDate = DateTime.utc(now.year, now.month, now.day);
    });
    _loadDataForDate(_selectedDate);
  }

  Future<void> _onSelectDate() async {
    final now = TimeUtils.nowVN;
    final maxDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryRed,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Just take the start date for view (or we could use it for manual crawl)
      setState(() {
        _selectedDate = DateTime.utc(picked.start.year, picked.start.month, picked.start.day);
      });
      _loadDataForDate(_selectedDate);
      
      // Khởi động cào dữ liệu cho khoảng ngày
      if (mounted) {
        _showCrawlProgressDialog();
        await context.read<LotteryProvider>().manualCrawlDateRange(picked.start, picked.end);
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close dialog
        }
      }
    }
  }

  void _showCrawlProgressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<LotteryProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: const Text('Cập Nhật Dữ Liệu'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.isCrawling) const CircularProgressIndicator(),
                  if (provider.isCrawling) const SizedBox(height: 16),
                  Text(provider.crawlStatus),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amberAccent, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.stars, color: Colors.amber, size: 20),
                ),
              ),
            ),
            const Text('XỔ SỐ MIỀN BẮC',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Xuất file CSV',
            onPressed: () {
              CsvHelper.shareCsvFile();
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          DateNavigator(
            currentDate: _selectedDate,
            onPrevious: _onPreviousDay,
            onNext: _onNextDay,
            onSelectToday: _onSelectToday,
            onSelectDate: _onSelectDate,
          ),
          Selector<LotteryProvider, ({List<DateTime> dates, bool isSyncing})>(
            selector: (_, prov) => (dates: prov.missingDates, isSyncing: prov.isSyncingMissingData),
            builder: (context, data, _) => MissingDataBanner(
              missingDates: data.dates,
              isSyncing: data.isSyncing,
              onSyncNow: () => context.read<LotteryProvider>().syncMissingDates(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final prov = context.read<LotteryProvider>();
                await prov.fetchResultByDate(_selectedDate);
                await prov.fetchQuickStats(_selectedDate);
                await prov.checkMissingDates();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Selector<LotteryProvider, bool>(
                      selector: (_, prov) => prov.isLiveDrawing,
                      builder: (context, isLive, _) => _buildLiveBanner(context, isLive),
                    ),
                    const SizedBox(height: 8),
                    Selector<LotteryProvider, ({bool isLoading, LotteryResult? result, bool isLive})>(
                      selector: (_, prov) => (
                        isLoading: prov.isLoadingToday,
                        result: prov.todayResult,
                        isLive: prov.isLiveDrawing,
                      ),
                      builder: (context, state, _) {
                        if (state.isLoading) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        return _buildResultsTable(context, state.result, state.isLive);
                      },
                    ),
                    const SizedBox(height: 16),
                    Selector<LotteryProvider, ({bool isLoading, LotteryResult? result})>(
                      selector: (_, prov) => (
                        isLoading: prov.isLoadingDauDuoi,
                        result: prov.todayResult,
                      ),
                      builder: (context, state, _) => _buildHeadTailTable(context, state.isLoading, state.result),
                    ),
                    // KHỐI THỐNG KÊ NHANH CHO NGÀY (RỒNG BẠCH KIM HYBRID)
                    Selector<LotteryProvider, ({QuickStatsData? data, bool isLoading})>(
                      selector: (_, prov) => (
                        data: prov.quickStatsData,
                        isLoading: prov.isLoadingQuickStats,
                      ),
                      builder: (context, stats, _) {
                        if (stats.data == null && !stats.isLoading) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: QuickStatsSection(
                            data: stats.data ??
                                const QuickStatsData(
                                  targetDate: '',
                                  lotoGanList: [],
                                  lotoFrequencyList: [],
                                  deGanList: [],
                                  ganTongList: [],
                                  ganChamList: [],
                                  topTongDesc: '',
                                  topChamDesc: '',
                                ),
                            isLoading: stats.isLoading,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prov = context.read<LotteryProvider>();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Text('Đang đồng bộ dữ liệu kỳ quay...'),
                ],
              ),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await prov.fetchResultByDate(_selectedDate);
          await prov.fetchQuickStats(_selectedDate);
          await prov.checkMissingDates();
        },
        backgroundColor: const Color(0xFF0D6EFD),
        tooltip: 'Làm mới & Đồng bộ dữ liệu',
        child: const Icon(Icons.sync, color: Colors.white),
      ),
    );
  }

  // --- Bảng Kết Quả & Live Banner ---
  Widget _buildLiveBanner(BuildContext context, bool isLive) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget buildCountdownBox(String val, String label, bool isDark) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.primaryRed.withValues(alpha: 0.3) : const Color(0xFFDC3545),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Text(
              val,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/live');
      },
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLive 
            ? (isDark ? Colors.red.shade900.withValues(alpha: 0.2) : Colors.red.shade50) 
            : (isDark ? const Color(0xFF1E2D3D) : Colors.blue.shade50),
        border: Border.all(
          color: isLive 
              ? (isDark ? Colors.red.shade800 : Colors.red.shade300) 
              : (isDark ? Colors.blue.shade800 : Colors.blue.shade200),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isLive ? Icons.sensors : Icons.access_time, 
            color: isLive ? Colors.red : Colors.blue.shade700,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                isLive ? 'ĐANG TRỰC TIẾP QUAY THƯỞNG' : 'Đếm ngược ngày quay tiếp theo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isLive ? Colors.red.shade800 : Colors.blue.shade900,
                ),
              ),
                const SizedBox(height: 6),
                isLive
                    ? Text(
                        'Đang cập nhật kết quả liên tục...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade800,
                        ),
                      )
                    : ValueListenableBuilder<String>(
                        valueListenable: context.read<LotteryProvider>().countdownNotifier,
                        builder: (context, countdown, _) {
                          List<String> parts = countdown.split(':');
                          if (parts.length == 3) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildCountdownBox(parts[0], 'giờ', isDark),
                                const Padding(
                                  padding: EdgeInsets.only(left: 6, right: 6, bottom: 12),
                                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                buildCountdownBox(parts[1], 'phút', isDark),
                                const Padding(
                                  padding: EdgeInsets.only(left: 6, right: 6, bottom: 12),
                                  child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ),
                                buildCountdownBox(parts[2], 'giây', isDark),
                              ],
                            );
                          }
                          return Text(
                            countdown,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          );
                        },
                      ),
              ],
            ),
          // ), Remove this
        ],
      ),
    ),
    );
  }

  Widget _buildResultsTable(BuildContext context, LotteryResult? currentResult, bool isLive) {
    final result = currentResult ?? LotteryResult(
      drawDate: TimeUtils.formatToYYYYMMDD(_selectedDate),
      db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [], createdAt: ''
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : AppTheme.primaryRed.withValues(alpha: 0.4); 
    final headerColor = isDark ? const Color(0xFF383D43) : const Color(0xFFF8D7DA); 
    final labelColor = isDark ? Colors.white70 : AppTheme.primaryRed; 

    TableRow buildRow(String label, List<String> numbers, int expectedCount, {bool isDb = false}) {
      if (numbers.isEmpty || (numbers.length == 1 && numbers[0].isEmpty)) {
         numbers = List.filled(expectedCount, '-----');
      } else if (numbers.length < expectedCount && isLive) {
         numbers = List.from(numbers)..addAll(List.filled(expectedCount - numbers.length, '???'));
      } else if (numbers.length < expectedCount) {
         numbers = List.from(numbers)..addAll(List.filled(expectedCount - numbers.length, '-----'));
      }

      return TableRow(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: headerColor,
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDb ? AppTheme.primaryRed : labelColor,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: isDb ? BoxDecoration(
              color: isDark ? AppTheme.primaryRed.withValues(alpha: 0.08) : const Color(0xFFFFF5F5),
            ) : null,
            alignment: Alignment.center,
            child: Wrap(
              spacing: 24,
              runSpacing: 12,
              alignment: WrapAlignment.spaceEvenly,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: numbers.map((n) => Text(
                n,
                style: TextStyle(
                  fontSize: isDb ? 24 : 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: isDb ? AppTheme.primaryRed : (isDark ? Colors.white : Colors.black87),
                ),
              )).toList(),
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF383D43) : Colors.white,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            alignment: Alignment.center,
            child: Text(
              'KẾT QUẢ XỔ SỐ MIỀN BẮC - Ngày ${TimeUtils.formatDisplayDate(result.drawDate)}',
              style: const TextStyle(
                color: AppTheme.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          if (result.db.isEmpty && !isLive)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: isDark ? const Color(0xFF3D2E1E) : const Color(0xFFFFF3CD),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: isDark ? AppTheme.accentGold : const Color(0xFF664D03),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Chưa có dữ liệu kỳ quay ngày ${TimeUtils.formatDisplayDate(result.drawDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.accentGold : const Color(0xFF664D03),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.read<LotteryProvider>().fetchResultByDate(_selectedDate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('Tải lại', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(90),
              1: FlexColumnWidth(),
            },
            border: TableBorder.symmetric(
              inside: BorderSide(color: borderColor, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              buildRow('Đặc biệt', [result.db], 1, isDb: true),
              buildRow('Giải Nhất', [result.g1], 1),
              buildRow('Giải Nhì', result.g2, 2),
              buildRow('Giải Ba', result.g3, 6),
              buildRow('Giải Tư', result.g4, 4),
              buildRow('Giải Năm', result.g5, 6),
              buildRow('Giải Sáu', result.g6, 3),
              buildRow('Giải Bảy', result.g7, 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeadTailTable(BuildContext context, bool isLoadingDauDuoi, LotteryResult? todayResult) {
    if (isLoadingDauDuoi) return const SizedBox.shrink();

    final result = todayResult ?? LotteryResult(
      drawDate: TimeUtils.formatToYYYYMMDD(_selectedDate),
      db: '', g1: '', g2: [], g3: [], g4: [], g5: [], g6: [], g7: [], createdAt: ''
    );
    final headStats = result.headStats;
    final tailStats = result.tailStats;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    const headerBgColor = Color(0xFFDC3545); // Red

    Widget buildBadge(int count, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          count.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    List<TableRow> rows = [];
    // Sub-header row
    rows.add(TableRow(
      decoration: BoxDecoration(color: isDark ? const Color(0xFF383D43) : Colors.grey.shade100),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('Đầu', style: TextStyle(fontWeight: FontWeight.bold)))),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('Lô tô', style: TextStyle(fontWeight: FontWeight.bold)))),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)))),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('Đuôi', style: TextStyle(fontWeight: FontWeight.bold)))),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('Lô tô', style: TextStyle(fontWeight: FontWeight.bold)))),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(child: Text('SL', style: TextStyle(fontWeight: FontWeight.bold)))),
      ]
    ));

    // Data rows
    for (int i = 0; i < 10; i++) {
      final headLoto = headStats[i]?.join(', ') ?? '';
      final tailLoto = tailStats[i]?.join(', ') ?? '';
      final headCount = headStats[i]?.length ?? 0;
      final tailCount = tailStats[i]?.length ?? 0;

      rows.add(TableRow(
        decoration: BoxDecoration(color: isDark ? AppTheme.darkSurface : Colors.white),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text('$i', style: const TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text(headLoto, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))),
          ),
          Center(child: buildBadge(headCount, AppTheme.primaryRed)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text('$i', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text(tailLoto, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600))),
          ),
          Center(child: buildBadge(tailCount, const Color(0xFF0D6EFD))), // Blue
        ]
      ));
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: headerBgColor,
            alignment: Alignment.center,
            child: const Text(
              'THỐNG KÊ ĐẦU - ĐUÔI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Table(
            border: TableBorder.symmetric(inside: BorderSide(color: borderColor, width: 0.5)),
            columnWidths: const {
              0: FixedColumnWidth(40),
              1: FlexColumnWidth(),
              2: FixedColumnWidth(40),
              3: FixedColumnWidth(40),
              4: FlexColumnWidth(),
              5: FixedColumnWidth(40),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: rows,
          ),
        ],
      ),
    );
  }
}
