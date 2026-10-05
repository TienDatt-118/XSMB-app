import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentRoute = ModalRoute.of(context)?.settings.name;

    Widget buildItem(IconData icon, String title, String route) {
      final isSelected = currentRoute == route;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          leading: Icon(icon, color: isSelected ? AppTheme.primaryRed : (isDark ? Colors.white70 : Colors.black87)),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryRed : (isDark ? Colors.white : Colors.black),
            ),
          ),
          selected: isSelected,
          selectedTileColor: isDark ? Colors.white10 : Colors.red.shade50,
          onTap: () {
            Navigator.pop(context); // Close drawer
            if (!isSelected) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
        ),
      );
    }

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 24, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDC3545), Color(0xFF8B1E29)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amberAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.stars, color: Colors.amber, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'XỔ SỐ MIỀN BẮC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Hệ thống kết quả nhanh nhất',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildItem(Icons.home, 'Trang Chủ', AppRoutes.root),
                buildItem(Icons.bar_chart, 'Thống Kê', AppRoutes.analysis),
                buildItem(Icons.trending_up, 'Lô Top', AppRoutes.loGan),
                buildItem(Icons.call_split, 'Đầu - Đuôi', AppRoutes.dauDuoi),
                buildItem(Icons.calendar_month, 'Kỳ Quay', AppRoutes.history),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              children: [
                Text(
                  'XSMB SIÊU TỐC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Phiên bản 2.1.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white24 : Colors.grey.shade400,
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
