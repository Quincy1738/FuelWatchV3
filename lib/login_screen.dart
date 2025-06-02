import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dashboard_screen.dart';
import 'forgot_password.dart';
import 'signup_screen.dart';
import 'user_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final UserStore _userStore = UserStore();
  bool _isCheckingConnection = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();

    // Animate fade-in for the form
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _hasInternet() async {
    var result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> _checkSavedLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool remember = prefs.getBool('remember_me') ?? false;
    String? email = prefs.getString('email');
    String? password = prefs.getString('password');

    if (remember && email != null && password != null) {
      if (_userStore.validateUser(email, password)) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    setState(() => _isCheckingConnection = true);

    bool online = await _hasInternet();
    if (!online) {
      setState(() => _isCheckingConnection = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection')),
      );
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (_userStore.validateUser(email, password)) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setBool('remember_me', true);
        await prefs.setString('email', email);
        await prefs.setString('password', password);
      } else {
        await prefs.remove('remember_me');
        await prefs.remove('email');
        await prefs.remove('password');
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password')),
      );
    }

    setState(() => _isCheckingConnection = false);
  }

  Future<void> _handleGoogleSignIn() async {
    bool online = await _hasInternet();
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to the internet')),
      );
      return;
    }

    try {
      GoogleSignIn googleSignIn = GoogleSignIn();
      GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${account.email}')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google sign-in failed')),
      );
    }
  }

  Future<void> _handleAppleSignIn() async {
    bool online = await _hasInternet();
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to the internet')),
      );
      return;
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final userDisplay = credential.email ?? credential.userIdentifier;

      if (userDisplay != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as $userDisplay')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Apple sign-in failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                child: Container(
                  constraints: BoxConstraints(maxWidth: 450),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Circle Avatar
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_gas_station_rounded, size: 72, color: theme.primaryColor),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'Welcome to FuelWatch',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColorDark,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to continue',
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      ),

                      const SizedBox(height: 30),

                      // Email TextField
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email, color: theme.primaryColor),
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password TextField
                      TextField(
                        controller: passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock, color: theme.primaryColor),
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.primaryColor, width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: theme.primaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: theme.primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          const Text('Remember me'),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              final result = await Navigator.push<Map<String, String>>(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                              );

                              if (result != null) {
                                setState(() {
                                  emailController.text = result['email'] ?? '';
                                  passwordController.text = result['password'] ?? '';
                                });
                              }
                            },
                            child: const Text('Forgot password?'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isCheckingConnection ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 6,
                          ),
                          child: _isCheckingConnection
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // <-- explicitly set text color here
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1.2,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade400,
                              thickness: 1.2,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _handleGoogleSignIn,
                            icon: const Icon(Icons.g_mobiledata, size: 24), // Google-like icon from Flutter's material icons
                            label: const Text('Google'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _handleAppleSignIn,
                            icon: const Icon(Icons.apple, size: 24),
                            label: const Text('Apple'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              textStyle: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
