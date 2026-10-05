import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomBarChart extends StatelessWidget {
  final Map<int, int> data; // Digit: count

  const CustomBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    final barGroups = List.generate(10, (index) {
      final val = data[index] ?? 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: val.toDouble(),
            color: index == 0 || index == 9 ? AppTheme.accentGold : primaryColor,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 15,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
          )
        ],
      );
    });

    return RepaintBoundary(
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 15,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) => Text(
                    val.toInt().toString(),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppTheme.lightTextSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }
}

class CustomPieChart extends StatelessWidget {
  final int oddCount;
  final int evenCount;

  const CustomPieChart({super.key, required this.oddCount, required this.evenCount});

  @override
  Widget build(BuildContext context) {
    final total = oddCount + evenCount;
    final oddPercent = total > 0 ? (oddCount / total * 100).toStringAsFixed(1) : '0';
    final evenPercent = total > 0 ? (evenCount / total * 100).toStringAsFixed(1) : '0';

    return RepaintBoundary(
      child: SizedBox(
        height: 150,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 30,
            sections: [
              PieChartSectionData(
                color: AppTheme.primaryRed,
                value: oddCount.toDouble(),
                title: 'Lẻ\n$oddPercent%',
                radius: 40,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              PieChartSectionData(
                color: AppTheme.accentGold,
                value: evenCount.toDouble(),
                title: 'Chẵn\n$evenPercent%',
                radius: 40,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomLineChart extends StatelessWidget {
  final List<double> values;

  const CustomLineChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final spots = List.generate(values.length, (index) {
      return FlSpot(index.toDouble(), values[index]);
    });

    return RepaintBoundary(
      child: SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            lineTouchData: const LineTouchData(enabled: true),
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: isDark ? Colors.white10 : Colors.black12,
                strokeWidth: 0.5,
              ),
            ),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.primaryRed,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.primaryRed.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 10x10 Heatmap Grid representing numbers 00 to 99
class CustomHeatmapGrid extends StatelessWidget {
  final Map<String, int> data; // "00": count, "01": count

  const CustomHeatmapGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Helper to calculate maximum occurrence to set opacity scale
    int maxVal = 1;
    data.forEach((k, v) {
      if (v > maxVal) maxVal = v;
    });

    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 10,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: 100,
        itemBuilder: (context, index) {
          final numStr = index.toString().padLeft(2, '0');
          final freq = data[numStr] ?? 0;

          // Calculate opacity based on occurrence frequency
          final double opacity = freq > 0 ? 0.2 + (freq / maxVal) * 0.8 : 0.0;
          final color = freq > 0 
              ? AppTheme.primaryRed.withValues(alpha: opacity.clamp(0.0, 1.0)) 
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04));

          final textColor = freq > 0 
              ? (opacity > 0.6 ? Colors.white : (isDark ? Colors.white : AppTheme.lightTextPrimary))
              : (isDark ? Colors.white38 : AppTheme.lightTextSecondary.withValues(alpha: 0.5));

          return GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Số $numStr xuất hiện $freq lần trong chu kỳ vừa qua'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: freq > 0 && opacity > 0.7
                    ? Border.all(color: AppTheme.accentGold, width: 1)
                    : null,
              ),
              child: Text(
                numStr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: freq > 0 ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
