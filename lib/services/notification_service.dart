import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Dar_es_Salaam'));

    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // Request permissions for Android 13+
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
    }

    final iOS = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iOS != null) {
      await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  // Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'duka_channel',
      'Duka Notifications',
      channelDescription: 'Notifications for Duka Kiganjani app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // Low stock alert
  Future<void> showLowStockAlert({
    required String productName,
    required int quantity,
    required int threshold,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '⚠️ Bidhaa Zinakaribia Kuisha!',
      body:
          '$productName zimebaki $quantity tu (kiwango cha chini: $threshold)',
      payload: 'low_stock',
    );
  }

  // Daily sales summary
  Future<void> showDailySalesSummary({
    required double totalSales,
    required int transactionCount,
  }) async {
    await showNotification(
      id: 1,
      title: '📊 Muhtasari wa Mauzo ya Leo',
      body:
          'Jumla: TZS ${totalSales.toStringAsFixed(0)} | Mauzo: $transactionCount',
      payload: 'daily_summary',
    );
  }

  // Debt reminder
  Future<void> showDebtReminder({
    required int debtCount,
    required double totalDebt,
  }) async {
    await showNotification(
      id: 2,
      title: '💰 Madeni Yasiyolipwa',
      body:
          'Una madeni $debtCount ya jumla TZS ${totalDebt.toStringAsFixed(0)}',
      payload: 'debt_reminder',
    );
  }

  // Schedule daily reminder at specific time
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminders',
          'Daily Reminders',
          channelDescription: 'Daily reminders for shop management',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Opening reminder (8:00 AM)
  Future<void> scheduleOpeningReminder() async {
    await scheduleDailyReminder(
      id: 100,
      title: '🌅 Habari za Asubuhi!',
      body: 'Ni wakati wa kufungua duka',
      hour: 8,
      minute: 0,
    );
  }

  // Closing reminder (6:00 PM)
  Future<void> scheduleClosingReminder() async {
    await scheduleDailyReminder(
      id: 101,
      title: '🌙 Muhtasari wa Leo',
      body: 'Ni wakati wa kufunga duka. Angalia muhtasari wa mauzo',
      hour: 18,
      minute: 0,
    );
  }
}
