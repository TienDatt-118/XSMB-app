import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/lottery_provider.dart';
import '../models/models.dart';
import '../widgets/shimmer_loading.dart';

import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LotteryProvider>();
      provider.fetchHistoryRange(provider.historyFromDate, provider.historyToDate);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Pick Date Filter
  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final provider = context.read<LotteryProvider>();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? provider.historyFromDate : provider.historyToDate,
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
      if (isFrom) {
        provider.setHistoryDates(picked, provider.historyToDate);
      } else {
        provider.setHistoryDates(provider.historyFromDate, picked);
      }
      if (context.mounted) {
        provider.fetchHistoryRange(provider.historyFromDate, provider.historyToDate);
      }
    }
  }

  List<LotteryResult> _getFilteredList(List<LotteryResult> originalList) {
    var list = List<LotteryResult>.from(originalList);

    // Filter by search query (checks if special prize contains the query, etc.)
    if (_searchQuery.isNotEmpty) {
      list = list.where((item) => item.db.contains(_searchQuery) || item.drawDate.contains(_searchQuery)).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _getFilteredList(provider.rangeHistoryResults);

    return Scaffold(

      appBar: AppBar(
        title: const Text('LỊCH SỬ KỲ QUAY', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Search query bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo giải Đặc biệt hoặc ngày...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          
          // Date Range pickers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: isDark ? AppTheme.darkSurface : Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Từ ngày', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd/MM/yyyy').format(provider.historyFromDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Đến ngày', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd/MM/yyyy').format(provider.historyToDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: filteredList.isEmpty && provider.isLoadingHistory
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ShimmerListLoading(),
                  )
                : filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Không tìm thấy kết quả phù hợp.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                provider.fetchHistory(isRefresh: true);
                              },
                              child: const Text('Tải lại'),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];
                          return _HistoryCard(widgetItem: item);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final LotteryResult widgetItem;
  const _HistoryCard({required this.widgetItem});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.widgetItem;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : AppTheme.primaryRed;
    final headerColor = isDark ? Colors.grey.shade800 : const Color(0xFFF8D7DA);
    final labelColor = isDark ? Colors.white70 : AppTheme.primaryRed;

    TableRow buildRow(String label, String numberStr, {bool isDb = false}) {
      List<String> numbers = numberStr.split(',').where((e) => e.isNotEmpty).toList();
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

    Widget buildHalfTable(String title, Map<int, List<int>> stats, bool isHead) {
      List<TableRow> rows = [];
      rows.add(TableRow(
        decoration: BoxDecoration(color: headerColor),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Center(
              child: Text(
                isHead ? 'Đầu' : 'Đuôi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: labelColor),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Center(
              child: Text(
                'Lô tô',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: labelColor),
              ),
            ),
          ),
        ]
      ));

      for (int i = 0; i < 10; i++) {
        String numbers = stats[i]?.join(', ') ?? '';
        rows.add(TableRow(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              color: isDark ? Colors.grey.shade900 : const Color(0xFFFFFDFD),
              child: Center(
                child: Text(
                  '$i',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryRed,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Text(
                numbers,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ]
        ));
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1.0),
          borderRadius: BorderRadius.circular(6),
          color: isDark ? Colors.grey.shade900 : Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: isHead ? AppTheme.accentGold : const Color(0xFFE0A800),
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              Table(
                border: TableBorder.symmetric(
                  inside: BorderSide(color: borderColor, width: 0.5),
                ),
                columnWidths: const {
                  0: FixedColumnWidth(30),
                  1: FlexColumnWidth(),
                },
                children: rows,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.04),
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(8))
                    : BorderRadius.circular(8),
                border: _isExpanded
                    ? Border(bottom: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300))
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kỳ quay ngày: ${TimeUtils.formatDisplayDate(item.drawDate)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      if (!_isExpanded)
                        const SizedBox(height: 4),
                      if (!_isExpanded)
                        Text(
                          item.db.isEmpty ? 'Chưa có kết quả (Chờ quay số)' : 'Đặc biệt: ${item.db}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.db.isEmpty ? Colors.orange : AppTheme.primaryRed,
                            fontSize: 14,
                            fontStyle: item.db.isEmpty ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      if (!_isExpanded)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Xem chi tiết',
                            style: TextStyle(fontSize: 11, color: AppTheme.primaryRed, fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: item.db.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.pending_actions, size: 48, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          'Kỳ quay chưa diễn ra hoặc chưa có kết quả. Dữ liệu sẽ tự động cập nhật khi có kết quả mới.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor, width: 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(90),
                                1: FlexColumnWidth(),
                              },
                              border: TableBorder.symmetric(
                                inside: BorderSide(color: borderColor, width: 1),
                              ),
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                buildRow('Đặc biệt', item.db, isDb: true),
                                buildRow('Giải Nhất', item.g1),
                                buildRow('Giải Nhì', item.g2.join(',')),
                                buildRow('Giải Ba', item.g3.join(',')),
                                buildRow('Giải Tư', item.g4.join(',')),
                                buildRow('Giải Năm', item.g5.join(',')),
                                buildRow('Giải Sáu', item.g6.join(',')),
                                buildRow('Giải Bảy', item.g7.join(',')),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: buildHalfTable('ĐẦU LÔ TÔ', item.headStats, true),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: buildHalfTable('ĐUÔI LÔ TÔ', item.tailStats, false),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
