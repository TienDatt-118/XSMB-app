import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single digit ball with three visual states:
/// 1. Empty/Waiting  → shimmer placeholder "–"
/// 2. Rolling         → rapid random digits with gold pulse glow
/// 3. Settled         → final number with pop-in scale animation
class RollingNumberBall extends StatefulWidget {
  final String val;
  final bool isRolling;
  final bool highlight; // Đặc Biệt prize → red/gold glow
  final double size;

  const RollingNumberBall({
    super.key,
    required this.val,
    required this.isRolling,
    this.highlight = false,
    this.size = 42.0,
  });

  @override
  State<RollingNumberBall> createState() => _RollingNumberBallState();
}

class _RollingNumberBallState extends State<RollingNumberBall>
    with TickerProviderStateMixin {
  // Pop-in scale when digit settles
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Pulsing glow when rolling
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String _displayVal = '';
  Timer? _rollTimer;
  bool _wasRolling = false;

  @override
  void initState() {
    super.initState();
    _displayVal = widget.val.isEmpty ? '' : widget.val;

    // Scale pop-in
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Pulse glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRolling) {
      _startRolling();
    } else if (widget.val.isNotEmpty) {
      _scaleController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant RollingNumberBall oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRolling && !oldWidget.isRolling) {
      // Transition TO rolling
      _wasRolling = true;
      _startRolling();
    } else if (!widget.isRolling && oldWidget.isRolling) {
      // Transition FROM rolling → settled
      _stopRolling();
    } else if (!widget.isRolling && widget.val != oldWidget.val) {
      // Value changed while not rolling (new number revealed from scrape)
      if (widget.val.isNotEmpty && oldWidget.val.isEmpty) {
        // Number just appeared → play reveal animation
        _wasRolling = true;
        setState(() => _displayVal = widget.val);
        _scaleController.forward(from: 0.0);
      } else {
        setState(() => _displayVal = widget.val.isEmpty ? '' : widget.val);
        _scaleController.forward(from: 0.0);
      }
    }
  }

  void _startRolling() {
    _rollTimer?.cancel();
    _pulseController.repeat(reverse: true);
    _rollTimer = Timer.periodic(const Duration(milliseconds: 55), (timer) {
      if (mounted) {
        setState(() {
          _displayVal = Random().nextInt(10).toString();
        });
      }
    });
  }

  void _stopRolling() {
    _rollTimer?.cancel();
    _rollTimer = null;
    _pulseController.stop();
    _pulseController.value = 0.0;
    setState(() {
      _displayVal = widget.val.isEmpty ? '' : widget.val;
    });
    // Play reveal animation
    _scaleController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _buildBallContent(context),
    );
  }

  Widget _buildBallContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEmpty = _displayVal.isEmpty;
    final isRolling = widget.isRolling;

    // ─── EMPTY / WAITING STATE ───
    if (isEmpty && !isRolling) {
      return _ShimmerPlaceholder(size: widget.size, isDark: isDark);
    }

    // ─── ROLLING STATE ───
    if (isRolling) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final pulseVal = _pulseAnimation.value;
          return Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.grey.shade800
                  : Colors.amber.shade50,
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.5 + pulseVal * 0.5),
                width: 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withValues(alpha: 0.2 + pulseVal * 0.4),
                  blurRadius: 8 + pulseVal * 8,
                  spreadRadius: 1 + pulseVal * 3,
                ),
              ],
            ),
            child: Text(
              _displayVal,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentGold.withValues(alpha: 0.6 + pulseVal * 0.4),
                fontFamily: 'monospace',
              ),
            ),
          );
        },
      );
    }

    // ─── SETTLED STATE (with reveal animation) ───
    BoxDecoration decoration;
    TextStyle textStyle;

    if (widget.highlight) {
      // Giải Đặc Biệt → premium red/gold
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.luckyGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 3,
          ),
        ],
      );
      textStyle = const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'monospace',
      );
    } else {
      // Normal settled digit
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1A1F25) : Colors.white,
        border: Border.all(
          color: _wasRolling
              ? Colors.green.shade400
              : (isDark ? Colors.white24 : Colors.black12),
          width: _wasRolling ? 2.0 : 1.5,
        ),
        boxShadow: _wasRolling
            ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
      );
      textStyle = TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _wasRolling
            ? Colors.green.shade400
            : (isDark ? Colors.white : AppTheme.lightTextPrimary),
        fontFamily: 'monospace',
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: decoration,
        child: Text(
          _displayVal,
          style: textStyle,
        ),
      ),
    );
  }
}

/// Shimmer placeholder for digits that haven't been drawn yet.
/// Shows a subtle animated gradient sweep.
class _ShimmerPlaceholder extends StatefulWidget {
  final double size;
  final bool isDark;

  const _ShimmerPlaceholder({required this.size, required this.isDark});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              center: Alignment.center,
              startAngle: 0,
              endAngle: 2 * pi,
              transform: GradientRotation(_shimmerController.value * 2 * pi),
              colors: widget.isDark
                  ? [
                      Colors.grey.shade800,
                      Colors.grey.shade700,
                      Colors.grey.shade600,
                      Colors.grey.shade700,
                      Colors.grey.shade800,
                    ]
                  : [
                      Colors.grey.shade200,
                      Colors.grey.shade100,
                      Colors.white,
                      Colors.grey.shade100,
                      Colors.grey.shade200,
                    ],
            ),
            border: Border.all(
              color: widget.isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
          child: Text(
            '–',
            style: TextStyle(
              fontSize: 16,
              color: widget.isDark ? Colors.white24 : Colors.black26,
              fontWeight: FontWeight.w300,
            ),
          ),
        );
      },
    );
  }
}

/// Renders a full multi-digit lottery number (e.g. 12345) using rolling balls.
/// Each digit independently shows its state: waiting → rolling → settled.
class RollingNumberGroup extends StatelessWidget {
  final String number;
  final bool isRolling;
  final bool highlight;
  final int expectedLength;

  const RollingNumberGroup({
    super.key,
    required this.number,
    required this.isRolling,
    required this.highlight,
    this.expectedLength = 5,
  });

  @override
  Widget build(BuildContext context) {
    final pads = expectedLength - number.length;
    final digits = <String>[];

    // Pad characters if not full length yet
    for (int i = 0; i < pads; i++) {
      digits.add('');
    }
    for (int i = 0; i < number.length; i++) {
      digits.add(number[i]);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(expectedLength, (index) {
        final charVal = digits[index];
        final digitIsRolling = isRolling && charVal.isEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: RollingNumberBall(
            val: charVal,
            isRolling: digitIsRolling,
            highlight: highlight,
          ),
        );
      }),
    );
  }
}
