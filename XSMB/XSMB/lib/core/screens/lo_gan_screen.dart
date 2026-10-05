import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lottery_provider.dart';
import '../models/models.dart';
import '../widgets/shimmer_loading.dart';

import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class LoGanScreen extends StatefulWidget {
  const LoGanScreen({super.key});

  @override
  State<LoGanScreen> createState() => _LoGanScreenState();
}

class _LoGanScreenState extends State<LoGanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1); // Default to Today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LotteryProvider>().fetchLoGanList();
      context.read<LotteryProvider>().fetchLoTopData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final now = TimeUtils.nowVN;
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));

    String formatDay(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}";

    return Scaffold(

      appBar: AppBar(
        title: const Text('LÔ TOP', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 4,
          labelPadding: EdgeInsets.zero,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hôm qua', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatDay(yesterday), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hôm nay', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatDay(now), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ngày mai', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatDay(tomorrow), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Hôm qua
          _buildDayTab(
            title: 'LÔ TOP - ${formatDay(yesterday)}/${yesterday.year}',
            headerBgColor: isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF3E0),
            headerTextColor: isDark ? Colors.orangeAccent : const Color(0xFFE65100),
            isLoading: provider.isLoadingLoTop,
            data: provider.yesterdayTop,
            isDark: isDark,
          ),

          // TAB 2: Hôm nay
          _buildDayTab(
            title: 'LÔ TOP HÔM NAY - ${formatDay(now)}/${now.year}',
            headerBgColor: isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9),
            headerTextColor: isDark ? Colors.greenAccent : const Color(0xFF2E7D32),
            isLoading: provider.isLoadingLoTop,
            data: provider.todayTop,
            isToday: true,
            isDark: isDark,
          ),

          // TAB 3: Ngày mai (Dự đoán từ Lô Gan)
          _buildTomorrowTab(
            title: 'DỰ ĐOÁN LÔ TOP - ${formatDay(tomorrow)}/${tomorrow.year}',
            headerBgColor: isDark ? const Color(0xFF311B92) : const Color(0xFFEDE7F6),
            headerTextColor: isDark ? Colors.deepPurpleAccent : const Color(0xFF4527A0),
            isLoading: provider.isLoadingLoGan,
            loGanList: provider.loGanList,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab({
    required String title,
    required Color headerBgColor,
    required Color headerTextColor,
    required bool isLoading,
    required List<LoTopItem> data,
    bool isToday = false,
    required bool isDark,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: ShimmerListLoading(),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: headerBgColor,
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: headerTextColor,
            ),
          ),
        ),
        Expanded(
          child: data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? 'Chưa có kết quả hôm nay' : 'Không có dữ liệu',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      if (isToday)
                        const Text(
                          'Kết quả sẽ cập nhật sau 18:15',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(isDark ? Colors.black54 : Colors.black87),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      dataRowMinHeight: 45,
                      dataRowMaxHeight: 55,
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('STT')),
                        DataColumn(label: Text('Số')),
                        DataColumn(label: Text('Lần về')),
                        DataColumn(label: Text('Giải')),
                        DataColumn(label: Text('Tổng')),
                      ],
                      rows: List.generate(data.length, (index) {
                        final item = data[index];
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(
                              Text(
                                item.number,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: isDark ? Colors.redAccent : AppTheme.primaryRed,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: item.hitCount >= 2 ? AppTheme.primaryRed : Colors.grey.shade600,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.hitCount >= 2 ? '${item.hitCount} nháy' : '1',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            DataCell(
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: item.prizes.map((p) {
                                  final isDB = p == 'GĐB';
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDB ? AppTheme.primaryRed : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                      border: Border.all(color: isDB ? AppTheme.primaryRed : Colors.grey.shade400),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      p,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDB ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                        fontWeight: isDB ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            DataCell(Text('${item.totalHistoricalHits}')),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTomorrowTab({
    required String title,
    required Color headerBgColor,
    required Color headerTextColor,
    required bool isLoading,
    required List<LoGanModel> loGanList,
    required bool isDark,
  }) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: ShimmerListLoading(),
      );
    }

    // Sort descending by missing days to get top Gan
    var sortedList = List<LoGanModel>.from(loGanList);
    sortedList.sort((a, b) => b.missingDays.compareTo(a.missingDays));
    final topList = sortedList.take(30).toList(); // Show top 30 predictions

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          color: headerBgColor,
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: headerTextColor,
            ),
          ),
        ),
        Expanded(
          child: topList.isEmpty
              ? const Center(child: Text('Không có dữ liệu Lô Gan', style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF311B92) : const Color(0xFF4527A0)),
                      headingTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      dataRowMinHeight: 45,
                      dataRowMaxHeight: 55,
                      columnSpacing: 30,
                      columns: const [
                        DataColumn(label: Text('STT')),
                        DataColumn(label: Text('Số')),
                        DataColumn(label: Text('Lý do')),
                        DataColumn(label: Text('Gan hiện tại')),
                      ],
                      rows: List.generate(topList.length, (index) {
                        final item = topList[index];
                        return DataRow(
                          cells: [
                            DataCell(Text('${index + 1}')),
                            DataCell(
                              Text(
                                item.number,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: isDark ? Colors.deepPurpleAccent : const Color(0xFF4527A0),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                'Gan ${item.missingDays} ngày',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF00897B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${item.missingDays} ngày',
                                style: const TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
