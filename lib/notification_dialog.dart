import 'package:flutter/material.dart';

class NotificationDialog {
  static Future<bool?> show(BuildContext context, bool currentStatus) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: Text(
            currentStatus
                ? 'Do you want to turn notifications OFF?'
                : 'Do you want to turn notifications ON?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: currentStatus ? Colors.red : Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }
}
