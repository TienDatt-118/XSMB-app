import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lottery_provider.dart';

import '../theme/app_theme.dart';
import '../models/models.dart';

class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({super.key});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();

  final ScrollController _verticalTitleController = ScrollController();
  final ScrollController _verticalBodyController = ScrollController();
  final ScrollController _horizontalTitleController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();

  @override
  void initState() {
    super.initState();
    _verticalBodyController.addListener(() {
      if (_verticalTitleController.hasClients && _verticalTitleController.offset != _verticalBodyController.offset) {
        _verticalTitleController.jumpTo(_verticalBodyController.offset);
      }
    });
    _verticalTitleController.addListener(() {
      if (_verticalBodyController.hasClients && _verticalBodyController.offset != _verticalTitleController.offset) {
        _verticalBodyController.jumpTo(_verticalTitleController.offset);
      }
    });
    _horizontalBodyController.addListener(() {
      if (_horizontalTitleController.hasClients && _horizontalTitleController.offset != _horizontalBodyController.offset) {
        _horizontalTitleController.jumpTo(_horizontalBodyController.offset);
      }
    });
    _horizontalTitleController.addListener(() {
      if (_horizontalBodyController.hasClients && _horizontalBodyController.offset != _horizontalTitleController.offset) {
        _horizontalBodyController.jumpTo(_horizontalTitleController.offset);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void dispose() {
    _verticalTitleController.dispose();
    _verticalBodyController.dispose();
    _horizontalTitleController.dispose();
    _horizontalBodyController.dispose();
    super.dispose();
  }

  void _fetchData() {
    context.read<LotteryProvider>().fetchThongKeHistory(_fromDate, _toDate);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _fetchData();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final thongKeData = provider.thongKeData;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      appBar: AppBar(
        title: const Text('THỐNG KÊ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter Controls
          Container(
            padding: const EdgeInsets.all(12),
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFF0F3),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, true),
                    child: _buildDateBox('Từ ngày', _formatDate(_fromDate), isDark),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDate(context, false),
                    child: _buildDateBox('Đến ngày', _formatDate(_toDate), isDark),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _fetchData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('XEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
          
          // Data Grid
          Expanded(
            child: provider.isLoadingAnalysis
                ? const Center(child: CircularProgressIndicator())
                : (thongKeData == null || thongKeData.history.isEmpty)
                    ? const Center(child: Text('Không có dữ liệu.'))
                    : _buildGrid(thongKeData, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDateBox(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.black45 : Colors.white,
        border: Border.all(color: AppTheme.primaryRed.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: AppTheme.primaryRed, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGrid(ThongKeData data, bool isDark) {
    final history = data.history;
    final maxFreq = data.maxFrequency > 0 ? data.maxFrequency : 1;

    // Tổng số cột là 101 (1 cột ngày + 100 cột số)
    return InteractiveViewer(
      constrained: false, // Cho phép bảng rộng hơn màn hình
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 2.0,
      child: Table(
        defaultColumnWidth: const FixedColumnWidth(30.0),
        columnWidths: const {0: FixedColumnWidth(90.0)}, // Cột ngày rộng hơn
        children: [
          // 1. Dòng Header
          TableRow(children: [
            _buildCell('Ngày', isHeader: true, isDateCol: true, isDark: isDark),
            ...List.generate(100, (i) => _buildCell(i.toString().padLeft(2, '0'), isHeader: true, isDark: isDark)),
          ]),
          // 2. Dòng Tần suất
          TableRow(children: [
            _buildCell('Tần suất', isDateCol: true, isFreqCol: true, isDark: isDark),
            ...List.generate(100, (i) => _buildFreqBar(data.frequencies[i.toString().padLeft(2, '0')] ?? 0, maxFreq, isDark)),
          ]),
          // 3. Dòng Lịch sử
          ...history.map((result) {
            return TableRow(children: [
              _buildCell(_formatShortDate(result.drawDate), isDateCol: true, isDark: isDark),
              ...List.generate(100, (i) => _buildResultCell(result, i.toString().padLeft(2, '0'), isDark)),
            ]);
          }).toList(),
        ],
      ),
    );
  }

  String _formatShortDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  Widget _buildCell(String text, {
    bool isHeader = false,
    bool isDateCol = false,
    bool isFreqCol = false,
    bool isFreqNum = false,
    bool isDark = false,
    double height = 26,
  }) {
    Color bgColor = Colors.transparent;
    Color textColor = isDark ? Colors.white : Colors.black87;
    FontWeight fw = FontWeight.normal;

    if (isHeader) {
      bgColor = isDateCol ? const Color(0xFFB71C2E) : const Color(0xFFDC3545);
      textColor = Colors.white;
      fw = FontWeight.bold;
    } else if (isDateCol) {
      bgColor = isDark ? const Color(0xFF333333) : const Color(0xFFFFF0F3);
      textColor = AppTheme.primaryRed;
      fw = FontWeight.bold;
    } else if (isFreqCol) {
      bgColor = isDark ? const Color(0xFF333333) : const Color(0xFFFFF0F3);
      textColor = Colors.grey;
    } else if (isFreqNum) {
      bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFF0F3);
      textColor = AppTheme.primaryRed;
      fw = FontWeight.bold;
    }

    return Container(
      width: isDateCol ? 90 : 30,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFF8D7DA), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: fw,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildFreqBar(int count, int maxFreq, bool isDark) {
    double heightRatio = count / maxFreq;
    if (heightRatio > 1.0) heightRatio = 1.0;
    
    return Container(
      width: 30,
      height: 40,
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFFFF0F3),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFF8D7DA), width: 0.5),
      ),
      child: Container(
        width: 18,
        height: 40 * heightRatio,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE91E63), Color(0xFFDC3545)],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
        ),
      ),
    );
  }

  Widget _buildResultCell(LotteryResult result, String numStr, bool isDark) {
    int hitCount = 0;
    bool isGdb = false;

    if (result.db.length >= 2 && result.db.substring(result.db.length - 2) == numStr) {
      isGdb = true;
      hitCount++;
    }

    // Check all other prizes
    for (var num in result.allNumbers) {
      if (num != result.db) { // Avoid double counting DB if already checked
        if (num.length >= 2 && num.substring(num.length - 2) == numStr) {
          hitCount++;
        }
      }
    }

    Color bgColor = Colors.transparent;
    Color textColor = isDark ? Colors.white70 : Colors.black87;
    FontWeight fw = FontWeight.normal;
    String text = '';

    if (hitCount > 0) {

      text = hitCount.toString();

      if (isGdb) {

        bgColor = const Color(0xFFDC3545);

        textColor = Colors.white;

        fw = FontWeight.bold;

      }
      else if (hitCount >= 2) {

        bgColor = const Color(0xFFE91E63);

        textColor = Colors.white;

        fw = FontWeight.bold;

      }
      else {

        bgColor = isDark
            ? const Color(0xFF5C2B35)
            : const Color(0xFFFCE4EC);

        textColor = const Color(0xFFC82333);

        fw = FontWeight.bold;

      }

    }

    return Container(
      width: 30,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFF8D7DA), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: fw,
          fontSize: 11,
          shadows: isGdb ? [const Shadow(color: Colors.white54, blurRadius: 4)] : null,
        ),
      ),
    );
  }
}
