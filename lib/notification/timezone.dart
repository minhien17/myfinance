import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

// Biến toàn cục cho plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 💡 Khởi tạo thông báo
Future<void> initializeNotifications() async {
  tzdata.initializeTimeZones();
  final location = tz.getLocation('Asia/Ho_Chi_Minh');

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        print('Notification payload: ${response.payload}');
      }
    },
  );

  tz.setLocalLocation(location);
}

// 💡 Lập lịch thông báo hàng ngày (7:00 sáng)
Future<void> scheduleDailyMorningNotification() async {
  final now = tz.TZDateTime.now(tz.local);
  var scheduledDate =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, 7, 0, 0);

  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'daily_morning_notes_channel',
    'Nhắc nhở chi tiêu hàng ngày',
    channelDescription: 'Nhắc nhở ghi lại chi tiêu lúc 7h sáng.',
    importance: Importance.high,
    priority: Priority.high,
    ongoing: true,
    autoCancel: false,
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    12345,
    'My Finance',
    'Note all your expenses on My finance',
    scheduledDate,
    platformDetails,
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // ✅ Không cần exact alarm
    matchDateTimeComponents: DateTimeComponents.time,
    payload: 'open_expense_page',
  );

  print('✅ Đã lập lịch thông báo hàng ngày vào 7:00 sáng (inexact).');
}

// 💡 Lập lịch test (1 giây sau)
Future<void> showInstantNotification() async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'instant_channel',
    'Test Channel',
    channelDescription: 'Kênh test thông báo',
    importance: Importance.max,
    priority: Priority.high,
  );

  const NotificationDetails platformDetails =
      NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    999,
    'My Finance',
    'What your budget now',
    platformDetails,
  );
}


// 💡 Hủy tất cả thông báo
Future<void> cancelAllNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
  print('❌ Đã hủy tất cả thông báo đã lập lịch.');
}
