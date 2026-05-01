import 'package:FitnessApp/main.dart';
import 'package:FitnessApp/models/UserProfile_model.dart';
import 'package:FitnessApp/screens/onboarding/login_screen.dart';
import 'package:FitnessApp/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompleteProfilescreen extends StatefulWidget {
  const CompleteProfilescreen({super.key});

  @override
  State<CompleteProfilescreen> createState() => _CompleteProfilescreen();
}

class _CompleteProfilescreen extends State<CompleteProfilescreen> {
  TextEditingController heightController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  String? gender;
  int feet = 0;
  int inches = 0;
  @override
  void dispose() {
    genderController.dispose();
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    nameController.dispose();
    super.dispose();
  }

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
                  "Complete Your Profile",
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
              _inputField("Enter your name", nameController),
              SizedBox(height: 10),

              const Text("Age", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              _numericinputField("Enter your age", ageController),
              SizedBox(height: 10),

              const Text("Gender", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              // _inputField("Select your gender", genderController),
              _dropdownField(
                "Select gender",
                gender,
                ["Male", "Female", "Other"],
                (value) {
                  setState(() {
                    gender = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please select gender";
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),

              const Text("Height", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => showHeightPicker(context),
                child: AbsorbPointer(
                  child: _inputField("Height", heightController),
                ),
              ),
              SizedBox(height: 10),

              const Text("Weight", style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              // GestureDetector(
              //   onTap: () => showWeightPicker(context),
              //   child: AbsorbPointer(
              //     child: _inputField("Weight", weightController),
              //   ),
              // ),
              _numericinputField("Enter you weight", weightController),
              SizedBox(height: 10),

              SizedBox(height: 10),
              _continueButton(),

              SizedBox(height: 8),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text("Haven't received the code yet? "),
              //     GestureDetector(
              //       onTap: () {},
              //       child: const Text(
              //         "Resend Code",
              //         style: TextStyle(color: Colors.blue),
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(height: 15),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     const Text("Already have an account? "),
              //     GestureDetector(
              //       onTap: () {
              //         Navigator.pop(
              //           context,
              //           MaterialPageRoute(builder: (context) => LoginScreen()),
              //         );
              //       },
              //       child: const Text(
              //         "Login",
              //         style: TextStyle(color: Colors.blue),
              //       ),
              //     ),
              //   ],
              // ),
              SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  void showHeightPicker(BuildContext context) {
    int tempFeet = feet;
    int tempInches = inches;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 300,
              child: Column(
                children: [
                  //  Top bar with Done button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            feet = tempFeet;
                            inches = tempInches;
                            heightController.text = "$feet ft $inches in";
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Done"),
                      ),
                    ],
                  ),

                  //  Picker
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: feet - 3,
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempFeet = index + 3;
                              });
                            },
                            children: List.generate(
                              5,
                              (i) => Center(
                                child: Text(
                                  "${i + 3} ft",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: inches,
                            ),
                            onSelectedItemChanged: (index) {
                              setModalState(() {
                                tempInches = index;
                              });
                            },
                            children: List.generate(
                              12,
                              (i) => Center(
                                child: Text(
                                  "$i in",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // void showWeightPicker(BuildContext context) {
  //   int tempWeight = 70;

  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.black,
  //     builder: (_) {
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return SizedBox(
  //             height: 300,
  //             child: Column(
  //               children: [
  //                 // Top bar
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     TextButton(
  //                       onPressed: () => Navigator.pop(context),
  //                       child: Text("Cancel"),
  //                     ),
  //                     TextButton(
  //                       onPressed: () {
  //                         setState(() {
  //                           weightController.text = "$tempWeight kg";
  //                         });
  //                         Navigator.pop(context);
  //                       },
  //                       child: Text("Done"),
  //                     ),
  //                   ],
  //                 ),

  //                 // Picker
  //                 Expanded(
  //                   child: CupertinoPicker(
  //                     backgroundColor: Colors.black,
  //                     itemExtent: 40,
  //                     scrollController: FixedExtentScrollController(
  //                       initialItem: tempWeight - 30,
  //                     ),
  //                     onSelectedItemChanged: (index) {
  //                       setModalState(() {
  //                         tempWeight = 30 + index;
  //                       });
  //                     },
  //                     children: List.generate(
  //                       171, // 30kg to 200kg
  //                       (i) => Center(
  //                         child: Text(
  //                           "${30 + i} kg",
  //                           style: TextStyle(color: Colors.white, fontSize: 18),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  Widget _inputField(String hintText, TextEditingController? controller) {
    return TextField(
      style: TextStyle(color: Colors.white),
      controller: controller,
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

  Widget _numericinputField(
    String hintText,
    TextEditingController? controller,
  ) {
    return TextField(
      style: TextStyle(color: Colors.white),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(),
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

  Widget _dropdownField(
    String hintText,
    String? value,
    List<String> items,
    Function(String?) onChanged, {
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      hint: Text(hintText, style: TextStyle(color: Colors.white54)),
      value: value,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white54),
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
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _continueButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2E8B57),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async {
        if (nameController.text.isEmpty ||
            ageController.text.isEmpty ||
            weightController.text.isEmpty ||
            gender == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Please fill all the fields")));
          return;
        }

        final uid = FirebaseAuth.instance.currentUser!.uid;

        //  Convert height (feet + inches → cm)
        final heightInCm = ((feet * 30.48) + (inches * 2.54));

        //  Convert age → DOB (recommended)
        final age = int.parse(ageController.text);
        final dob = DateTime(DateTime.now().year - age);

        final user = UserProfile(
          uid: uid,
          name: nameController.text.trim(),
          // dob: dob,
          age: ageController.text.trim(),
          height: heightInCm,
          weight: double.parse(weightController.text),
          gender: gender!,
        );

        await StorageService.instance.saveUserProfile(user);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSignedIn', true);
        await prefs.setBool('ProfileCompleted', true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      },
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
