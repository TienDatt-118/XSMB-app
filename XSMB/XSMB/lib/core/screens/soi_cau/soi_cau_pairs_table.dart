import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class SoiCauPairsTable extends StatefulWidget {
  final List<CauItem> list;
  final SoiCauResult result;
  final String? activeInlineBridge;
  final Function(String position, {bool openModal}) onSelectBridge;
  final Function(List<CauItem> list) onCopyAllPairs;

  const SoiCauPairsTable({
    super.key,
    required this.list,
    required this.result,
    this.activeInlineBridge,
    required this.onSelectBridge,
    required this.onCopyAllPairs,
  });

  @override
  State<SoiCauPairsTable> createState() => _SoiCauPairsTableState();
}

class _SoiCauPairsTableState extends State<SoiCauPairsTable> {
  int _tableLayoutType = 0; // 0: Bảng 2 cột song song chuẩn Web, 1: Danh sách chi tiết
  int _tableFilterMode = 0; // 0: Tất cả, 1: Cầu VIP (>=3), 2: 2 cầu, 3: 1 cầu
  final TextEditingController _tableSearchController = TextEditingController();
  String _tableSearchQuery = '';

  @override
  void dispose() {
    _tableSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = widget.list;
    final result = widget.result;

    // 1. Phân loại số lượng
    final vipList = list.where((e) => e.count >= 3).toList();
    final count2List = list.where((e) => e.count == 2).toList();
    final count1List = list.where((e) => e.count == 1).toList();

    // 2. Lọc theo tìm kiếm và tab bộ lọc
    final filteredList = list.where((item) {
      if (_tableSearchQuery.isNotEmpty) {
        if (!item.pair.contains(_tableSearchQuery)) return false;
      }
      if (_tableFilterMode == 1) return item.count >= 3;
      if (_tableFilterMode == 2) return item.count == 2;
      if (_tableFilterMode == 3) return item.count == 1;
      return true;
    }).toList();

    final borderColor = isDark ? Colors.white12 : const Color(0xFFDEE2E6);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // A. HEADER BẢNG: Tiêu đề, số lượng, chuyển đổi giao diện & Sao chép
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.table_chart_rounded,
                      size: 18, color: AppTheme.primaryRed),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'THỐNG KÊ CẦU LẶP',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            letterSpacing: 0.3),
                      ),
                      Text(
                        '${list.length} cặp số • ${result.totalBridges} lượt ghép cầu',
                        style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Nút chuyển đổi kiểu bảng: 2 cột song song (chuẩn web gọn) vs Danh sách chi tiết
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTableLayoutToggleBtn(
                        icon: Icons.view_week_rounded,
                        tooltip: 'Bảng song song (Chuẩn web)',
                        isSelected: _tableLayoutType == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _tableLayoutType = 0),
                      ),
                      _buildTableLayoutToggleBtn(
                        icon: Icons.view_agenda_rounded,
                        tooltip: 'Danh sách chi tiết',
                        isSelected: _tableLayoutType == 1,
                        isDark: isDark,
                        onTap: () => setState(() => _tableLayoutType = 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Nút sao chép dàn
                TextButton.icon(
                  onPressed: () => widget.onCopyAllPairs(
                      filteredList.isNotEmpty ? filteredList : list),
                  icon: const Icon(Icons.copy_rounded,
                      size: 14, color: AppTheme.accentGold),
                  label: const Text(
                    'Sao chép',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentGold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        AppTheme.accentGold.withValues(alpha: 0.12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          // B. THANH TÌM KIẾM CẶP SỐ NHANH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _tableSearchController,
                onChanged: (val) =>
                    setState(() => _tableSearchQuery = val.trim()),
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Tìm nhanh cặp số trong bảng (vd: 23, 68...)',
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey[500]),
                  prefixIcon:
                      const Icon(Icons.search, size: 18, color: Colors.grey),
                  suffixIcon: _tableSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 16, color: Colors.grey),
                          onPressed: () {
                            _tableSearchController.clear();
                            setState(() => _tableSearchQuery = '');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF20242B)
                      : const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryRed, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // C. BỘ LỌC NHANH (TẤT CẢ / VIP / 2 CẦU / 1 CẦU)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _buildTableFilterChip(
                  label: 'Tất cả (${list.length})',
                  isSelected: _tableFilterMode == 0,
                  isDark: isDark,
                  onTap: () => setState(() => _tableFilterMode = 0),
                ),
                const SizedBox(width: 6),
                _buildTableFilterChip(
                  label: '🔥 Cầu VIP ≥3 (${vipList.length})',
                  isSelected: _tableFilterMode == 1,
                  isDark: isDark,
                  onTap: () => setState(() => _tableFilterMode = 1),
                  badgeColor: AppTheme.primaryRed,
                ),
                const SizedBox(width: 6),
                _buildTableFilterChip(
                  label: '2 cầu (${count2List.length})',
                  isSelected: _tableFilterMode == 2,
                  isDark: isDark,
                  onTap: () => setState(() => _tableFilterMode = 2),
                ),
                const SizedBox(width: 6),
                _buildTableFilterChip(
                  label: '1 cầu (${count1List.length})',
                  isSelected: _tableFilterMode == 3,
                  isDark: isDark,
                  onTap: () => setState(() => _tableFilterMode = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),

          // D. NỘI DUNG BẢNG THỐNG KÊ
          if (filteredList.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.filter_list_off_rounded,
                        size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'Không có cặp số nào khớp với bộ lọc',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () {
                        _tableSearchController.clear();
                        setState(() {
                          _tableFilterMode = 0;
                          _tableSearchQuery = '';
                        });
                      },
                      child: const Text('Đặt lại bộ lọc',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
          else if (_tableLayoutType == 0)
            // 1. Chế độ Bảng 2 cột song song (Chuẩn Web RongBachKim .tbl1)
            _buildTableDualColumns(isDark, filteredList)
          else
            // 2. Chế độ Danh sách chi tiết
            _buildTableDetailedList(isDark, filteredList),

          // E. FOOTER HƯỚNG DẪN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1E24) : const Color(0xFFF8F9FA),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded,
                    size: 14, color: AppTheme.accentGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Chạm vào cặp số để xem chi tiết đường chạy cầu trên 27 giải.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : const Color(0xFF6C757D),
                    ),
                  ),
                ),
                Text(
                  '${filteredList.length} cặp',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Chế độ Bảng 2 cột song song (Chuẩn web RongBachKim)
  Widget _buildTableDualColumns(bool isDark, List<CauItem> list) {
    final half = (list.length + 1) ~/ 2;
    final leftList = list.sublist(0, half);
    final rightList = list.sublist(half);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFDEE2E6);

    return Column(
      children: [
        // Header dòng tiêu đề 2 bên
        Container(
          height: 32,
          color: isDark ? const Color(0xFF252A34) : const Color(0xFFE9ECEF),
          child: Row(
            children: [
              // Cột trái
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Text(
                        'CẶP SỐ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF495057)),
                      ),
                      const Spacer(),
                      Text(
                        'SỐ CẦU',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF495057)),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 32, color: borderColor),
              // Cột phải
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Text(
                        'CẶP SỐ',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF495057)),
                      ),
                      const Spacer(),
                      Text(
                        'SỐ CẦU',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF495057)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Danh sách dữ liệu với kẻ sọc Zebra
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: half,
          separatorBuilder: (_, __) => Divider(
              height: 1,
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          itemBuilder: (context, index) {
            final leftItem = leftList[index];
            final rightItem =
                index < rightList.length ? rightList[index] : null;
            final isEven = index % 2 == 0;
            final rowBg = isEven
                ? (isDark ? AppTheme.darkSurface : Colors.white)
                : (isDark ? const Color(0xFF1E232B) : const Color(0xFFF8FAFC));

            return Container(
              color: rowBg,
              child: Row(
                children: [
                  // Ô bên trái
                  Expanded(
                    child: _buildTableDualCell(isDark, leftItem),
                  ),
                  Container(width: 1, height: 38, color: borderColor),
                  // Ô bên phải
                  Expanded(
                    child: rightItem != null
                        ? _buildTableDualCell(isDark, rightItem)
                        : const SizedBox(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Từng ô trong bảng 2 cột song song
  Widget _buildTableDualCell(bool isDark, CauItem item) {
    final isSelected = widget.activeInlineBridge != null &&
        item.positions.contains(widget.activeInlineBridge);
    final isTop = item.count >= 5;
    final isHot = item.count >= 3 && item.count < 5;

    return InkWell(
      onTap: item.positions.isNotEmpty
          ? () => widget.onSelectBridge(item.positions.first)
          : null,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.15),
                border: Border.all(color: AppTheme.accentGold, width: 1),
              )
            : null,
        child: Row(
          children: [
            // Cặp số
            if (isTop) ...[
              const Text('👑', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
            ] else if (isHot) ...[
              const Text('🔥', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 3),
            ],
            Text(
              item.pair,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: isTop
                    ? AppTheme.primaryRed
                    : (isHot
                        ? const Color(0xFFE65100)
                        : (isDark ? Colors.white : const Color(0xFF254694))),
              ),
            ),
            const Spacer(),
            // Badge Số cầu
            _buildBridgeCountBadge(isDark, item.count),
          ],
        ),
      ),
    );
  }

  // 2. Chế độ Danh sách chi tiết (1 cột)
  Widget _buildTableDetailedList(bool isDark, List<CauItem> list) {
    final borderColor = isDark ? Colors.white12 : const Color(0xFFDEE2E6);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
      itemBuilder: (context, index) {
        final item = list[index];
        final isSelected = widget.activeInlineBridge != null &&
            item.positions.contains(widget.activeInlineBridge);
        final isTop = item.count >= 5;
        final isHot = item.count >= 3 && item.count < 5;

        return InkWell(
          onTap: item.positions.isNotEmpty
              ? () => widget.onSelectBridge(item.positions.first)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: isSelected
                ? AppTheme.accentGold.withValues(alpha: 0.12)
                : (index % 2 == 1
                    ? (isDark
                        ? const Color(0xFF1E232B)
                        : const Color(0xFFF8FAFC))
                    : Colors.transparent),
            child: Row(
              children: [
                // Badge Cặp Số
                Container(
                  constraints: const BoxConstraints(minWidth: 54),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isTop
                        ? AppTheme.primaryRed
                        : (isHot
                            ? const Color(0xFFE65100)
                            : (isDark
                                ? Colors.white12
                                : const Color(0xFFE9ECEF))),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isTop
                          ? AppTheme.primaryRed
                          : (isHot
                              ? const Color(0xFFE65100)
                              : Colors.transparent),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.pair,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isTop || isHot
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF254694)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Thông tin vị trí cầu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${item.count} vị trí ghép cầu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isTop
                                  ? AppTheme.primaryRed
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          if (isTop) ...[
                            const SizedBox(width: 6),
                            const Text('👑 Cầu VIP',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentGold)),
                          ],
                        ],
                      ),
                      if (item.positions.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Vị trí: ${item.positions.take(4).join(', ')}${item.positions.length > 4 ? '...' : ''}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.grey[400]
                                : const Color(0xFF6C757D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                _buildBridgeCountBadge(isDark, item.count),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  // Huy hiệu hiển thị số lượng cầu (Pill badge theo cấp độ màu)
  Widget _buildBridgeCountBadge(bool isDark, int count) {
    Color bg;
    Color textColor;
    FontWeight fw = FontWeight.bold;

    if (count >= 5) {
      bg = AppTheme.primaryRed;
      textColor = Colors.white;
    } else if (count >= 3) {
      bg = const Color(0xFFE65100);
      textColor = Colors.white;
    } else if (count == 2) {
      bg = isDark ? const Color(0xFF16325C) : const Color(0xFFDCEAFE);
      textColor = isDark ? const Color(0xFF93C5FD) : const Color(0xFF0D6EFD);
    } else {
      bg = isDark ? Colors.white10 : const Color(0xFFF1F5F9);
      textColor = isDark ? Colors.grey[400]! : const Color(0xFF64748B);
      fw = FontWeight.w600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count cầu',
        style: TextStyle(
          fontSize: 11,
          fontWeight: fw,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildTableFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (badgeColor ?? AppTheme.primaryRed)
              : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? (badgeColor ?? AppTheme.primaryRed)
                : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildTableLayoutToggleBtn({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
