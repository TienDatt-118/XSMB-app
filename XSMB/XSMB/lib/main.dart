import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'core/network/api_client.dart';
import 'core/services/database_helper.dart';
import 'core/services/storage_service.dart';
import 'core/services/pusher_service.dart';
import 'core/services/notification_service.dart';
import 'core/repository/lottery_repository.dart';
import 'core/repository/admin_repository.dart';
import 'core/providers/lottery_provider.dart';
import 'core/providers/admin_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/firebase_messaging_service.dart';
import 'core/services/xsmb_scraper_service.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // THÊM DÒNG NÀY VÀO ĐỂ KHỞI TẠO NGÔN NGỮ
  await initializeDateFormatting('vi_VN', null);

  // 1. Initialize core system services
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);
  storageService.loadConfigOverrides();
// load test url redirects if saved
  final dbHelper = DatabaseHelper();
  final notificationService = NotificationService();

  final pusherService = PusherService();
  pusherService.init(); // prepare WebSocket connections (no await to speed up boot)

  final firebaseMessagingService = FirebaseMessagingService(notificationService);

  // Khởi tạo các service có yêu cầu xin Quyền (Permission) sau khi App đã hiển thị UI
  // Việc gọi xin quyền trước runApp() sẽ gây lỗi đen màn hình trên Android.
  Future.delayed(const Duration(milliseconds: 500), () async {
    await notificationService.init(); 
    await firebaseMessagingService.init();
  });

  // 2. Initialize repositories & API client
  final apiClient = ApiClient(storageService);
  final scraperService = XsmbScraperService(dio: apiClient.dio);
  final lotteryRepository = LotteryRepository(apiClient, dbHelper, scraperService);
  final adminRepository = AdminRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LotteryProvider(lotteryRepository, pusherService, notificationService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(adminRepository, storageService),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(prefs),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final pusherService = context.read<LotteryProvider>().pusherService;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // Tối ưu RAM và Pin: Ngắt kết nối Pusher khi người dùng ẩn App
      pusherService.disconnect();
    } else if (state == AppLifecycleState.resumed) {
      // Kết nối lại khi người dùng quay lại App
      pusherService.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'XSMB Siêu Tốc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: AppRoutes.root,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
