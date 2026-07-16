import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/botton_nav_provider.dart';
import 'package:tiies_attendance_app/Providers/checkIn_checkOut_provider.dart';
import 'package:tiies_attendance_app/screens/bottom_navigation.dart';
import 'package:tiies_attendance_app/screens/login/login_screen.dart';
import 'package:intl/intl.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {

    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      await _getUserCheckStatus(user.uid);
    } catch (e) {
      debugPrint("Splash Error: $e");
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BottomNavigation()),
    );
  }

  Future<void> _getUserCheckStatus(String uid) async {

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final isCheckedIn = userData?['userCheckIn'] ?? false;

    if (!isCheckedIn) return;

    final attendanceDoc = await FirebaseFirestore.instance
        .collection('Attendance')
        .doc(uid)
        .collection('Records')
        .doc(today)
        .get();

    if (!attendanceDoc.exists) return;

    final checkInTime = attendanceDoc.data()?['checkInTime'];

    if (checkInTime != null) {
      Provider.of<CheckInCheckoutProvider>(
        context,
        listen: false,
      ).fetchCheckInTime(checkInTime.toDate());

      Provider.of<BottomNavProvider>(
        context,
        listen: false,
      ).pageCheckIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xff560542),
      body: Center(
        child: Image(
          width: 450,
          height: 450,
          image: AssetImage('assets/logo.png'),
        ),
      ),
    );
  }
}
