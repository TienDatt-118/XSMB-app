import 'package:flutter/material.dart';
import '../screens/main_layout.dart';
import '../screens/analysis_screen.dart';
import '../screens/soi_cau_screen.dart';
import '../screens/lo_gan_screen.dart';
import '../screens/dau_duoi_screen.dart';
import '../screens/history_screen.dart';
import '../screens/live_draw_screen.dart';

class AppRoutes {
  static const String root = '/';
  static const String soiCau = '/soi_cau';
  static const String analysis = '/analysis';
  static const String loGan = '/lo_gan';
  static const String dauDuoi = '/dau_duoi';
  static const String history = '/history';
  static const String analysisDashboard = '/analysis_dashboard';
  static const String liveDraw = '/live';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return MaterialPageRoute(builder: (_) => const MainLayout(), settings: settings);
      case soiCau:
        return MaterialPageRoute(builder: (_) => const SoiCauScreen(), settings: settings);
      case loGan:
        return MaterialPageRoute(builder: (_) => const LoGanScreen(), settings: settings);
      case analysis:
      case analysisDashboard:
        return MaterialPageRoute(builder: (_) => const AnalysisScreen(), settings: settings);
      case dauDuoi:
        return MaterialPageRoute(builder: (_) => const DauDuoiScreen(), settings: settings);
      case history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen(), settings: settings);
      case liveDraw:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const LiveDrawScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Không tìm thấy tuyến đường: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
