import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/lottery_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import 'soi_cau/soi_cau_matrix_modal.dart';
import 'soi_cau/soi_cau_detail_sheet.dart';
import 'soi_cau/soi_cau_pairs_table.dart';

class SoiCauScreen extends StatefulWidget {
  const SoiCauScreen({super.key});

  @override
  State<SoiCauScreen> createState() => _SoiCauScreenState();
}

class _SoiCauScreenState extends State<SoiCauScreen> {
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedDate = TimeUtils.nowVN;
  int _selectedLimit = 5;
  int _selectedExactLimit = 0; // 0: Bằng hoặc hơn (>=), 1: Chính xác bằng (==)
  int _selectedNhay = 1; // 1 to 5
  bool _selectedIsDb = false;
  bool _selectedIsLon = true; // true: Lộn, false: Không lộn (bạch thủ)

  // Modes: 'full' (Soi cầu toàn diện), 'num' (Tìm cầu cho cặp số)
  String _mode = 'full';
  // Result view mode: 0 = Tổng hợp & Thống kê lặp, 1 = Chi tiết tất cả vị trí cầu
  int _resultViewTab = 0;

  // Selected bridge for inline detail view (like RongBachKim's showcauarea)
  String? _activeInlineBridge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSoiCau();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadSoiCau() {
    final search = _mode == 'num' && _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    setState(() {
      _activeInlineBridge = null;
    });

    context.read<LotteryProvider>().fetchSoiCau(
          date: _selectedDate,
          limit: _selectedLimit,
          exactLimit: _selectedExactLimit,
          nhay: _selectedNhay,
          isDb: _selectedIsDb,
          isLon: _selectedIsLon,
          searchNum: search,
        );
  }

  void _onSearchSubmit() {
    FocusScope.of(context).unfocus();
    _loadSoiCau();
  }

