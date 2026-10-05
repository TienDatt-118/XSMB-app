import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/lottery_provider.dart';
import '../../theme/app_theme.dart';

class SoiCauDetailSheet extends StatelessWidget {
  final String position;

  const SoiCauDetailSheet({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final detail = provider.currentCauDetail;
    final isLoading = provider.isLoadingCauDetail;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF212529) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Modal Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'VỊ TRÍ $position',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chi tiết đường chạy cầu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryRed),
                  )
                : detail == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_off_rounded,
                                size: 44,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Chưa tải được chi tiết vị trí cầu',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Vui lòng kiểm tra lại kết nối mạng hoặc thử lại.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (detail.predictedNumbers.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.success
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.tips_and_updates,
                                      color: AppTheme.success, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        children: [
                                          const TextSpan(
                                              text: 'Dự đoán hôm nay nổ cặp: '),
                                          TextSpan(
                                            text: detail.predictedNumbers
                                                .join(', '),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppTheme.primaryRed,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),

                          Text(
                            'LỊCH SỬ KỲ QUAY ĐÃ NỔ CẦU (${detail.historyDays.length} NGÀY)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),

                          ...detail.historyDays.map(
                            (day) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.darkSurface
                                    : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white12
                                      : const Color(0xFFDEE2E6),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.event,
                                          size: 15, color: AppTheme.accentGold),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          day.drawDate,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                        ),
                                      ),
                                      if (day.hitNumbers.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryRed,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Ăn: ${day.hitNumbers.join(', ')}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(
                                      height: 1, color: Colors.black12),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Ghép: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black54,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentGold
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${day.char1} & ${day.char2}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppTheme.accentGold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Báo: ${day.predictedPair}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.primaryRed),
                                      ),
                                    ],
                                  ),
                                  if (day.prizeStructure.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.black26
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: isDark
                                                ? Colors.white10
                                                : Colors.grey.shade300),
                                      ),
                                      child: Column(
                                        children: day.prizeStructure.entries
                                            .map((entry) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 2),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 36,
                                                  child: Text(
                                                    entry.key,
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.grey),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Wrap(
                                                    spacing: 8,
                                                    children: entry.value
                                                        .map((numStr) {
                                                      final endsWithHit = day
                                                          .hitNumbers
                                                          .any((h) => numStr
                                                              .endsWith(h));
                                                      return Container(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                                horizontal:
                                                                    endsWithHit
                                                                        ? 4
                                                                        : 0),
                                                        decoration: endsWithHit
                                                            ? BoxDecoration(
                                                                color: const Color(
                                                                    0xFFFED683),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            3),
                                                              )
                                                            : null,
                                                        child: Text(
                                                          numStr,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                endsWithHit
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .w600,
                                                            color: endsWithHit
                                                                ? const Color(
                                                                    0xFFB02A37)
                                                                : (isDark
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black87),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
