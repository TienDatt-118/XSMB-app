import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? color;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = color ?? AppTheme.primaryRed;

    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 20, bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: primaryColor, size: 22),
            const SizedBox(width: 8),
          ] else ...[
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
