import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lottery_provider.dart';
import '../models/models.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_charts.dart';
import '../widgets/shimmer_loading.dart';

import '../theme/app_theme.dart';

class DauDuoiScreen extends StatefulWidget {
  const DauDuoiScreen({super.key});

  @override
  State<DauDuoiScreen> createState() => _DauDuoiScreenState();
}

class _DauDuoiScreenState extends State<DauDuoiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LotteryProvider>().fetchDauDuoiStats();
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
    final data = provider.headTailStats;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(

      appBar: AppBar(
        title: const Text('BẢNG THỐNG KÊ ĐẦU ĐUÔI', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryRed,
          labelColor: AppTheme.primaryRed,
          unselectedLabelColor: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
          tabs: const [
            Tab(text: 'Thống Kê Đầu', icon: Icon(Icons.align_horizontal_left)),
            Tab(text: 'Thống Kê Đuôi', icon: Icon(Icons.align_horizontal_right)),
          ],
        ),
      ),
      body: provider.isLoadingDauDuoi
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: ShimmerChartsLoading(),
            )
          : data.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Không có dữ liệu Đầu Đuôi.'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => provider.fetchDauDuoiStats(),
                        child: const Text('Tải lại'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Heads (Đầu 0-9)
                    _buildStatsTab(context, data['head'] ?? []),
                    
                    // Tab 2: Tails (Đuôi 0-9)
                    _buildStatsTab(context, data['tail'] ?? [], isHead: false),
                  ],
                ),
    );
  }

  Widget _buildStatsTab(BuildContext context, List<HeadTailModel> stats, {bool isHead = true}) {
    // Convert List<HeadTailModel> to Map<int, int> for CustomBarChart
    final Map<int, int> chartMap = {};
    int maxVal = 1;
    for (var item in stats) {
      chartMap[item.digit] = item.count;
      if (item.count > maxVal) maxVal = item.count;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHead ? 'Tần Suất Xuất Hiện Theo Đầu' : 'Tần Suất Xuất Hiện Theo Đuôi',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: CustomBarChart(data: chartMap),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chi Tiết Số Lần & Tỷ Lệ Xuất Hiện',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final item = stats[index];
                // Highlight high frequencies (greater than 80% of max value)
                final isHigh = item.count >= (maxVal * 0.8).toInt();

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
                    border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Badge showing digit 0-9
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isHead ? AppTheme.primaryRed : AppTheme.accentGold,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${item.digit}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Value indicator bar representation
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Xuất hiện ${item.count} lần',
                                  style: TextStyle(
                                    fontWeight: isHigh ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  '${item.percentage.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Custom progress bar indicator
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.count / maxVal,
                                backgroundColor: Colors.grey.withValues(alpha: 0.1),
                                color: isHead ? AppTheme.primaryRed : AppTheme.accentGold,
                                minHeight: 6,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
