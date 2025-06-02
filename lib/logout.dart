import 'package:flutter/material.dart';
import 'signup_screen.dart';
import 'user_store.dart';
import 'signup_screen.dart';  // Use your exact file and class name here

class LogoutPage extends StatelessWidget {
  const LogoutPage({Key? key}) : super(key: key);

  void _logout(BuildContext context) {
    final userStore = UserStore();

    // Optionally clear user data here
    userStore.updateUserInfo(
      fullName: '',
      email: '',
      phone: '',
      password: '',
    );

    // Navigate to SignUpScreen, removing all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logout and redirect immediately after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logout(context);
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
