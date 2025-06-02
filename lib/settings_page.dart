import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:petroleum_management_system/login_screen.dart';

import 'help_center_page.dart';
import 'personal_information_page.dart';
import 'user_store.dart';
import 'notification_dialog.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = false;
  final UserStore _userStore = UserStore();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<bool> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return true;
    }
    return false;
  }

  Future<void> _enableNotifications() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'your_channel_id',
      'Your Channel Name',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Notifications Enabled',
      'You will now receive notifications.',
      platformChannelSpecifics,
      payload: 'notification_enabled',
    );
  }

  Future<void> _disableNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (enable) {
      final permissionGranted = await _requestNotificationPermission();
      if (!permissionGranted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
                'Notification permission is required to enable notifications. Please enable it in settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(context);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }
      await _enableNotifications();
    } else {
      await _disableNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userName = _userStore.fullName ?? 'Your Name';
    final String userEmail = _userStore.email ?? 'email@example.com';

    File? profileImageFile;
    if (_userStore.profileImagePath != null) {
      profileImageFile = File(_userStore.profileImagePath!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Settings",
            style: TextStyle(
              color: Colors.grey[900],
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            )),
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        children: [
          // Profile Card
          Card(
            elevation: 4,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white,
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              leading: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blueGrey.shade200,
                backgroundImage:
                profileImageFile != null ? FileImage(profileImageFile) : null,
                child: profileImageFile == null
                    ? const Icon(Icons.person_outline,
                    color: Colors.white, size: 36)
                    : null,
              ),
              title: Text(
                userName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black),
              ),
              subtitle: Text(
                userEmail,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PersonalInformationPage()),
                  );
                  setState(() {});
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Account Settings Header
          Text(
            'Account Settings',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[850],
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 12),

          // Personal Info Tile
          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blueAccent),
              title: const Text('Personal Information'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PersonalInformationPage()),
                );
                setState(() {});
              },
            ),
          ),

          const SizedBox(height: 12),

          // Notifications Tile with Switch
          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined,
                  color: Colors.deepPurple),
              title: const Text('Notifications'),
              trailing: Switch.adaptive(
                value: notificationsEnabled,
                activeColor: Colors.deepPurple,
                onChanged: (value) async {
                  if (value) {
                    final permissionGranted = await _requestNotificationPermission();
                    if (!permissionGranted) {
                      // Show dialog to open settings if denied
                      await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Permission Required'),
                          content: const Text(
                              'Notification permission is required to enable notifications. Please enable it in settings.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                openAppSettings();
                                Navigator.pop(context);
                              },
                              child: const Text('Open Settings'),
                            ),
                          ],
                        ),
                      );
                      return;
                    }
                    await _enableNotifications();
                  } else {
                    await _disableNotifications();
                  }
                  setState(() {
                    notificationsEnabled = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Notifications turned ON' : 'Notifications turned OFF',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Help & Support Section
          Text(
            'Help & Support',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[850],
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.teal),
              title: const Text(
                'Help & Support',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelpCenterPage()),
                );
              },
            ),
          ),

          const SizedBox(height: 48),

          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: Colors.redAccent.shade200,
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
