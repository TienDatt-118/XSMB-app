import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lottery_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'analysis_screen.dart';
import 'soi_cau_screen.dart';
import 'thong_ke_screen.dart';
import 'history_screen.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> get _pages => [
    const HomeScreen(),
    const ThongKeScreen(),
    const SoiCauScreen(),
    const AnalysisScreen(),
    const HistoryScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 4 && index != _currentIndex) {
      final provider = context.read<LotteryProvider>();
      provider.fetchHistoryRange(provider.historyFromDate, provider.historyToDate);
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          selectedItemColor: AppTheme.primaryRed,
          unselectedItemColor: isDark ? Colors.grey[500] : Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang Chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Thống Kê',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Soi Cầu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Phân Tích',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Kỳ Quay',
            ),
          ],
        ),
      ),
    );
  }
}
