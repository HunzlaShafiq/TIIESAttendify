import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/firebase_auth_provider.dart';
import 'package:tiies_attendance_app/screens/login/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController otherDesignationController = TextEditingController();
  final TextEditingController confirm = TextEditingController();
  bool hide1 = true, hide2 = true;

  String? selectedDesignation;

  final List<String> designationOptions = [
    "Mobile App Developer",
    "Web Developer",
    "Artificial Intelligence",
    "Others",
  ];

  // ================= ERROR FUNCTION =================
  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // ================= INPUT DECORATION =================
  InputDecoration inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white54),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  // ================= COMMON FIELD =================
  Widget field(IconData icon, String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: inputDecoration(icon, hint),
      ),
    );
  }

  Widget passwordField(String h, TextEditingController c, bool hide,
      VoidCallback tap) => Padding(
    padding: const EdgeInsets.only(bottom: 15), child: TextField(
    controller: c,
    obscureText: hide,
    style: const TextStyle(color: Colors.white),
    decoration: inputDecoration(Icons.key, h).copyWith(suffixIcon: IconButton(
      icon: Icon(
          hide ? Icons.visibility_off : Icons.visibility, color: Colors.white),
      onPressed: tap,),),),);

  // ================= DESIGNATION DROPDOWN =================
  Widget designationDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        value: selectedDesignation,
        dropdownColor: const Color(0xFF5B004F),
        iconEnabledColor: Colors.white,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.badge, color: Colors.white),
          hintText: "Select Designation",
          hintStyle: TextStyle(color: Colors.white70,),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white54),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
        items: designationOptions
            .map(
              (item) => DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        )
            .toList(),
        onChanged: (value) {
          setState(() {
            selectedDesignation = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF5B004F),
      body: Stack(
        children: [
          Positioned(top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
                'assets/Login.png', height: h * .62, fit: BoxFit.cover),),
          Positioned(bottom: -60, left: 0, right: 0,
            child: Container(
              height: h * .75,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF5B004F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),),
              child: Consumer<AuthenticationProvider>(
                builder: (context, authProvider, child) {
                  return SingleChildScrollView(

                    child: Column(
                      children: [
                        const Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 15),

                        field(Icons.person, "Full Name", name),
                        field(Icons.email, "Email", email),
                        field(Icons.phone, "Phone Number", phone),
                        designationDropdown(),

                        // 👇 SHOW EXTRA FIELD IF OTHERS SELECTED
                        if (selectedDesignation == "Others")
                          field(Icons.edit, "Enter Your Designation",
                              otherDesignationController),
                        passwordField("Password", password, hide1, () =>
                            setState(() => hide1 = !hide1)),
                        passwordField("Confirm Password", confirm, hide2, () =>
                            setState(() => hide2 = !hide2)),


                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5B004F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: authProvider.loading
                                ? null
                                : () async {
                              // ================= VALIDATION =================
                              if (name.text.isEmpty ||
                                  email.text.isEmpty ||
                                  password.text.isEmpty ||
                                  phone.text.isEmpty ||
                                  selectedDesignation == null) {
                                return showError(
                                    context, "All fields are required");
                              }

                              if (selectedDesignation == "Others" &&
                                  otherDesignationController
                                      .text.isEmpty) {
                                return showError(context,
                                    "Please enter your designation");
                              }

                              String finalDesignation =
                              selectedDesignation == "Others"
                                  ? otherDesignationController.text
                                  : selectedDesignation!;

                              await authProvider.signUp(
                                name: name.text.trim(),
                                email: email.text.trim(),
                                password: password.text.trim(),
                                phone: phone.text.trim(),
                                designation: finalDesignation,
                                context: context,
                              );
                            },
                            child: authProvider.loading
                                ? const CircularProgressIndicator(
                              color: Color(0xFF5B004F),
                            )
                                : const Text(
                              "Sign Up",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),


                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("I already have account!",
                                style: TextStyle(color: Colors.white70)),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const LoginScreen())),
                              child: const Text("Sign In",
                                  style: TextStyle(color: Colors.white)),
                            )
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        ],
      )

    );
  }



}

