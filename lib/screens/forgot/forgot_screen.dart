import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/firebase_auth_provider.dart';


class ForgotScreen extends StatefulWidget {
  const ForgotScreen({super.key});

  @override
  State<ForgotScreen> createState() => _ForgotScreenState();
}

class _ForgotScreenState extends State<ForgotScreen> {
  final email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset('assets/Login.png',
                height: h * .62, fit: BoxFit.cover),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: h * .45,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF5B004F),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const Text("Reset Password",
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                  const SizedBox(height: 30),

                  TextField(
                    controller: email,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      prefixIcon:
                      Icon(Icons.email, color: Colors.white),
                      hintText: "Email",
                      hintStyle: TextStyle(color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Consumer<AuthenticationProvider>(
                    builder: (_, auth, __) {
                      return  ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize:
                            const Size(double.infinity, 50)),
                        onPressed: () {
                          if (email.text.isEmpty) {
                            return showError(
                                context, "Enter email");
                          }
                          if (!isEmailValid(email.text)) {
                            return showError(
                                context, "Invalid email");
                          }

                          auth.resetPassword(
                            context: context,
                            email: email.text,
                          );
                        },
                        child: auth.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Send Reset Link",
                            style: TextStyle(
                                color: Color(0xFF5B004F),
                                fontSize: 18)),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

// Back to Login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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

