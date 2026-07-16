import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/checkIn_checkOut_provider.dart';
import 'package:tiies_attendance_app/screens/bottom_navigation.dart';

class AuthenticationProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = false;
  bool get loading => _loading;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  // ================= FLASH MESSAGE =================

  void showMessage(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  // ================= SIGN UP =================

  Future<void> signUp({
    required BuildContext context,
    required String name,
    required String email,
    required String password,
    required String designation,
    required String phone,
  }) async {
    try {
      _setLoading(true);

      UserCredential user =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = user.user!.uid;


      await _firestore.collection("users").doc(uid).set({
        "userID": uid,
        "userName": name,
        "userEmail": email,
        "userDesignation": designation,
        "userJoiningDate": DateTime.now(),
        "userPhoneNumber": phone,
        "userProfileURL": "",
        "userCheckIn" : false,
        "onBreak" : false,
        "createdAt": FieldValue.serverTimestamp(),
      });


      showMessage(context, "Account created successfully 🎉");



    } on FirebaseAuthException catch (e) {
      showMessage(context, e.message ?? "Signup failed", error: true);
    } catch (e) {
      showMessage(context, "Something went wrong", error: true);
    } finally {
      _setLoading(false);
      Provider.of<CheckInCheckoutProvider>(context,listen: false);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>BottomNavigation()));
    }
  }

  // ================= SIGN IN =================

  Future<void> signIn({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>BottomNavigation()));
      showMessage(context, "Login successful ✅");

    } on FirebaseAuthException catch (e) {
      showMessage(context, e.message ?? "Login failed", error: true);
    } catch (e) {
      showMessage(context, "Something went wrong", error: true);
    } finally {
      _setLoading(false);
    }
  }

  // ================= FORGOT PASSWORD =================

  Future<void> resetPassword({
    required BuildContext context,
    required String email,
  }) async {
    try {
      _setLoading(true);

      await _auth.sendPasswordResetEmail(email: email.trim());

      showMessage(context, "Reset link sent to email 📩");

    } on FirebaseAuthException catch (e) {
      showMessage(context, e.message ?? "Failed to send link", error: true);
    } finally {
      _setLoading(false);
    }
  }
}
