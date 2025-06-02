import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'splash_screen.dart';
import 'user_store.dart'; // Import your UserStore

// Create a global instance of the notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved user data
  await UserStore().loadFromPrefs();

  // Android notification initialization
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  // Combine into platform initialization
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  // Initialize notifications plugin
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(FuelManagementApp());
}

class FuelManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Start with splash
    );
  }
}
