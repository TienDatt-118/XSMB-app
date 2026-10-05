import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class QuickStatsSection extends StatelessWidget {
  final QuickStatsData data;
  final bool isLoading;

  const QuickStatsSection({
    super.key,
    required this.data,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFDEE2E6);
    final cardBg = isDark ? const Color(0xFF2C3034) : Colors.white;

    if (isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryRed),
              SizedBox(height: 12),
              Text('Đang tải thống kê nhanh...', style: TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header chính chuẩn màu AppTheme
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: const BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'THỐNG KÊ NHANH CHO NGÀY ${data.targetDate.toUpperCase()}',
                    style: const TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                       fontSize: 14,
                       letterSpacing: 0.3,
                     ),
                  ),
                ),
                if (!data.isFromWeb)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Offline',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. Lotto lâu chưa ra (lotto gan)
                _buildSubHeader(
                  title: 'Lotto lâu chưa ra (lotto gan):',
                  icon: Icons.timer_outlined,
                  color: AppTheme.primaryRed,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildLotoGanGrid(data.lotoGanList, isDark, borderColor),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 3. Lotto ra nhiều trong tháng qua
                _buildSubHeader(
                  title: 'Lotto ra nhiều trong tháng qua:',
                  icon: Icons.whatshot_rounded,
                  color: AppTheme.accentGold,
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildLotoFrequencyGrid(data.lotoFrequencyList, isDark, borderColor),

                const SizedBox(height: 16),

                // 4. Các cặp lotto dẫn đầu bảng gan
                if (data.leadingGan != null) ...[
                  _buildLeadingGanBanner(data.leadingGan!, isDark),
                  const SizedBox(height: 16),
                ],

                const Divider(height: 1),
                const SizedBox(height: 16),

                // 5. Đặc biệt lâu chưa ra (Đề gan)
                _buildSubHeader(
                  title: 'Đặc biệt lâu chưa ra (Đề gan):',
                  icon: Icons.star_border_rounded,
                  color: const Color(0xFFC20171),
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                _buildDeGanGrid(data.deGanList, isDark, borderColor),

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 6. Thống kê gan đặc biệt theo Tổng
                _buildSubHeader(
                  title: 'Thống kê gan đặc biệt theo tổng (0 - 9):',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF770060),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildGanChart(
                  items: data.ganTongList
                      .map((e) => _ChartBarData(
                            label: e.tong.toString(),
                            days: e.days,
                            subtext: 'ng',
                          ))
                      .toList(),
                  isDark: isDark,
                  primaryColor: const Color(0xFF770060),
                ),
                if (data.topTongDesc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDescNote(data.topTongDesc, isDark),
                ],

                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 7. Thống kê gan đặc biệt theo Chạm
                _buildSubHeader(
                  title: 'Thống kê gan đặc biệt theo chạm (0 - 9):',
                  icon: Icons.view_column_rounded,
                  color: const Color(0xFF0061B0),
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildGanChart(
                  items: data.ganChamList
                      .map((e) => _ChartBarData(
                            label: e.cham.toString(),
                            days: e.days,
                            subtext: 'ng',
                          ))
                      .toList(),
                  isDark: isDark,
                  primaryColor: const Color(0xFF0061B0),
                ),
                if (data.topChamDesc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildDescNote(data.topChamDesc, isDark),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF212529),
          ),
        ),
      ],
    );
  }

  Widget _buildLotoGanGrid(List<LotoGanItem> list, bool isDark, Color borderColor) {
    if (list.isEmpty) {
      return Text('Không có số liệu lô gan', style: TextStyle(fontSize: 12, color: Colors.grey[500]));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 24) / 4; // 4 columns
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.map((item) {
          return Container(
            width: itemWidth,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF212529) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${item.days} ng',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF495057),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildLotoFrequencyGrid(List<LotoFrequencyItem> list, bool isDark, Color borderColor) {
    if (list.isEmpty) {
      return Text('Không có số liệu tần suất', style: TextStyle(fontSize: 12, color: Colors.grey[500]));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 24) / 4; // 4 columns
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.map((item) {
          return Container(
            width: itemWidth,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF212529) : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.accentGold,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${item.count} lần',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : const Color(0xFF495057),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildLeadingGanBanner(LeadingGanItem leading, bool isDark) {
    final rangeText = (leading.fromDate.isNotEmpty && leading.toDate.isNotEmpty)
        ? ' (từ ${leading.fromDate} đến ${leading.toDate})'
        : '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF321E36) : const Color(0xFFFDF0F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC20171).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFC20171), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white : const Color(0xFF212529),
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Cặp số dẫn đầu bảng gan: Cặp số '),
                      TextSpan(
                        text: leading.number,
                        style: const TextStyle(
                          color: Color(0xFF8E00CC),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const TextSpan(text: ' đã '),
                      TextSpan(
                        text: '${leading.currentDays}',
                        style: const TextStyle(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const TextSpan(text: ' ngày chưa ra, cực đại là '),
                      TextSpan(
                        text: '${leading.maxDays}',
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      TextSpan(text: ' ngày$rangeText.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Text(
            '(Dữ liệu thống kê dựa trên lịch sử KQXS)',
            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDeGanGrid(List<DeGanItem> list, bool isDark, Color borderColor) {
    if (list.isEmpty) {
      return Text('Không có số liệu đề gan', style: TextStyle(fontSize: 12, color: Colors.grey[500]));
    }

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 24) / 4; // 4 columns
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: list.take(16).map((item) {
          return Container(
            width: itemWidth,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A1E20) : const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? AppTheme.primaryRed.withValues(alpha: 0.3) : const Color(0xFFF5C2C7),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.number,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.primaryRed,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${item.days} ng',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : const Color(0xFF842029),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildGanChart({
    required List<_ChartBarData> items,
    required bool isDark,
    required Color primaryColor,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxDays = items.map((e) => e.days).reduce(max);
    final effectiveMax = maxDays > 0 ? maxDays : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalItems = items.length;
        final slotWidth = totalItems > 0 ? (availableWidth / totalItems) : 36.0;
        final barWidth = max(14.0, min(24.0, slotWidth - 10.0));

        Widget content = Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: items.map((item) {
            final barHeight = (item.days / effectiveMax) * 80.0 + 16.0;
            final isPeak = item.days == maxDays && item.days > 0;

            return SizedBox(
              width: slotWidth > 36 ? slotWidth : 36,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Số ngày trên cột
                  Text(
                    '${item.days}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPeak ? AppTheme.primaryRed : (isDark ? Colors.grey[400] : Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Cột biểu đồ
                  Container(
                    height: barHeight,
                    width: barWidth,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      gradient: LinearGradient(
                        colors: isPeak
                            ? [AppTheme.primaryRed, const Color(0xFFFF7851)]
                            : [primaryColor.withValues(alpha: 0.85), primaryColor.withValues(alpha: 0.5)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Số Tổng hoặc Chạm (0..9)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : const Color(0xFFE9ECEF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF212529),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );

        if (availableWidth < 340) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }
        return content;
      },
    );
  }

  Widget _buildDescNote(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.white70 : const Color(0xFF495057),
          height: 1.35,
        ),
      ),
    );
  }
}

class _ChartBarData {
  final String label;
  final int days;
  final String subtext;

  _ChartBarData({
    required this.label,
    required this.days,
    required this.subtext,
  });
}
