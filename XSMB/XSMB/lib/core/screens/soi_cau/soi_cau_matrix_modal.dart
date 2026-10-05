import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class SoiCauMatrixModal extends StatefulWidget {
  final SoiCauResult result;
  final Function(String pos) onSelectBridge;

  const SoiCauMatrixModal({
    super.key,
    required this.result,
    required this.onSelectBridge,
  });

  @override
  State<SoiCauMatrixModal> createState() => _SoiCauMatrixModalState();
}

class _SoiCauMatrixModalState extends State<SoiCauMatrixModal> {
  int? _selectedVt;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final digits = widget.result.matrixDigits;
    final connections = widget.result.matrixConnections;
    final connectedSet =
        _selectedVt != null ? (connections[_selectedVt] ?? []).toSet() : <int>{};

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF212529) : Colors.white,
      insetPadding: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.grid_4x4_rounded,
                      color: AppTheme.accentGold, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'BẢNG VỊ TRÍ CẦU (107 VỊ TRÍ)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Hướng dẫn tương tác
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: isDark ? Colors.white10 : const Color(0xFFFFF3CD),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFF664D03)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedVt == null
                          ? 'Bấm vào một vị trí có cầu, sẽ biết các vị trí tạo cầu (màu đỏ).'
                          : 'Bấm vào số MÀU ĐỎ để xem chi tiết đường chạy cầu.',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF664D03)),
                    ),
                  ),
                  if (_selectedVt != null)
                    InkWell(
                      onTap: () => setState(() => _selectedVt = null),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Bỏ chọn',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),

            // Ma trận 107 số theo các giải XSMB
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildPrizeRow(
                      'ĐB', 0, 5, digits, connections, connectedSet, isDark),
                  _buildPrizeRow(
                      'Nhất', 5, 5, digits, connections, connectedSet, isDark),
                  _buildPrizeRow(
                      'Nhì', 10, 10, digits, connections, connectedSet, isDark,
                      subGroups: 2),
                  _buildPrizeRow(
                      'Ba', 20, 30, digits, connections, connectedSet, isDark,
                      subGroups: 6),
                  _buildPrizeRow(
                      'Tư', 50, 16, digits, connections, connectedSet, isDark,
                      subGroups: 4),
                  _buildPrizeRow(
                      'Năm', 66, 24, digits, connections, connectedSet, isDark,
                      subGroups: 6),
                  _buildPrizeRow(
                      'Sáu', 90, 9, digits, connections, connectedSet, isDark,
                      subGroups: 3),
                  _buildPrizeRow(
                      'Bảy', 99, 8, digits, connections, connectedSet, isDark,
                      subGroups: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeRow(
    String label,
    int startIdx,
    int count,
    List<String> digits,
    Map<int, List<int>> connections,
    Set<int> connectedSet,
    bool isDark, {
    int subGroups = 1,
  }) {
    final groupSize = count ~/ subGroups;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFDEE2E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryRed),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 6,
              children: List.generate(subGroups, (g) {
                final subStart = startIdx + g * groupSize;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(groupSize, (i) {
                    final vt = subStart + i;
                    final char = vt < digits.length && digits[vt].isNotEmpty
                        ? digits[vt]
                        : '-';
                    final hasBridge = connections.containsKey(vt);
                    final isSelected = _selectedVt == vt;
                    final isConnected = connectedSet.contains(vt);

                    Color bg = Colors.transparent;
                    Color textCol = isDark ? Colors.white70 : Colors.black87;
                    Border? border;

                    if (isSelected) {
                      bg = const Color(0xFFC4E1FF);
                      textCol = const Color(0xFF003DDD);
                      border =
                          Border.all(color: const Color(0xFF003DDD), width: 1.5);
                    } else if (isConnected) {
                      bg = const Color(0xFFFFECA8);
                      textCol = const Color(0xFFFF0600);
                      border =
                          Border.all(color: const Color(0xFFFF0600), width: 1.5);
                    } else if (hasBridge) {
                      bg = isDark ? Colors.white12 : const Color(0xFFE9ECEF);
                      textCol = isDark ? Colors.white : const Color(0xFF363636);
                      border =
                          Border.all(color: Colors.grey.shade400, width: 1);
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: InkWell(
                        onTap: () {
                          if (isSelected) {
                            setState(() => _selectedVt = null);
                          } else if (isConnected && _selectedVt != null) {
                            final vt1 = min(_selectedVt!, vt);
                            final vt2 = max(_selectedVt!, vt);
                            widget.onSelectBridge('${vt1}x$vt2');
                          } else if (hasBridge) {
                            setState(() => _selectedVt = vt);
                          }
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 25,
                          height: 28,
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(4),
                            border: border,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            char,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: hasBridge || isConnected || isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: textCol,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
