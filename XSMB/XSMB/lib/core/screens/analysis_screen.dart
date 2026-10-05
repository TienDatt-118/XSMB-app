import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/lottery_provider.dart';
import '../models/models.dart';
import '../models/strategy_analysis_model.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late DateTime _fromDate;
  late DateTime _toDate;
  int _analysisMode = 25; // 25 (4 Bộ) hoặc 20 (5 Bộ)
  String _activeTabStrKey = '';
  String _activePieColumn = '';
  String _activeLineField = 'gdb_first2';
  bool _showNumberSets = false;
  int _ganFilterMin = 150;
  final Map<String, int> _touchedPieIndices = {};

  @override
  void initState() {
    super.initState();
    final now = TimeUtils.nowVN;
    final today = DateTime.utc(now.year, now.month, now.day);
    _toDate = today;
    _fromDate = today.subtract(const Duration(days: 30));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LotteryProvider>();
      if (provider.thongKeData == null) {
        provider.fetchThongKeHistory(_fromDate, _toDate);
      }
      if (provider.getStrategyData(25) == null) {
        provider.computeStrategyAnalysis(fromDate: _fromDate, toDate: _toDate);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final now = TimeUtils.nowVN;
    final maxDate = DateTime.utc(now.year, now.month, now.day).add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryRed,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        DateTime pickedUtc = DateTime.utc(picked.year, picked.month, picked.day);
        if (isFrom) {
          _fromDate = pickedUtc;
        } else {
          _toDate = pickedUtc;
        }
      });
      if (context.mounted) {
        final provider = context.read<LotteryProvider>();
        provider.fetchThongKeHistory(_fromDate, _toDate);
        provider.computeStrategyAnalysis(fromDate: _fromDate, toDate: _toDate);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    LotteryResult? latestResult;
    if (provider.thongKeData != null && provider.thongKeData!.history.isNotEmpty) {
      latestResult = provider.thongKeData!.history.first;
    }

    final strategies = provider.getStrategyData(_analysisMode);
    StrategyData? activeStrategy;
    if (strategies != null && strategies.isNotEmpty) {
      if (_activeTabStrKey.isEmpty) {
        _activeTabStrKey = strategies.first.strKey;
      }
      activeStrategy = strategies.firstWhere(
        (s) => s.strKey == _activeTabStrKey,
        orElse: () => strategies.first,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text('PHÂN TÍCH CHUYÊN SÂU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        titleSpacing: 16,
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: latestResult == null
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryRed))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderFilter(isDark),
                    const SizedBox(height: 20),

                    // 1. KẾT QUẢ GĐB VÀ G1
                    _buildPrizeResults(latestResult, isDark),
                    const SizedBox(height: 24),

                    // 2. 4 CARD PHÂN TÍCH ĐẦU - ĐUÔI
                    const Text('Phân Tích Đầu - Đuôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primaryRed)),
                    const Divider(color: AppTheme.primaryRed, thickness: 2),
                    const SizedBox(height: 12),
                    _buildHeadTailAnalysis(latestResult, isDark),
                    const SizedBox(height: 24),

                    // 3. CHẾ ĐỘ PHÂN TÍCH (PILL TOGGLE)
                    _buildModeSelector(isDark),
                    const SizedBox(height: 16),

                    // 4. BẢNG LIỆT KÊ SỐ THUỘC BỘ
                    if (_activeTabStrKey == 'mod4' || _activeTabStrKey == 'mod_5')
                      _buildNumberSetsPanel(isDark),

                    // 5. TABS CHIẾN LƯỢC
                    if (strategies != null && strategies.isNotEmpty) ...[
                      _buildStrategyTabs(strategies, isDark),
                      const SizedBox(height: 16),
                    ],

                    // Loading indicator
                    if (provider.isLoadingStrategy)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
                      ),

                    // 6-9. STRATEGY CONTENT (Mega Table + Charts + Summary)
                    if (activeStrategy != null && !provider.isLoadingStrategy) ...[
                      _buildMegaTable(activeStrategy, isDark),
                      const SizedBox(height: 20),
                      _buildGanBarCharts(activeStrategy, isDark),
                      const SizedBox(height: 20),
                      _buildPieCharts(activeStrategy, isDark),
                      const SizedBox(height: 20),
                      _buildLineCharts(activeStrategy, isDark),
                      const SizedBox(height: 20),
                      _buildMaxGanSummary(activeStrategy, isDark),
                      const SizedBox(height: 24),
                    ],

                    // 10. BẢNG LÔ GAN ĐUÔI ĐẶC BIỆT
                    if (provider.ganGdbTail != null)
                      _buildGanDeGrid(provider.ganGdbTail!, isDark),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // =========================================
  // 1. HEADER FILTER
  // =========================================
  Widget _buildHeaderFilter(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () => setState(() {
              _fromDate = _fromDate.subtract(const Duration(days: 1));
              _toDate = _toDate.subtract(const Duration(days: 1));
              context.read<LotteryProvider>().fetchThongKeHistory(_fromDate, _toDate);
              context.read<LotteryProvider>().computeStrategyAnalysis(fromDate: _fromDate, toDate: _toDate);
            }),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectDate(context, true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryRed),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(_toDate),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 28),
            onPressed: () => setState(() {
              _fromDate = _fromDate.add(const Duration(days: 1));
              _toDate = _toDate.add(const Duration(days: 1));
              context.read<LotteryProvider>().fetchThongKeHistory(_fromDate, _toDate);
              context.read<LotteryProvider>().computeStrategyAnalysis(fromDate: _fromDate, toDate: _toDate);
            }),
          ),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              onPressed: () => setState(() {
                final now = TimeUtils.nowVN;
                final today = DateTime.utc(now.year, now.month, now.day);
                _toDate = today;
                _fromDate = today.subtract(const Duration(days: 30));
                context.read<LotteryProvider>().fetchThongKeHistory(_fromDate, _toDate);
                context.read<LotteryProvider>().computeStrategyAnalysis(fromDate: _fromDate, toDate: _toDate);
              }),
              child: const Text('Hôm nay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  // =========================================
  // 2. PRIZE RESULTS (GĐB & G1)
  // =========================================
  Widget _buildPrizeResults(LotteryResult result, bool isDark) {
    String dbFirst = result.db.length >= 2 ? result.db.substring(0, 2) : '--';
    String dbLast = result.db.length >= 2 ? result.db.substring(result.db.length - 2) : '--';
    String g1First = result.g1.length >= 2 ? result.g1.substring(0, 2) : '--';
    String g1Last = result.g1.length >= 2 ? result.g1.substring(result.g1.length - 2) : '--';

    return Row(
      children: [
        Expanded(child: _buildPrizeBox('GIẢI ĐẶC BIỆT', result.db, dbFirst, dbLast, AppTheme.primaryRed, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildPrizeBox('GIẢI NHẤT', result.g1, g1First, g1Last, Colors.blue.shade700, isDark)),
      ],
    );
  }

  Widget _buildPrizeBox(String title, String full, String first, String last, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          const SizedBox(height: 8),
          Text(full.isEmpty ? '-----' : full, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, letterSpacing: 2)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(4)),
                child: Text(first, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey.shade400),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(border: Border.all(color: color), borderRadius: BorderRadius.circular(4)),
                child: Text(last, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // =========================================
  // 3. HEAD TAIL ANALYSIS (4 cards)
  // =========================================
  Widget _buildHeadTailAnalysis(LotteryResult result, bool isDark) {
    final freqs = context.read<LotteryProvider>().thongKeData?.frequencies ?? {};
    String dbFirst = result.db.length >= 2 ? result.db.substring(0, 2) : '--';
    String dbLast = result.db.length >= 2 ? result.db.substring(result.db.length - 2) : '--';
    String g1First = result.g1.length >= 2 ? result.g1.substring(0, 2) : '--';
    String g1Last = result.g1.length >= 2 ? result.g1.substring(result.g1.length - 2) : '--';

    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _buildAnalysisCard('ĐẦU ĐẶC BIỆT', dbFirst, isDark, freqs[dbFirst] ?? 0),
        _buildAnalysisCard('CUỐI ĐẶC BIỆT', dbLast, isDark, freqs[dbLast] ?? 0),
        _buildAnalysisCard('ĐẦU GIẢI NHẤT', g1First, isDark, freqs[g1First] ?? 0),
        _buildAnalysisCard('CUỐI GIẢI NHẤT', g1Last, isDark, freqs[g1Last] ?? 0),
      ],
    );
  }

  Widget _buildAnalysisCard(String title, String val, bool isDark, int nFreq) {
    bool isEmpty = val == '--';
    int tens = !isEmpty ? int.parse(val[0]) : 0;
    int units = !isEmpty ? int.parse(val[1]) : 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryRed)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.primaryRed), borderRadius: BorderRadius.circular(4)),
                child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed, fontSize: 14)),
              )
            ],
          ),
          const SizedBox(height: 6),
          if (isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Chưa có dữ liệu', style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 6),
          ] else ...[
            _buildAnalysisRow('Hàng chục:', tens),
            const SizedBox(height: 6),
            _buildAnalysisRow('Hàng đơn vị:', units),
          ],
          const Divider(),
          Text('Nổ $nFreq lần / 30 ngày', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, int val) {
    bool isEven = val % 2 == 0;
    bool isBig = val >= 5;
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(width: 4),
        Text(val.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: isEven ? Colors.red.shade50 : Colors.purple.shade50, borderRadius: BorderRadius.circular(2)),
          child: Text(isEven ? 'Chẵn' : 'Lẻ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isEven ? AppTheme.primaryRed : Colors.purple)),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: isBig ? Colors.teal.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(2)),
          child: Text(isBig ? 'Lớn' : 'Nhỏ', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: isBig ? Colors.teal : Colors.orange)),
        ),
      ],
    );
  }

  // =========================================
  // 4. MODE SELECTOR (Pill Toggle)
  // =========================================
  Widget _buildModeSelector(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Chế độ:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(width: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryRed, width: 2),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPill('4 Bộ (25 Số)', 25),
              _buildPill('5 Bộ (20 Số)', 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String label, int mode) {
    bool active = _analysisMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() {
          _analysisMode = mode;
          final strategies = context.read<LotteryProvider>().getStrategyData(mode);
          if (strategies != null && strategies.isNotEmpty) {
            _activeTabStrKey = strategies.first.strKey;
          }
          _activePieColumn = '';
          _showNumberSets = false;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.w800, fontSize: 12,
          color: active ? Colors.white : AppTheme.primaryRed,
        )),
      ),
    );
  }

  // =========================================
  // 5. NUMBER SETS PANEL (Collapsible)
  // =========================================
  Widget _buildNumberSetsPanel(bool isDark) {
    int divisor = _activeTabStrKey == 'mod4' ? 4 : 5;
    String title = _activeTabStrKey == 'mod4' ? 'Chia 4' : 'Chia 5';
    Map<String, List<String>> sets = {};
    for (int r = 0; r < divisor; r++) {
      String key = 'Dư $r';
      sets[key] = [];
      for (int i = 0; i < 100; i++) {
        if (i % divisor == r) sets[key]!.add(i.toString().padLeft(2, '0'));
      }
    }

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showNumberSets = !_showNumberSets),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.primaryRed, width: 2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              _showNumberSets ? '✕ Đóng danh sách số' : '📋 Xem danh sách số thuộc bộ $title',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primaryRed),
            ),
          ),
        ),
        if (_showNumberSets) ...[
          const SizedBox(height: 12),
          ...sets.entries.map((e) => _buildNumSetBox(e.key, e.value, isDark)),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNumSetBox(String title, List<String> nums, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFC0392B), Color(0xFFE74C3C)]),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                  child: Text('${nums.length} số', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 6, runSpacing: 6,
              children: nums.map((n) => Container(
                width: 42, padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFAFA),
                  border: Border.all(color: const Color(0xFFF5C6CB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(n, textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryRed, fontFamily: 'Consolas', fontSize: 14)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // 6. STRATEGY TABS
  // =========================================
  Widget _buildStrategyTabs(List<StrategyData> strategies, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: strategies.map((s) {
          bool active = s.strKey == _activeTabStrKey;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTabStrKey = s.strKey;
                _activePieColumn = '';
                _showNumberSets = false;
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryRed : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                  border: Border.all(color: active ? AppTheme.primaryRed : Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: active ? [BoxShadow(color: AppTheme.primaryRed.withValues(alpha: 0.3), blurRadius: 10)] : null,
                ),
                child: Text(s.name, style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 12,
                  color: active ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF495057)),
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================
  // 7. MEGA TABLE
  // =========================================
  Widget _buildMegaTable(StrategyData strategy, bool isDark) {
    final fieldKeys = ['gdb_first2', 'gdb_last2', 'g1_first2', 'g1_last2'];
    final cols = strategy.cols;
    final history = strategy.fields['gdb_first2']!.history;
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header row 1: Field group names
            Row(
              children: [
                _megaCell('Ngày', isHeader: true, width: 65, bg: const Color(0xFFF8F9FA)),
                ...fieldKeys.asMap().entries.map((e) {
                  final f = strategy.fields[e.value]!;
                  final isGdb = e.key < 2;
                  return Row(
                    children: List.generate(cols.length, (i) => _megaCell(
                      i == cols.length ~/ 2 ? f.name : '',
                      isHeader: true, width: 45,
                      bg: isGdb ? const Color(0xFFFFF5F5) : const Color(0xFFF0F8FF),
                      textColor: isGdb ? AppTheme.primaryRed : Colors.blue.shade700,
                      fontSize: 7,
                    )),
                  );
                }),
              ],
            ),
            // Header row 2: Column names
            Row(
              children: [
                _megaCell('', isHeader: true, width: 65, bg: const Color(0xFFF8F9FA)),
                ...fieldKeys.expand((_) => cols.map((c) => _megaCell(c, isHeader: true, width: 45, fontSize: 8))),
              ],
            ),
            // Gan HT row
            Row(
              children: [
                _megaCell('Gan HT', isHeader: true, width: 65, bg: const Color(0xFFFFFFFA), textColor: AppTheme.primaryRed),
                ...fieldKeys.expand((fk) {
                  final f = strategy.fields[fk]!;
                  return cols.map((c) {
                    int g = f.gan[c] ?? 0;
                    return _megaCell(
                      g == 0 ? 'Vừa nổ' : g.toString(),
                      width: 45, fontWeight: FontWeight.w900,
                      textColor: g == 0 ? Colors.green : AppTheme.primaryRed,
                      fontSize: g == 0 ? 7 : 10,
                    );
                  });
                }),
              ],
            ),
            // Max Gan row
            Row(
              children: [
                _megaCell('Max', isHeader: true, width: 65, bg: const Color(0xFFF8F9FA), textColor: Colors.grey),
                ...fieldKeys.expand((fk) {
                  final f = strategy.fields[fk]!;
                  return cols.map((c) => _megaCell(
                    (f.maxGan[c] ?? 0).toString(),
                    width: 45, textColor: Colors.grey.shade600, fontSize: 9,
                  ));
                }),
              ],
            ),
            // Data rows
            ...history.asMap().entries.map((entry) {
              final i = entry.key;
              return Row(
                children: [
                  _megaCell(history[i].date.substring(0, 5), width: 65, bg: const Color(0xFFF8F9FA),
                    fontWeight: FontWeight.w700, textColor: Colors.grey.shade600, fontSize: 9),
                  ...fieldKeys.map((fk) {
                    final fHistory = strategy.fields[fk]!.history;
                    if (i >= fHistory.length) {
                      return Row(children: cols.map((_) => _megaCell('-', width: 45, textColor: Colors.grey.shade300)).toList());
                    }
                    final row = fHistory[i];
                    final isG1 = fk.startsWith('g1');
                    return Row(
                      children: cols.map((c) {
                        if (row.pattern == c) {
                          return Container(
                            width: 45, height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, width: 0.5)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: isG1 ? Colors.blue.shade700 : AppTheme.primaryRed,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(row.val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9, fontFamily: 'Consolas')),
                            ),
                          );
                        }
                        return Container(
                          width: 45, height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200, width: 0.5)),
                          child: Text('-', style: TextStyle(color: Colors.grey.shade300, fontSize: 10)),
                        );
                      }).toList(),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _megaCell(String text, {double width = 50, bool isHeader = false, Color? bg,
    Color? textColor, double fontSize = 10, FontWeight fontWeight = FontWeight.w600}) {
    return Container(
      width: width, height: isHeader ? 28 : 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg ?? (isHeader ? const Color(0xFFF8F9FA) : Colors.white),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Text(text, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: fontSize, fontWeight: isHeader ? FontWeight.w800 : fontWeight,
          color: textColor ?? (isHeader ? const Color(0xFF333333) : Colors.black87)),
      ),
    );
  }

  // =========================================
  // 8. GAN BAR CHARTS (2×2)
  // =========================================
  Widget _buildGanBarCharts(StrategyData strategy, bool isDark) {
    final configs = [
      {'key': 'gdb_first2', 'color': const Color(0xFF8B8DFB)},
      {'key': 'gdb_last2', 'color': const Color(0xFF8B8DFB)},
      {'key': 'g1_first2', 'color': const Color(0xFF6C757D)},
      {'key': 'g1_last2', 'color': const Color(0xFF6C757D)},
    ];

    int globalMax = 1;
    for (var c in configs) {
      final f = strategy.fields[c['key'] as String]!;
      for (var v in f.gan.values) {
        if (v > globalMax) globalMax = v;
      }
    }

    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: configs.map((c) {
        final f = strategy.fields[c['key'] as String]!;
        final barColor = c['color'] as Color;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text(f.name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: barColor)),
              const SizedBox(height: 4),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: globalMax.toDouble() * 1.2,
                    barGroups: strategy.cols.asMap().entries.map((e) {
                      int val = f.gan[e.value] ?? 0;
                      return BarChartGroupData(x: e.key, barRods: [
                        BarChartRodData(toY: val.toDouble(), color: barColor, width: 12, borderRadius: const BorderRadius.vertical(top: Radius.circular(2))),
                      ]);
                    }).toList(),
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 16,
                        getTitlesWidget: (v, _) {
                          int idx = v.toInt();
                          if (idx < 0 || idx >= strategy.cols.length) return const SizedBox.shrink();
                          int val = f.gan[strategy.cols[idx]] ?? 0;
                          return Text('$val', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)));
                        },
                      )),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 20,
                        getTitlesWidget: (v, _) {
                          int idx = v.toInt();
                          if (idx < 0 || idx >= strategy.cols.length) return const SizedBox.shrink();
                          return Text(strategy.cols[idx], style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'Consolas'));
                        },
                      )),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // =========================================
  // 9. PIE CHARTS
  // =========================================
  Widget _buildPieCharts(StrategyData strategy, bool isDark) {
    if (_activePieColumn.isEmpty && strategy.cols.isNotEmpty) {
      _activePieColumn = strategy.cols.first;
    }

    final pConfigs = [
      {'key': 'gdb_first2', 'title': 'ĐẦU ĐB'},
      {'key': 'gdb_last2', 'title': 'CUỐI ĐB'},
      {'key': 'g1_first2', 'title': 'ĐẦU G1'},
      {'key': 'g1_last2', 'title': 'CUỐI G1'},
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Column filter chips
          const Text('LỌC THEO BỘ:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: strategy.cols.map((col) {
                bool active = col == _activePieColumn;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(col, style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 11,
                      color: active ? Colors.white : AppTheme.primaryRed,
                    )),
                    selected: active,
                    selectedColor: AppTheme.primaryRed,
                    backgroundColor: isDark ? const Color(0xFF3C3C3C) : Colors.white,
                    side: BorderSide(color: active ? AppTheme.primaryRed : Colors.grey.shade300),
                    onSelected: (_) => setState(() => _activePieColumn = col),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Text('TỶ LỆ NGÀY NỔ GAN: $_activePieColumn',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 12),
          // 2×2 pie charts
          GridView.count(
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.85,
            children: pConfigs.map((pc) {
              final f = strategy.fields[pc['key']]!;
              
              // Lấy tất cả lịch sử chu kỳ gan của cột đang chọn
              final cycles = f.ganCycles[_activePieColumn] ?? [];
              
              // 2. LOGIC ĐẾM TẦN SUẤT
              Map<int, int> dayCounts = {};
              for (var cy in cycles) {
                // Chỉ lấy các mốc gan >= 15 ngày
                if (cy.length >= 15) {
                  // Đếm số lần xuất hiện của mốc gan này (ví dụ: mốc 15 ngày +1 lần)
                  dayCounts[cy.length] = (dayCounts[cy.length] ?? 0) + 1;
                }
              }
              
              // Sắp xếp các mốc ngày (keys) tăng dần: 15, 16, 17...
              final sortedKeys = dayCounts.keys.toList()..sort();
              // Lấy danh sách số lần xuất hiện (tần suất) tương ứng với các mốc ngày trên
              final values = sortedKeys.map((k) => dayCounts[k]!).toList();
              
              int totalHits = values.fold(0, (sum, val) => sum + val);
              int touchedIndex = _touchedPieIndices[pc['key']] ?? -1;

              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(pc['title']!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
                    const SizedBox(height: 4),
                    Expanded(
                      child: sortedKeys.isEmpty
                        // Nếu không có mốc gan nào >= 15 ngày thì báo không có dữ liệu
                        ? const Center(child: Text('Không có dữ liệu\n>= 15 ngày', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey)))
                        
                        // 3. VẼ BIỂU ĐỒ TRÒN
                        : PieChart(PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedPieIndices[pc['key'] as String] = -1;
                                    return;
                                  }
                                  _touchedPieIndices[pc['key'] as String] = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            sections: sortedKeys.asMap().entries.map((e) {
                              // Tính toán màu sắc tự động cho từng lát cắt (dựa vào hue)
                              double hue = (e.key * (360 / sortedKeys.length)) % 360;
                              bool isTouched = e.key == touchedIndex;
                              Color sliceColor = HSLColor.fromAHSL(1, hue, 0.7, 0.55).toColor();
                              
                              return PieChartSectionData(
                                value: values[e.key].toDouble(), // Độ lớn lát cắt (tần suất)
                                title: '${e.value}n',            // Tiêu đề lát cắt (số ngày gan, VD: "15n")
                                color: sliceColor,
                                radius: isTouched ? 42 : 35, 
                                titleStyle: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.white),
                              );
                            }).toList(),
                            sectionsSpace: 2, // Khoảng cách giữa các lát cắt
                          )),
                    ),
                    const SizedBox(height: 4),
                    // Hộp chú thích khi chọn mốc
                    SizedBox(
                      height: 22,
                      child: touchedIndex != -1 && touchedIndex < sortedKeys.length
                          ? _buildPieTooltip(
                              sortedKeys[touchedIndex],
                              values[touchedIndex],
                              totalHits,
                              HSLColor.fromAHSL(1, (touchedIndex * (360 / sortedKeys.length)) % 360, 0.7, 0.55).toColor(),
                              isDark,
                            )
                          : const Center(child: Text('Chạm vào lát cắt để xem chi tiết', style: TextStyle(fontSize: 8, color: Colors.grey))),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPieTooltip(int days, int freq, int total, Color color, bool isDark) {
    double percent = total > 0 ? (freq / total * 100) : 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 9, color: isDark ? Colors.white70 : Colors.black87),
            children: [
              TextSpan(text: '$days ngày: ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: '$freq lần ', style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(
                text: '(${percent.toStringAsFixed(1)}%)', 
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.redAccent : AppTheme.primaryRed)
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================
  // 10. LINE CHARTS (Lịch sử gan khan)
  // =========================================
  Widget _buildLineCharts(StrategyData strategy, bool isDark) {
    final fieldConfigs = [
      {'key': 'gdb_first2', 'name': 'ĐẦU ĐẶC BIỆT'},
      {'key': 'gdb_last2', 'name': 'CUỐI ĐẶC BIỆT'},
      {'key': 'g1_first2', 'name': 'ĐẦU GIẢI NHẤT'},
      {'key': 'g1_last2', 'name': 'CUỐI GIẢI NHẤT'},
    ];
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.amber];

    if (!fieldConfigs.any((fc) => fc['key'] == _activeLineField)) {
      _activeLineField = fieldConfigs.first['key']!;
    }
    String activeFieldName = fieldConfigs.firstWhere((fc) => fc['key'] == _activeLineField)['name']!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text('BIỂU ĐỒ ĐƯỜNG: LỊCH SỬ GAN KHAN (>= 15 NGÀY) TỪ 1996 ĐẾN NAY',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.primaryRed),
            textAlign: TextAlign.center),
          const SizedBox(height: 12),
          // Field tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: fieldConfigs.map((fc) {
                bool active = fc['key'] == _activeLineField;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _activeLineField = fc['key']!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.primaryRed : Colors.transparent,
                        border: Border.all(color: active ? AppTheme.primaryRed : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(fc['name']!, style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 10,
                        color: active ? Colors.white : Colors.grey.shade600,
                      )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Chart Container matching Web UI
          Container(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(activeFieldName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Color(0xFF084298))),
                const SizedBox(height: 8),
                // Legend
                Wrap(
                  spacing: 12, runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: strategy.cols.asMap().entries.map((e) {
                    Color c = colors[e.key % colors.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text(e.value, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey)),
                      ],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // Line Chart
                SizedBox(
                  height: 250,
                  child: _buildLineChartForField(strategy, _activeLineField, colors, isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartForField(StrategyData strategy, String fieldKey, List<Color> colors, bool isDark) {
    final f = strategy.fields[fieldKey]!;
    final cols = strategy.cols;

    // Collect all data points
    List<_LinePoint> allPoints = [];
    for (var col in cols) {
      for (var cy in (f.ganCycles[col] ?? [])) {
        if (cy.length >= 15 && cy.to.isNotEmpty) {
          try {
            final parts = cy.to.split('/');
            if (parts.length == 3) {
              String y = parts[2].length == 2 ? '20${parts[2]}' : parts[2];
              String iso = '$y-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
              allPoints.add(_LinePoint(col: col, dateIso: iso, val: cy.length));
            }
          } catch (_) {}
        }
      }
    }

    allPoints.sort((a, b) => a.dateIso.compareTo(b.dateIso));
    if (allPoints.isEmpty) {
      return const Center(child: Text('Chưa có dữ liệu gan >= 15 ngày', style: TextStyle(color: Colors.grey)));
    }

    List<String> uniqueDates = allPoints.map((p) => p.dateIso).toSet().toList()..sort();
    double maxVal = allPoints.map((p) => p.val).reduce(max).toDouble();

    List<LineChartBarData> datasets = cols.asMap().entries.map((e) {
      Color c = colors[e.key % colors.length];
      List<FlSpot> spots = [];
      for (int i = 0; i < uniqueDates.length; i++) {
        var pt = allPoints.where((p) => p.col == e.value && p.dateIso == uniqueDates[i]).firstOrNull;
        if (pt != null) spots.add(FlSpot(i.toDouble(), pt.val.toDouble()));
      }
      return LineChartBarData(
        spots: spots, color: c, barWidth: 2,
        dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
          FlDotCirclePainter(radius: 3, color: c, strokeWidth: 1, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: false),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: SizedBox(
        width: max(uniqueDates.length * 50.0, MediaQuery.of(context).size.width - 48),
        child: LineChart(LineChartData(
          lineBarsData: datasets,
          minY: 10, maxY: maxVal + 5,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 50, interval: 1,
              getTitlesWidget: (v, _) {
                int idx = v.toInt();
                if (idx < 0 || idx >= uniqueDates.length) return const SizedBox.shrink();
                try {
                  final d = DateTime.parse(uniqueDates[idx]);
                  return Transform.rotate(angle: -0.8,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  );
                } catch (_) { return const SizedBox.shrink(); }
              },
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
            )),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: true,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            getDrawingVerticalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1)),
          borderData: FlBorderData(show: true, border: Border(
            bottom: BorderSide(color: Colors.grey.shade300),
            left: BorderSide(color: Colors.grey.shade300),
            top: BorderSide(color: Colors.grey.shade100),
            right: BorderSide(color: Colors.grey.shade100),
          )),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
              return spotIndexes.map((index) {
                return TouchedSpotIndicatorData(
                  FlLine(color: barData.color ?? Colors.blue, strokeWidth: 2.5),
                  FlDotData(show: true, getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(radius: 5, color: barData.color ?? Colors.blue, strokeWidth: 2, strokeColor: Colors.white)),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: const Color(0xFF546E7A), // Slate gray matching image
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tooltipRoundedRadius: 6,
              getTooltipItems: (spots) => spots.map((s) {
                int datasetIdx = datasets.indexOf(datasets.firstWhere((d) => d.spots.contains(FlSpot(s.x, s.y)), orElse: () => datasets.first));
                String colName = cols[datasetIdx % cols.length];
                
                String dateIso = '';
                String dateStr = '';
                int idx = s.x.toInt();
                if (idx >= 0 && idx < uniqueDates.length) {
                  dateIso = uniqueDates[idx];
                  try {
                    final d = DateTime.parse(dateIso);
                    dateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
                  } catch (_) {}
                }
                
                int val = s.y.toInt();
                
                var matching = allPoints.where((p) => p.col == colName && p.val == val).toList();
                int occurrence = matching.indexWhere((p) => p.dateIso == dateIso) + 1;
                if (occurrence == 0) occurrence = 1;
                int total = matching.length;

                return LineTooltipItem(
                  '$colName\n',
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white),
                  textAlign: TextAlign.center,
                  children: [
                    if (dateStr.isNotEmpty)
                      TextSpan(
                        text: '$dateStr\n',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    TextSpan(
                      text: '$val ngày',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    TextSpan(
                      text: '\n(Lần thứ $occurrence đạt mức này / tổng $total lần)',
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: Colors.white70),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        )),
      ),
    );
  }

  // =========================================
  // 11. MAX GAN SUMMARY
  // =========================================
  Widget _buildMaxGanSummary(StrategyData strategy, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: Border.all(color: const Color(0xFFCCE5FF)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE7F1FF),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
            ),
            child: Text('TỔNG KẾT KỶ LỤC GAN CỰC ĐẠI - ${strategy.name}'.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF084298))),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ['gdb_first2', 'gdb_last2', 'g1_first2', 'g1_last2'].map((fk) {
                final f = strategy.fields[fk]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 5),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0D0D0), style: BorderStyle.solid))),
                      child: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryRed, fontSize: 13)),
                    ),
                    const SizedBox(height: 8),
                    ...strategy.cols.map((col) {
                      final displayName = colDisplayNames[col] ?? col;
                      int ganNow = f.gan[col] ?? 0;
                      int ganMax = f.maxGan[col] ?? 0;
                      String ganDates = f.maxGanDates[col] ?? '---';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 10),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF444444)),
                            children: [
                              const TextSpan(text: '• Bộ '),
                              TextSpan(text: displayName, style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryRed)),
                              if (ganNow == 0)
                                const TextSpan(text: ' vừa nổ xong', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.green))
                              else
                                TextSpan(children: [
                                  const TextSpan(text: ' đã '),
                                  TextSpan(text: '$ganNow', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green)),
                                  const TextSpan(text: ' ngày chưa ra'),
                                ]),
                              const TextSpan(text: ', cực đại là '),
                              TextSpan(text: '$ganMax', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryRed)),
                              const TextSpan(text: ' ngày '),
                              TextSpan(text: '($ganDates)', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // 12. GAN ĐỀ GRID (Đuôi ĐB lâu chưa ra)
  // =========================================
  Widget _buildGanDeGrid(Map<String, int> ganGdbTail, bool isDark) {
    // Sort by gan days descending
    final sorted = ganGdbTail.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final filtered = sorted.where((e) => e.value >= _ganFilterMin).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFFDFD),
        border: Border.all(color: const Color(0xFFF0E6D2)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ĐUÔI ĐẶC BIỆT LÂU CHƯA RA',
                style: TextStyle(color: AppTheme.primaryRed, fontWeight: FontWeight.w900, fontSize: 13)),
              Row(
                children: [
                  const Text('Lọc >=', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed, fontSize: 13),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        border: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryRed)),
                        isDense: true,
                      ),
                      controller: TextEditingController(text: _ganFilterMin.toString()),
                      onChanged: (v) {
                        final val = int.tryParse(v);
                        if (val != null) setState(() => _ganFilterMin = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('ngày', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Grid
          Wrap(
            spacing: 8, runSpacing: 8,
            children: filtered.map((e) => Container(
              width: 100,
              height: 34,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 35,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFFAFA),
                      border: Border(right: BorderSide(color: Colors.green)),
                    ),
                    child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.primaryRed, fontFamily: 'Consolas')),
                  ),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.white,
                      child: Text('${e.value} ngày', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF198754))),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Không có số nào gan >= giá trị lọc', style: TextStyle(color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}

/// Helper class for line chart data points
class _LinePoint {
  final String col;
  final String dateIso;
  final int val;
  _LinePoint({required this.col, required this.dateIso, required this.val});
}