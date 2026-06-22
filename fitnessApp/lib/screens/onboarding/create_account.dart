import 'package:FitnessApp/screens/onboarding/login_screen.dart';
import 'package:flutter/material.dart';

class CreateAccountscreen extends StatefulWidget {
  const CreateAccountscreen({super.key});

  @override
  State<CreateAccountscreen> createState() => _CreateAccountscreen();
}

class _CreateAccountscreen extends State<CreateAccountscreen> {
  bool _obscureText = true;
  bool _obscureText2 = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 50),

              Center(
                child: Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 30),

              const Text("Name", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Enter your name"),
              SizedBox(height: 10),

              const Text("Age", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Enter your age"),
              SizedBox(height: 10),

              const Text("Gender", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Select your gender"),
              SizedBox(height: 10),

              const Text("Height", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Enter your height"),
              SizedBox(height: 10),

              const Text("Email", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField("Enter you email"),
              SizedBox(height: 10),

              const Text("Password", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputPassField(
                "Enter password",
                _obscureText,
                ontoggle: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              SizedBox(height: 10),

              const Text(
                "Confirm Password",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              _inputPassField(
                "Re-enter your password",
                _obscureText2,
                ontoggle: () {
                  setState(() {
                    _obscureText2 = !_obscureText2;
                  });
                },
              ),
              SizedBox(height: 10),
              _continueButton(),

              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Haven't received the code yet? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      "Resend Code",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputPassField(
    String hintText,
    bool? obscureText, {
    VoidCallback? ontoggle,
  }) {
    return TextField(
      style: TextStyle(color: Colors.white),
      obscureText: obscureText!,
      decoration: InputDecoration(
        hintText: hintText,
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
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          color: Colors.white54,
          onPressed: ontoggle,
        ),
      ),
    );
  }

  Widget _inputField(String hintText) {
    return TextField(
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
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
      ),
    );
  }

  Widget _continueButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E8B57),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {},
      child: const Text(
        "Create Account",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
