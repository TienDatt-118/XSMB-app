import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/lottery_provider.dart';
import '../widgets/rolling_number.dart';
import '../widgets/glass_card.dart';
import '../theme/app_theme.dart';
import '../constants/app_constants.dart';

class LiveDrawScreen extends StatefulWidget {
  const LiveDrawScreen({super.key});

  @override
  State<LiveDrawScreen> createState() => _LiveDrawScreenState();
}

class _LiveDrawScreenState extends State<LiveDrawScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _prizeKeys = {
    'db': GlobalKey(),
    'g1': GlobalKey(),
    'g2': GlobalKey(),
    'g3': GlobalKey(),
    'g4': GlobalKey(),
    'g5': GlobalKey(),
    'g6': GlobalKey(),
    'g7': GlobalKey(),
  };

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPrize(String prizeCode) {
    final key = _prizeKeys[prizeCode];
    if (key == null || key.currentContext == null) return;

    // Auto scroll to active drawing prize row
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LotteryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Auto-scroll logic when drawing prize changes
    if (provider.isLiveDrawing && provider.liveDrawingPrize.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPrize(provider.liveDrawingPrize);
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: const Text('QUAY TRỰC TIẾP XSMB', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            provider.stopLiveDraw();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (provider.isLiveDrawing)
            IconButton(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.red),
              onPressed: () => provider.stopLiveDraw(),
              tooltip: 'Dừng Quay',
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Live status bar
          _buildStatusHeader(context, provider),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: AppConstants.prizeOrder.map((prizeCode) {
                  return _buildPrizeCard(context, provider, prizeCode);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, LotteryProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!provider.isLiveDrawing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: isDark ? AppTheme.darkSurface : Colors.white,
        child: Column(
          children: [
            const Text(
              'Phiên quay số chưa bắt đầu.',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Primary button: Scrape-based live draw (follows real broadcast)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => provider.startScrapeLiveDraw(),
                icon: const Icon(Icons.live_tv, color: Colors.white),
                label: const Text(
                  'TƯỜNG THUẬT TRỰC TIẾP',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Theo dõi kết quả trực tiếp từ đài quay (18h15 - 18h30)',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(height: 12),
            // Secondary buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.startWebSocketLiveDraw(),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('WebSocket', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => provider.startSimulatedLiveDraw(),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Chạy thử', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        border: const Border(bottom: BorderSide(color: Colors.redAccent, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Flashing red dot
          const FlashingDot(),
          const SizedBox(width: 8),
          Text(
            'HỆ THỐNG ĐANG QUAY TRỰC TIẾP...',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
              letterSpacing: 0.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Determine per-card draw state
  _PrizeCardState _getPrizeCardState(LotteryProvider provider, String prizeCode) {
    if (!provider.isLiveDrawing) return _PrizeCardState.idle;

    final result = provider.liveResult;
    final List<String> settledNumbers = _getSettledNumbers(result, prizeCode);
    final int expectedCount = AppConstants.prizeCounts[prizeCode] ?? 1;
    final int filledCount = settledNumbers.where((n) => n.isNotEmpty).length;
    final bool isCurrentlyDrawing = provider.liveDrawingPrize == prizeCode;

    if (filledCount >= expectedCount) {
      return _PrizeCardState.completed;
    } else if (isCurrentlyDrawing) {
      return _PrizeCardState.drawing;
    } else if (filledCount > 0) {
      return _PrizeCardState.partial;
    } else {
      return _PrizeCardState.waiting;
    }
  }

  Widget _buildPrizeCard(BuildContext context, LotteryProvider provider, String prizeCode) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = AppConstants.prizeLabels[prizeCode] ?? '';
    final count = AppConstants.prizeCounts[prizeCode] ?? 1;
    final isDb = prizeCode == 'db';

    // Per-card state
    final cardState = _getPrizeCardState(provider, prizeCode);
    final bool isPrizeDrawing = cardState == _PrizeCardState.drawing;
    final bool isCompleted = cardState == _PrizeCardState.completed;
    final bool isWaiting = cardState == _PrizeCardState.waiting;

    // Get existing numbers from the live or today result
    final result = provider.isLiveDrawing ? provider.liveResult : provider.todayResult;
    final List<String> settledNumbers = _getSettledNumbers(result, prizeCode);
    final int digitLength = (prizeCode == 'g7')
        ? 2
        : (prizeCode == 'g6'
            ? 3
            : ((prizeCode == 'g4' || prizeCode == 'g5') ? 4 : 5));

    // Card border and glow based on state
    Border? cardBorder;
    List<BoxShadow>? cardShadow;
    Color? statusColor;
    String? statusText;
    IconData? statusIcon;

    switch (cardState) {
      case _PrizeCardState.drawing:
        cardBorder = Border.all(color: AppTheme.accentGold, width: 2.0);
        cardShadow = [
          BoxShadow(
            color: AppTheme.accentGold.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 4,
          ),
        ];
        statusColor = AppTheme.accentGold;
        statusText = 'Đang quay...';
        statusIcon = Icons.motion_photos_on_rounded;
        break;
      case _PrizeCardState.completed:
        cardBorder = Border.all(color: Colors.green.shade400, width: 1.5);
        cardShadow = [
          BoxShadow(
            color: Colors.green.withOpacity(0.12),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
        statusColor = Colors.green.shade400;
        statusText = 'Đã có kết quả';
        statusIcon = Icons.check_circle;
        break;
      case _PrizeCardState.waiting:
        statusColor = isDark ? Colors.white30 : Colors.black26;
        statusText = 'Chờ quay...';
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      case _PrizeCardState.partial:
        statusColor = Colors.orange.shade400;
        statusText = 'Đang cập nhật';
        statusIcon = Icons.pending_rounded;
        break;
      case _PrizeCardState.idle:
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      key: _prizeKeys[prizeCode],
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: cardBorder,
        boxShadow: cardShadow,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: (isWaiting && provider.isLiveDrawing) ? 0.55 : 1.0,
        child: GlassCard(
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── HEADER ROW ───
              Row(
                children: [
                  // Prize label
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCompleted
                          ? Colors.green.shade400
                          : (isPrizeDrawing
                              ? AppTheme.accentGold
                              : (isDb
                                  ? AppTheme.primaryRed
                                  : (isDark ? Colors.white70 : AppTheme.lightTextPrimary))),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  if (provider.isLiveDrawing && statusText != null)
                    _AnimatedStatusBadge(
                      text: statusText,
                      color: statusColor!,
                      icon: statusIcon!,
                      isAnimating: isPrizeDrawing,
                    ),
                  const Spacer(),
                  // Completion indicator
                  if (isCompleted)
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                ],
              ),
              const Divider(height: 16, thickness: 0.5),
              // ─── NUMBERS AREA ───
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(count, (index) {
                  // Determine the state of this digit index
                  if (isPrizeDrawing && index == provider.liveDrawingIndex) {
                    // This slot is actively rolling
                    return RollingNumberGroup(
                      number: provider.liveRollingValue,
                      isRolling: true,
                      highlight: isDb,
                      expectedLength: digitLength,
                    );
                  } else if (index < settledNumbers.length) {
                    // This slot is already drawn
                    return RollingNumberGroup(
                      number: settledNumbers[index],
                      isRolling: false,
                      highlight: isDb,
                      expectedLength: digitLength,
                    );
                  } else {
                    // Empty slot not drawn yet
                    return RollingNumberGroup(
                      number: '',
                      isRolling: false,
                      highlight: isDb,
                      expectedLength: digitLength,
                    );
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Extract settled numbers for a given prize directly from LotteryResult fields.
  List<String> _getSettledNumbers(LotteryResult? result, String prizeCode) {
    if (result == null) return [];
    switch (prizeCode) {
      case 'db':
        return result.db.isNotEmpty ? [result.db] : [];
      case 'g1':
        return result.g1.isNotEmpty ? [result.g1] : [];
      case 'g2':
        return result.g2.where((e) => e.isNotEmpty).toList();
      case 'g3':
        return result.g3.where((e) => e.isNotEmpty).toList();
      case 'g4':
        return result.g4.where((e) => e.isNotEmpty).toList();
      case 'g5':
        return result.g5.where((e) => e.isNotEmpty).toList();
      case 'g6':
        return result.g6.where((e) => e.isNotEmpty).toList();
      case 'g7':
        return result.g7.where((e) => e.isNotEmpty).toList();
      default:
        return [];
    }
  }
}

/// Per-card draw state
enum _PrizeCardState {
  idle,       // Not in live draw mode
  waiting,    // Live mode but this prize hasn't started
  drawing,    // Currently rolling
  partial,    // Some numbers appeared but not all
  completed,  // All numbers settled
}

/// Animated status badge with icon for each prize card
class _AnimatedStatusBadge extends StatefulWidget {
  final String text;
  final Color color;
  final IconData icon;
  final bool isAnimating;

  const _AnimatedStatusBadge({
    required this.text,
    required this.color,
    required this.icon,
    required this.isAnimating,
  });

  @override
  State<_AnimatedStatusBadge> createState() => _AnimatedStatusBadgeState();
}

class _AnimatedStatusBadgeState extends State<_AnimatedStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedStatusBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = widget.isAnimating ? (0.6 + _controller.value * 0.4) : 1.0;
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 11, color: widget.color),
                const SizedBox(width: 4),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Custom blinking widget for the live status dot
class FlashingDot extends StatefulWidget {
  const FlashingDot({super.key});

  @override
  State<FlashingDot> createState() => _FlashingDotState();
}

class _FlashingDotState extends State<FlashingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppTheme.primaryRed,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryRed.withOpacity(0.5),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
