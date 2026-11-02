import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:dio/dio.dart';

const String kNotificationChannelId = 'lrf_blida_notifications';
const String kNotificationChannelName = 'إشعارات وتنبيهات رابطة البليدة';
const String kNotificationChannelDesc = 'تنبيهات الأخبار والمباريات والبلاغات العاجلة';

final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationService.checkAndShowNotifications();
    } catch (_) {}
    return Future.value(true);
  });
}

class NotificationService {
  static Timer? _foregroundTimer;

  static Future<void> init() async {
    try {
      // 1. Initialize Flutter Local Notifications
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings: initSettings);

      // Create Android Notification Channel
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            kNotificationChannelId,
            kNotificationChannelName,
            description: kNotificationChannelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidPlugin.requestNotificationsPermission();
      }

      // 2. Initialize WorkManager for background execution when app is closed
      if (!kIsWeb) {
        await Workmanager().initialize(
          callbackDispatcher,
        );

        await Workmanager().registerPeriodicTask(
          "check_lrf_notifications_task",
          "checkLrfNotifications",
          frequency: const Duration(minutes: 15),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
        );
      }

      // 3. Start foreground polling timer (checks every 60 seconds while app is in memory)
      _startForegroundPolling();

      // 4. Initial check now
      checkAndShowNotifications();
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  static void _startForegroundPolling() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkAndShowNotifications();
    });
  }

  static Future<void> checkAndShowNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getInt('last_server_notification_id') ?? 0;

      final dio = Dio(BaseOptions(
        baseUrl: 'https://lrf-blida.dz/api/v1',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      final res = await dio.get('/notifications/check', queryParameters: {
        'after_id': lastId,
      });

      if (res.statusCode == 200 && res.data['status'] == 'success') {
        final List list = res.data['data'] ?? [];
        int maxId = lastId;

        for (var item in list) {
          final id = item['id'] is int ? item['id'] as int : int.tryParse(item['id']?.toString() ?? '0') ?? 0;
          if (id > maxId) maxId = id;

          // Don't show notifications on initial fresh install if lastId was 0, just sync maxId
          if (lastId > 0) {
            await showSystemNotification(
              id: id,
              title: (item['title'] ?? 'تنبيه جديد من الرابطة').toString(),
              body: (item['body'] ?? '').toString(),
              payload: jsonEncode(item),
            );
          }
        }

        if (maxId > lastId || lastId == 0) {
          final serverLatest = res.data['latest_id'] is int ? res.data['latest_id'] as int : maxId;
          await prefs.setInt('last_server_notification_id', serverLatest > maxId ? serverLatest : maxId);
        }
      }
    } catch (e) {
      debugPrint('checkAndShowNotifications error: $e');
    }
  }

  static Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      kNotificationChannelId,
      kNotificationChannelName,
      channelDescription: kNotificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }
}
