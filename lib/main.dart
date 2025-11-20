import 'package:flutter/material.dart';
import 'package:my_finance/notification/timezone.dart';
import 'package:my_finance/pages/loading_page.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestNotificationPermission();
  await initializeNotifications();
  await scheduleDailyMorningNotification();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoadingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

Future<void> requestNotificationPermission() async {
  final status = await Permission.notification.request();
  print('Notification permission: $status');
}


