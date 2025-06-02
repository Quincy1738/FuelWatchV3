import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStore {
  static final UserStore _instance = UserStore._internal();
  factory UserStore() => _instance;
  UserStore._internal();

  final Map<String, String> _users = {}; // only in-memory

  // Store current user info in memory
  String? _currentEmail;
  String? _currentFullName;
  String? _currentPhone;
  String? _currentPassword;
  String? _profileImagePath;

  // Keys for SharedPreferences
  static const _keyEmail = 'user_email';
  static const _keyFullName = 'user_fullName';
  static const _keyPhone = 'user_phone';
  static const _keyPassword = 'user_password';
  static const _keyProfileImagePath = 'user_profileImagePath';

  String? get profileImagePath => _profileImagePath;
  set profileImagePath(String? path) {
    _profileImagePath = path;
    if (kDebugMode) {
      print('Profile image path updated: $path');
    }
    _saveToPrefs();
  }

  String? get email => _currentEmail;
  String? get fullName => _currentFullName;
  String? get phone => _currentPhone;
  String? get password => _currentPassword;

  // Register user (only updates in-memory _users)
  void registerUser(String email, String password,
      {required String fullName, required String phone}) {
    _users[email] = password;
    _currentEmail = email;
    _currentFullName = fullName;
    _currentPhone = phone;
    _currentPassword = password;

    if (kDebugMode) {
      print("User registered: $fullName, $email");
    }
    _saveToPrefs();
  }


  bool userExists(String email) => _users.containsKey(email);

  bool validateUser(String email, String password) {
    if (_users[email] == password) {
      _currentEmail = email;
      _currentPassword = password;
      _loadUserInfoFromPrefs(); // Load full info for this user
      return true;
    }
    return false;
  }

  // ✅ Add this method to retrieve stored password
  String? getPasswordForEmail(String email) {
    return _users[email];
  }

  void updateUserInfo({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? profileImagePath,
  }) {
    _currentFullName = fullName;
    _currentPhone = phone;
    _currentPassword = password;

    if (_users.containsKey(email)) {
      _users[email] = password;
    }

    if (profileImagePath != null) {
      _profileImagePath = profileImagePath;
    }

    if (kDebugMode) {
      print('User info updated: $fullName, $phone, Image: $_profileImagePath');
    }
    _saveToPrefs();
  }

  /// Save current user data to SharedPreferences
  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentEmail != null) {
      await prefs.setString(_keyEmail, _currentEmail!);
    }
    if (_currentFullName != null) {
      await prefs.setString(_keyFullName, _currentFullName!);
    }
    if (_currentPhone != null) {
      await prefs.setString(_keyPhone, _currentPhone!);
    }
    if (_currentPassword != null) {
      await prefs.setString(_keyPassword, _currentPassword!);
    }
    if (_profileImagePath != null) {
      await prefs.setString(_keyProfileImagePath, _profileImagePath!);
    }
  }

  /// Load user info from SharedPreferences
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentEmail = prefs.getString(_keyEmail);
    _currentFullName = prefs.getString(_keyFullName);
    _currentPhone = prefs.getString(_keyPhone);
    _currentPassword = prefs.getString(_keyPassword);
    _profileImagePath = prefs.getString(_keyProfileImagePath);

    if (kDebugMode) {
      print('Loaded user from prefs: $_currentEmail, $_currentFullName');
    }
  }

  /// Load user info from prefs (for example, after validateUser)
  Future<void> _loadUserInfoFromPrefs() async {
    await loadFromPrefs();
  }

  /// Clear user data from memory and prefs (e.g. on logout)
  Future<void> clearUserData() async {
    _currentEmail = null;
    _currentFullName = null;
    _currentPhone = null;
    _currentPassword = null;
    _profileImagePath = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyFullName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyProfileImagePath);

    if (kDebugMode) {
      print('User data cleared');
    }
  }
}
