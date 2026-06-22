import 'package:FitnessApp/screens/resetpasswordscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmailCodeScreen extends StatefulWidget {
  const EmailCodeScreen({super.key});

  @override
  State<EmailCodeScreen> createState() => _EmailCodeScreenstate();
}

class _EmailCodeScreenstate extends State<EmailCodeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          // style: ButtonStyle(
          //   backgroundColor: WidgetStateProperty.all(Colors.white),
          // ),
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30),
              Text(
                "Check Your Email",
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "We sent a reset link to examp...e@email.com\n Enter the 5 digit code that is mentioned in the email",
                style: TextStyle(color: Colors.white38),
              ),
              SizedBox(height: 20),
              // DigitBoxRow(digits: ["", "", "", "", ""]),
              OtpField(),
              SizedBox(height: 20),

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
            ],
          ),
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
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Resetpasswordscreen()),
        );
      },
      child: const Text(
        "Verify Code",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class DigitBoxRow extends StatelessWidget {
  final List<String> digits;

  const DigitBoxRow({super.key, required this.digits});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.map((digit) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 6),
          width: 50,
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            digit,
            style: TextStyle(fontSize: 22, color: Colors.white),
          ),
        );
      }).toList(),
    );
  }
}

class OtpField extends StatefulWidget {
  const OtpField({super.key});

  @override
  State<OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<OtpField> {
  final int length = 5;
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  String get text => controller.text;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      setState(() {
        if (controller.text.length > length) {
          controller.text = controller.text.substring(0, length);
          controller.selection = TextSelection.collapsed(
            offset: controller.text.length,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _onTap() {
    FocusScope.of(context).requestFocus(focusNode);
  }

  Widget _buildBox(int index) {
    final char = index < text.length ? text[index] : "";

    return Container(
      width: 50,
      height: 60,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        char,
        style: const TextStyle(fontSize: 22, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden TextField (REAL INPUT)
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [LengthLimitingTextInputFormatter(length)],
            ),
          ),

          // Visible UI
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(length, _buildBox),
          ),
        ],
      ),
    );
  }
}
