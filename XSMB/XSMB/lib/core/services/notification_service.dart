import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Initialize notifications
  Future<void> init() async {
    if (_isInitialized) return;
    
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    try {
      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create Android channel
      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
            
        if (androidPlugin != null) {
          // Request POST_NOTIFICATIONS permission for Android 13+
          await androidPlugin.requestNotificationsPermission();
          
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            'xsmb_live_draw', // id
            'XSMB Live Draw Alerts', // name
            description: 'Thông báo kết quả XSMB trực tiếp và hàng ngày.', // description
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          );

          await androidPlugin.createNotificationChannel(channel);
        }
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint("Notification Initialization Error: $e");
    }
  }

  // Handle click on notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint("Notification tapped: ${response.payload}");
    // We can handle payload routing in routes or navigation holder
  }

  // Show a result alert notification
  Future<void> showResultNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isInitialized) await init();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'xsmb_live_draw',
      'XSMB Live Draw Alerts',
      channelDescription: 'Thông báo kết quả XSMB trực tiếp và hàng ngày.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint("Error showing notification: $e");
    }
  }
}
