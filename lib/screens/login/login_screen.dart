import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/firebase_auth_provider.dart';
import '../forgot/forgot_screen.dart';
import '../signup/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return WillPopScope(

      onWillPop: () async{
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset('assets/Login.png',
                  height: height * .62, fit: BoxFit.cover),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height * .52,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF5B004F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text("Welcome to Tiies Attendify",
                          style: TextStyle(color: Colors.white, fontSize: 20)),

                      const SizedBox(height: 30),

                      buildField(Icons.email, "Email", email),

                      const SizedBox(height: 20),

                      buildPassword(),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ForgotScreen())),
                          child: const Text("Forgot password?", style: TextStyle(color: Colors.white)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Consumer<AuthenticationProvider>(
                        builder: (_, auth, __) {
                          return  ElevatedButton(
                            style: buttonStyle(),
                            onPressed: () {
                              if (email.text.isEmpty ||
                                  password.text.isEmpty) {
                                return showError(
                                    context, "All fields required");
                              }
                              if (!isEmailValid(email.text)) {
                                return showError(
                                    context, "Invalid email format");
                              }


                              auth.signIn(
                                context: context,
                                email: email.text,
                                password: password.text,
                              );
                            },
                            child:auth.loading
                                ? const CircularProgressIndicator(color: Colors.purple)
                                : const Text("Sign In",
                                style: TextStyle(
                                    color: Color(0xff1A124D),
                                    fontSize: 18)),
                          );
                        },
                      ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don’t have account?",
                              style: TextStyle(color: Colors.white70)),
                          TextButton(
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen())),
                            child: const Text("Sign Up",
                                style: TextStyle(color: Colors.white)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildField(IconData icon, String hint, TextEditingController c) {
    return TextField(
      controller: c,
      style: const TextStyle(color: Colors.white),
      decoration: inputDecoration(icon, hint),
    );
  }

  Widget buildPassword() {
    return TextField(
      controller: password,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: inputDecoration(Icons.key, "Password").copyWith(
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white),
          onPressed: () => setState(() => obscure = !obscure),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      enabledBorder:
      UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
      focusedBorder:
      const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
    );
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  bool isEmailValid(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }


  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

}
