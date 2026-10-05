import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class DateNavigator extends StatelessWidget {
  final DateTime currentDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSelectToday;
  final Future<void> Function()? onSelectDate;

  const DateNavigator({
    super.key,
    required this.currentDate,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectToday,
    this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final now = TimeUtils.nowVN;
    final isToday = currentDate.year == now.year &&
        currentDate.month == now.month &&
        currentDate.day == now.day;

    String getDayOfWeekName(int weekday) {
      switch (weekday) {
        case 1: return 'Thứ Hai';
        case 2: return 'Thứ Ba';
        case 3: return 'Thứ Tư';
        case 4: return 'Thứ Năm';
        case 5: return 'Thứ Sáu';
        case 6: return 'Thứ Bảy';
        case 7: return 'Chủ Nhật';
        default: return '';
      }
    }

    final dayName = getDayOfWeekName(currentDate.weekday);
    final dateStr = TimeUtils.formatDisplayDate(TimeUtils.formatToYYYYMMDD(currentDate));
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nút Previous
          InkWell(
            onTap: onPrevious,
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: borderColor)),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.chevron_left, color: iconColor),
            ),
          ),
          
          // Ngày hiện tại
          Expanded(
            child: InkWell(
              onTap: onSelectDate,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 16,
                      color: AppTheme.primaryRed.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$dayName, $dateStr',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nút Next
          InkWell(
            onTap: isToday ? null : onNext,
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: borderColor)),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.chevron_right, 
                color: isToday ? (isDark ? Colors.white24 : Colors.grey.shade300) : iconColor
              ),
            ),
          ),

          // Nút Hôm nay
          if (!isToday)
            InkWell(
              onTap: onSelectToday,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed,
                  border: Border(left: BorderSide(color: borderColor)),
                ),
                alignment: Alignment.center,
                child: const Text('Hôm nay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
        ],
      ),
    );
  }
}
