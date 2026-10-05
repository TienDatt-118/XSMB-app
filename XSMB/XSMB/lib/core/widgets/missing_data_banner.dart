import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MissingDataBanner extends StatelessWidget {
  final List<DateTime> missingDates;
  final bool isSyncing;
  final VoidCallback onSyncNow;

  const MissingDataBanner({
    super.key,
    required this.missingDates,
    required this.isSyncing,
    required this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    if (missingDates.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    const warningColor = AppTheme.orange; // Bootstrap Orange/Warning

    // Sắp xếp ngày từ cũ đến mới để lấy khoảng: từ ngày ... đến ngày ...
    final sorted = List<DateTime>.from(missingDates)..sort((a, b) => a.compareTo(b));
    final fromDate =
        '${sorted.first.day.toString().padLeft(2, '0')}/${sorted.first.month.toString().padLeft(2, '0')}/${sorted.first.year}';
    final toDate =
        '${sorted.last.day.toString().padLeft(2, '0')}/${sorted.last.month.toString().padLeft(2, '0')}/${sorted.last.year}';
    final isSingleDay = sorted.length == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? warningColor.withValues(alpha: 0.12)
            : const Color(0xFFFFF3CD), // Bootstrap warning bg
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? warningColor.withValues(alpha: 0.4)
              : const Color(0xFFFFECB5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dòng 1: Icon cảnh báo + Tiêu đề + Huy hiệu số ngày
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: isDark ? Colors.amberAccent : warningColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'CẢNH BÁO DỮ LIỆU CHƯA CÀO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.amberAccent : const Color(0xFF664D03),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: warningColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${sorted.length} ngày',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.amberAccent : warningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dòng 2: Khoảng ngày chi tiết + Nút Cào bù ngay
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : const Color(0xFF495057),
                      height: 1.35,
                    ),
                    children: [
                      const TextSpan(text: 'Chưa cào dữ liệu '),
                      if (isSingleDay) ...[
                        const TextSpan(text: 'kỳ quay ngày '),
                        TextSpan(
                          text: fromDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ] else ...[
                        const TextSpan(text: 'từ ngày '),
                        TextSpan(
                          text: fromDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const TextSpan(text: ' đến ngày '),
                        TextSpan(
                          text: toDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: isSyncing ? null : onSyncNow,
                icon: isSyncing
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync_rounded, size: 15),
                label: Text(isSyncing ? 'Đang cào...' : 'Cào bù ngay'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD), // Bootstrap Primary Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
