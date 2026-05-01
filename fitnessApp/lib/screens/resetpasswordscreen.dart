import 'package:flutter/material.dart';

class Resetpasswordscreen extends StatefulWidget {
  const Resetpasswordscreen({super.key});

  @override
  State<Resetpasswordscreen> createState() => _Resetpasswordscreen();
}

class _Resetpasswordscreen extends State<Resetpasswordscreen> {
  bool _obscureText = true;
  bool _obscureText2 = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
          ), //Needs A Change
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30),
              Text(
                "Set a new password",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Create a new password. Ensure it differs from\nprevious ones for security",
                style: TextStyle(color: Colors.white38),
              ),
              SizedBox(height: 20),

              const Text("Password", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _inputField(
                "Enter new password",
                _obscureText,
                ontoggle: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),

              SizedBox(height: 20),

              const Text(
                "Confirm Password",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 8),
              _inputField(
                "Re-enter your password",
                _obscureText2,
                ontoggle: () {
                  setState(() {
                    _obscureText2 = !_obscureText2;
                  });
                },
              ),

              SizedBox(height: 20),
              _continueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hintText,
    bool obscureText, {
    required VoidCallback ontoggle,
  }) {
    return TextField(
      style: TextStyle(color: Colors.white),
      obscureText: obscureText,
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

  Widget _continueButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E8B57),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {},
      child: const Text(
        "Confirm",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