  void _onClearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
    _loadSoiCau();
  }

  void _copyAllPairs(List<CauItem> list) {
    if (list.isEmpty) return;
    final allNumbers = list.map((e) => e.pair).join(', ');
    Clipboard.setData(ClipboardData(text: allNumbers));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Đã sao chép dàn ${list.length} cặp số soi cầu!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showBridgeDetail(String position, {bool openModal = false}) {
    setState(() {
      _activeInlineBridge = position;
    });

    final provider = context.read<LotteryProvider>();
    provider.fetchCauDetail(position, date: _selectedDate);

    if (openModal) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SoiCauDetailSheet(position: position),
      );
    }
  }

  void _openMatrixDialog(BuildContext context, SoiCauResult result) {
    showDialog(
      context: context,
      builder: (ctx) => SoiCauMatrixModal(
        result: result,
        onSelectBridge: (pos) {
          Navigator.pop(ctx);
          _showBridgeDetail(pos, openModal: true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = provider.soiCauResult;
    final isLoading = provider.isLoadingSoiCau;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOI CẦU',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryRed,
        actions: [
          IconButton(
            tooltip: 'Chọn ngày soi cầu',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2005),
                lastDate: TimeUtils.nowVN.add(const Duration(days: 1)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _loadSoiCau();
              }
            },
          ),
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: _loadSoiCau,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadSoiCau(),
        color: AppTheme.primaryRed,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // 1. Chuyển đổi chế độ (Tabs: Soi cầu toàn diện / Tìm cầu cho cặp số)
            _buildModeTabs(isDark),
            const SizedBox(height: 10),

            // 2. Ô tìm kiếm cặp số (khi ở chế độ Tìm cầu cho cặp số)
            if (_mode == 'num') ...[
              _buildSearchBar(isDark),
              const SizedBox(height: 10),
            ],

            // 3. Khối tùy chọn soi cầu đầy đủ theo chuẩn web RongBachKim
            _buildOptionsPanel(isDark),
            const SizedBox(height: 12),

            // 4. Thanh chọn nhanh số ngày cầu chạy (1..9 ngày)
            _buildQuickDaysBar(isDark),
            const SizedBox(height: 12),

            // 5. Nút mở Bảng vị trí cầu (Ma trận 107 vị trí) & Soi cầu ngay
            if (result != null) ...[
              _buildActionRow(isDark, result),
              const SizedBox(height: 12),
            ],

            // 6. Khu vực hiển thị chi tiết cầu đã chọn (Inline ShowCauArea như web)
            if (_activeInlineBridge != null) ...[
              _buildInlineBridgeDetail(isDark, provider),
              const SizedBox(height: 14),
            ],

            // 7. Loading State
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryRed),
                      SizedBox(height: 12),
                      Text(
                        'Đang quét các vị trí cầu chạy trên ma trận 107 số...',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else if (result == null || result.cauList.isEmpty)
              _buildEmptyState(isDark)
            else ...[
              // 8. Thống kê tóm tắt & Cầu vàng hôm nay
              _buildSummaryHeader(isDark, result),
              const SizedBox(height: 12),

              // 9. Lưới huy hiệu các con số có cầu (Badges a_cau như web)
              _buildBridgeChipsSection(isDark, result),
              const SizedBox(height: 14),

              // 10. Tabs chuyển đổi xem: Thống kê cầu lặp vs Tất cả vị trí cầu
              _buildResultViewTabs(isDark, result),
              const SizedBox(height: 12),

              // 11. Nội dung danh sách theo Tab
              if (_resultViewTab == 0) ...[
                // Bảng thống kê cầu lặp (Cặp số & Số cầu)
                SoiCauPairsTable(
                  list: result.cauList,
                  result: result,
                  activeInlineBridge: _activeInlineBridge,
                  onSelectBridge: (pos, {openModal = false}) =>
                      _showBridgeDetail(pos, openModal: openModal),
                  onCopyAllPairs: _copyAllPairs,
                ),
              ] else ...[
                // Danh sách tất cả vị trí tạo cầu
                _buildAllPositionsGrid(isDark, result.allPositions),
              ],
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- CÁC THÀNH PHẦN GIAO DIỆN CHUẨN WEB RỒNG BẠCH KIM ---

  Widget _buildModeTabs(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTabItem(
              title: 'Soi Cầu Toàn Diện',
              icon: Icons.all_inclusive_rounded,
              isSelected: _mode == 'full',
              isDark: isDark,
              onTap: () {
                if (_mode != 'full') {
                  setState(() => _mode = 'full');
                  _loadSoiCau();
                }
              },
            ),
          ),
          Expanded(
            child: _buildModeTabItem(
              title: 'Tìm Cầu Cho Cặp Số',
              icon: Icons.filter_2_rounded,
              isSelected: _mode == 'num',
              isDark: isDark,
              onTap: () {
                if (_mode != 'num') {
                  setState(() => _mode = 'num');
                  _loadSoiCau();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryRed.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.grey[800]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.accentGold, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.text,
              maxLength: 10,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: const InputDecoration(
                hintText: 'Nhập cặp số cần tìm cầu (VD: 23,32 hoặc 23)...',
                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey),
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _onSearchSubmit(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              onPressed: _onClearSearch,
            ),
          ElevatedButton(
            onPressed: _onSearchSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            child: const Text('Tìm Cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsPanel(bool isDark) {
    final borderColor = isDark ? Colors.white12 : const Color(0xFFDEE2E6);
    final cardBg = isDark ? AppTheme.darkSurface : Colors.white;
    final dateDisplayStr =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dòng 1: Độ dài cầu (Bằng hoặc hơn / Chính xác bằng) + Counter số ngày
          Row(
            children: [
              const Text(
                'Độ dài của cầu: ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedExactLimit,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                      items: const [
                        DropdownMenuItem(
                          value: 0,
                          child: Text('Bằng hoặc hơn (>=)', overflow: TextOverflow.ellipsis),
                        ),
                        DropdownMenuItem(
                          value: 1,
                          child: Text('Chính xác bằng (==)', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null && val != _selectedExactLimit) {
                          setState(() => _selectedExactLimit = val);
                          _loadSoiCau();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Counter tăng giảm số ngày
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: _selectedLimit > 1
                          ? () {
                              setState(() => _selectedLimit--);
                              _loadSoiCau();
                            }
                          : null,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                      child: Container(
                        width: 28,
                        height: 36,
                        alignment: Alignment.center,
                        child: const Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      child: Text(
                        '$_selectedLimit ngày',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryRed),
                      ),
                    ),
                    InkWell(
                      onTap: _selectedLimit < 20
                          ? () {
                              setState(() => _selectedLimit++);
                              _loadSoiCau();
                            }
                          : null,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                      child: Container(
                        width: 28,
                        height: 36,
                        alignment: Alignment.center,
                        child: const Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Dòng 2: Tùy chọn Ngày + Nháy + Giải ĐB + Lộn
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Chọn ngày soi cầu
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2005),
                    lastDate: TimeUtils.nowVN.add(const Duration(days: 1)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    _loadSoiCau();
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFFFF9E6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event, size: 15, color: AppTheme.accentGold),
                      const SizedBox(width: 4),
                      Text(
                        'Ngày $dateDisplayStr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down, size: 16),
                    ],
                  ),
                ),
              ),

              // Chọn số nháy (1..5)
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedNhay,
                    dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: [1, 2, 3, 4, 5].map((n) {
                      return DropdownMenuItem(
                        value: n,
                        child: Text('$n nháy'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedNhay = val;
                          if (val > 1) _selectedIsDb = false;
                        });
                        _loadSoiCau();
                      }
                    },
                  ),
                ),
              ),

              // Checkbox Giải đặc biệt
              InkWell(
                onTap: () {
                  setState(() {
                    _selectedIsDb = !_selectedIsDb;
                    if (_selectedIsDb) _selectedNhay = 1;
                  });
                  _loadSoiCau();
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: _selectedIsDb
                        ? AppTheme.primaryRed.withValues(alpha: 0.15)
                        : (isDark ? Colors.white10 : const Color(0xFFF8F9FA)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _selectedIsDb ? AppTheme.primaryRed : borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedIsDb ? Icons.check_box : Icons.check_box_outline_blank,
                        size: 16,
                        color: _selectedIsDb ? AppTheme.primaryRed : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Giải đặc biệt',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedIsDb ? FontWeight.bold : FontWeight.normal,
                          color: _selectedIsDb ? AppTheme.primaryRed : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Toggle Cầu Lộn / Không lộn
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () {
                      if (!_selectedIsLon) {
                        setState(() => _selectedIsLon = true);
                        _loadSoiCau();
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: _selectedIsLon
                            ? const Color(0xFF0D6EFD)
                            : (isDark ? Colors.white10 : const Color(0xFFF8F9FA)),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                        border: Border.all(color: _selectedIsLon ? const Color(0xFF0D6EFD) : borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Lộn',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedIsLon ? FontWeight.bold : FontWeight.normal,
                          color: _selectedIsLon ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (_selectedIsLon) {
                        setState(() => _selectedIsLon = false);
                        _loadSoiCau();
                      }
                    },
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: !_selectedIsLon
                            ? const Color(0xFF0D6EFD)
                            : (isDark ? Colors.white10 : const Color(0xFFF8F9FA)),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                        border: Border.all(color: !_selectedIsLon ? const Color(0xFF0D6EFD) : borderColor),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Không lộn',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: !_selectedIsLon ? FontWeight.bold : FontWeight.normal,
                          color: !_selectedIsLon ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDaysBar(bool isDark) {
    final days = [1, 2, 3, 4, 5, 6, 7, 8, 9];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.bolt_rounded, size: 16, color: AppTheme.accentGold),
            SizedBox(width: 4),
            Text(
              'Số ngày cầu chạy:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((day) {
            final isSelected = _selectedLimit == day;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () {
                    if (_selectedLimit != day) {
                      setState(() => _selectedLimit = day);
                      _loadSoiCau();
                    }
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryRed
                          : (isDark ? AppTheme.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryRed
                            : (isDark ? Colors.white12 : const Color(0xFFDEE2E6)),
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryRed.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionRow(bool isDark, SoiCauResult result) {
    return Row(
      children: [
        // Nút mở Bảng Vị Trí Cầu (Ma Trận 107 Vị Trí)
        Expanded(
          flex: 6,
          child: ElevatedButton.icon(
            onPressed: () => _openMatrixDialog(context, result),
            icon: const Icon(Icons.grid_on_rounded, size: 16),
            label: const Text(
              'Bảng Vị Trí Cầu (107 VT)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF383D43) : const Color(0xFF4A5568),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Nút Soi Cầu Ngay
        Expanded(
          flex: 4,
          child: ElevatedButton.icon(
            onPressed: _loadSoiCau,
            icon: const Icon(Icons.search, size: 16),
            label: const Text(
              'Soi Cầu Ngay',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(bool isDark, SoiCauResult result) {
    final compText = result.exactLimit == 1 ? 'chính xác =' : '>=';
    final lonText = result.isLon ? 'có lộn' : 'không lộn';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2D3D) : const Color(0xFFE8F4FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.blue.shade800 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded, size: 18, color: Color(0xFF0D6EFD)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'KẾT QUẢ SOI CẦU NGÀY ${result.targetDate}',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.blue.shade200 : const Color(0xFF084298),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (result.isFromWeb ? AppTheme.success : AppTheme.warning)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  result.isFromWeb ? 'Live RBK' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: result.isFromWeb ? AppTheme.success : AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
              children: [
                const TextSpan(text: 'Tìm được '),
                TextSpan(
                  text: '${result.totalBridges} cầu ',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryRed),
                ),
                TextSpan(text: 'có độ dài $compText ${result.limitDays} ngày ($lonText):'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• Trong đó có ${result.bridgesOverLimit} cầu dài trên ${result.limitDays} ngày (đánh dấu đậm).\n'
            '• Cầu xuất hiện tại ${result.distinctPairsCount} cặp số khác nhau, trong đó có ${result.pairsOverLimitCount} cặp số có cầu chạy hơn ${result.limitDays} ngày.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF495057),
            ),
          ),
          if (result.topGoldPair != null && _mode == 'full') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF321E36) : const Color(0xFFFDF0F8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC20171).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        children: [
                          const TextSpan(text: 'Cặp số có nhiều cầu nhất là: '),
                          TextSpan(
                            text: result.topGoldPair,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
          ],
        ],
      ),
    );
  }

  // Lưới các con số có cầu (Badges giống hệt web RongBachKim)
  Widget _buildBridgeChipsSection(bool isDark, SoiCauResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDEE2E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.accentGold),
              const SizedBox(width: 6),
              const Text(
                'DANH SÁCH CẦU (BẤM ĐỂ XEM ĐƯỜNG CHẠY)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
              ),
              const Spacer(),
              Text(
                '${result.allPositions.length} cầu',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: result.allPositions.map((pos) {
              final isMore = pos.isMore;
              final isSelected = _activeInlineBridge == pos.position;

              return InkWell(
                onTap: () => _showBridgeDetail(pos.position),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFCD5CF)
                        : (isMore
                            ? (isDark ? const Color(0xFF2C4A7A) : const Color(0xFF8AA5FF))
                            : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFC4D9FB))),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFDD5800)
                          : (isMore ? const Color(0xFF003DDD) : const Color(0xFF76A6F5)),
                      width: isSelected || isMore ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    pos.number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFFDD5800)
                          : (isMore
                              ? (isDark ? Colors.white : const Color(0xFF001F60))
                              : (isDark ? Colors.white : const Color(0xFF254694))),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Khối hiển thị chi tiết đường chạy cầu khi chọn 1 cầu
  Widget _buildInlineBridgeDetail(bool isDark, LotteryProvider provider) {
    final detail = provider.currentCauDetail;
    final isLoading = provider.isLoadingCauDetail;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B303A) : const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentGold.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VỊ TRÍ ${_activeInlineBridge!}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Chi tiết đường chạy cầu',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _activeInlineBridge = null),
              ),
            ],
          ),
          const Divider(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryRed)),
            )
          else if (detail == null)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: Text('Đang tải đường chạy cầu...', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            )
          else ...[
            if (detail.predictedNumbers.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          children: [
                            const TextSpan(text: 'Dự đoán kết quả sẽ về: '),
                            TextSpan(
                              text: detail.predictedNumbers.join(' - '),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
            const SizedBox(height: 10),
            Text(
              'Lịch sử cầu thông qua các kỳ quay (${detail.historyDays.length} ngày):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            ...detail.historyDays.map((day) => _buildHistoryDayCard(isDark, day)),
          ],
        ],
      ),
    );
  }

  Widget _buildResultViewTabs(bool isDark, SoiCauResult result) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : const Color(0xFFE9ECEF),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _resultViewTab = 0),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _resultViewTab == 0 ? AppTheme.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Thống Kê Cầu Lặp (${result.cauList.length} cặp)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _resultViewTab == 0 ? FontWeight.bold : FontWeight.w600,
                    color: _resultViewTab == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.grey[800]),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _resultViewTab = 1),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _resultViewTab == 1 ? AppTheme.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Tất Cả Vị Trí (${result.allPositions.length} cầu)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: _resultViewTab == 1 ? FontWeight.bold : FontWeight.w600,
                    color: _resultViewTab == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.grey[800]),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllPositionsGrid(bool isDark, List<BridgePosition> positions) {
    if (positions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Không có vị trí cầu nào', style: TextStyle(color: Colors.grey[500])),
        ),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = (constraints.maxWidth - 24) / 4; // 4 columns
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: positions.map((pos) {
          final isMore = pos.isMore;
          return InkWell(
            onTap: () => _showBridgeDetail(pos.position),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isMore
                    ? (isDark ? const Color(0xFF1E2D3D) : const Color(0xFFC4D9FB))
                    : (isDark ? AppTheme.darkSurface : const Color(0xFFF8F9FA)),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isMore
                      ? (isDark ? Colors.blue.shade700 : const Color(0xFF76A6F5))
                      : (isDark ? Colors.white12 : const Color(0xFFDEE2E6)),
                  width: isMore ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pos.number,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isMore
                          ? (isDark ? Colors.blue.shade300 : const Color(0xFF003DDD))
                          : AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pos.position,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.search_off, size: 50, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Không tìm thấy đường cầu cho số ${_searchController.text}'
                  : 'Không có dữ liệu cầu cho thiết lập này',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Thử giảm biên độ ngày hoặc chọn chế độ có lộn để quét nhiều cầu hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryDayCard(bool isDark, CauHistoryDay day) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFDEE2E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppTheme.accentGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  day.drawDate,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              if (day.hitNumbers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Ăn: ${day.hitNumbers.join(', ')}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Ghép: ',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black54),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D6EFD).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${day.char1} & ${day.char2}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF0D6EFD),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Báo: ${day.predictedPair}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryRed),
              ),
            ],
          ),
          if (day.prizeStructure.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade300),
              ),
              child: Column(
                children: day.prizeStructure.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 32,
                          child: Text(
                            entry.key,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: entry.value.map((numStr) {
                              final endsWithHit = day.hitNumbers.any((h) => numStr.endsWith(h));
                              return Container(
                                padding: EdgeInsets.symmetric(horizontal: endsWithHit ? 3 : 0),
                                decoration: endsWithHit
                                    ? BoxDecoration(
                                        color: const Color(0xFFFED683),
                                        borderRadius: BorderRadius.circular(3),
                                      )
                                    : null,
                                child: Text(
                                  numStr,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: endsWithHit ? FontWeight.bold : FontWeight.w500,
                                    color: endsWithHit ? const Color(0xFFB02A37) : (isDark ? Colors.white : Colors.black87),
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
    );
  }
}

