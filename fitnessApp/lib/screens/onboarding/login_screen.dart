import 'package:FitnessApp/main.dart';
import 'package:FitnessApp/screens/onboarding/complete_profile.dart';
import 'package:FitnessApp/screens/onboarding/create_account.dart';
import 'package:FitnessApp/screens/forgot_password_screen.dart';
import 'package:FitnessApp/services/firebase_service.dart';
import 'package:FitnessApp/services/firestore_service.dart';
import 'package:FitnessApp/services/healthconnect.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // bool isSignedIn = false;
  bool _obscureText = true;
  @override
  void initState() {
    super.initState();
    requestInitialPermissions();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> requestInitialPermissions() async {
    await [Permission.notification, Permission.activityRecognition].request();

    await HealthService().requestHealthPermissions();
  }

  void _checkLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool signedIn = prefs.getBool('isSignedIn') ?? false;

    if (signedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),

              const Center(
                child: Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text("E-mail", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Enter your email"),

              const SizedBox(height: 20),

              const Text("Password", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Enter your password", isPassword: true),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _loginButton(),

              const SizedBox(height: 30),

              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Or", style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 20),

              _socialButton(
                "Login with Apple",
                Icons.apple,
                onPressed: () async {
                  await HealthService().requestHealthPermissions();
                },
              ),
              const SizedBox(height: 8),
              _socialButton(
                "Login with Google",
                Icons.g_mobiledata,
                onPressed: () async {
                  final UserCredential? userscreds = await FirebaseService()
                      .signInWithGoogle();

                  if (userscreds?.user?.email == null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Login Failed")));
                  } else {
                    final uid = userscreds?.user?.uid;
                    final doc = await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('userprofile')
                        .doc('profile')
                        .get();

                    if (doc.exists) {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.setBool('ProfileCompleted', true);
                      await prefs.setBool('isSignedIn', true);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompleteProfilescreen(),
                        ),
                      );
                    }
                  }
                },
              ),

              // const Spacer(),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateAccountscreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String hint, {bool isPassword = false}) {
    return TextField(
      style: TextStyle(color: Colors.white),
      cursorColor: Colors.white60,
      obscureText: isPassword ? _obscureText : false,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                color: Colors.white54,
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _loginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E8B57),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {},
      child: const Text(
        "Log In",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _socialButton(
    String text,
    IconData icon, {
    required void Function()? onPressed,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: const BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,

      icon: Icon(icon, color: Colors.white, size: 25),
      label: Text(text, style: TextStyle(color: Colors.white)),
    );
  }
}
