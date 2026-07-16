import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/botton_nav_provider.dart';
import 'package:tiies_attendance_app/Providers/break_provider.dart';
import 'package:tiies_attendance_app/Providers/checkIn_checkOut_provider.dart';
import 'package:tiies_attendance_app/Providers/firebase_auth_provider.dart';
import 'package:tiies_attendance_app/Providers/google_Map_Provider.dart';
import 'package:tiies_attendance_app/Providers/my_request_provider.dart';
import 'package:tiies_attendance_app/Providers/profile_provider.dart';
import 'package:tiies_attendance_app/Providers/team_provider.dart';
import 'package:tiies_attendance_app/firebase_options.dart';
import 'package:tiies_attendance_app/screens/bottom_navigation.dart';
import 'package:tiies_attendance_app/screens/login/login_screen.dart';

import 'Providers/activity_provider.dart';


void main() async {
  WidgetsBinding widgetsBinding =
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => GoogleMapProvider()),
        ChangeNotifierProvider(create: (_) => CheckInCheckoutProvider()),
        ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
        ChangeNotifierProvider(create: (_) => MyRequestProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => BreakProvider()),
        ChangeNotifierProvider(create: (_) => ActivityProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
      ],
      child: const MyApp(),
    ),
  );
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Widget? _startScreen;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _startScreen = const LoginScreen();
    } else {
      await _restoreCheckInState(user.uid);
      _startScreen = const BottomNavigation();
    }

    FlutterNativeSplash.remove();
    setState(() {});
  }

  Future<void> _restoreCheckInState(String uid) async {

    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final isCheckedIn = userData?['userCheckIn'] ?? false;
    final onBreak = userData?['onBreak'] ?? false;

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
      context.read<CheckInCheckoutProvider>()
          .fetchCheckInTime(checkInTime.toDate());

      context.read<BottomNavProvider>()
          .pageCheckIn();
    }

    if(onBreak ){
      final activeBreak = await Provider.of<BreakProvider>(context,listen: false).getActiveBreak();
      if (activeBreak != null && mounted) {
        Provider.of<BottomNavProvider>(context,listen: false).yesOnBreak(activeBreak);

      }
    }
  }

  @override
  Widget build(BuildContext context) {

    if (_startScreen == null) {
      return const SizedBox();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
        ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: _startScreen,
    );
  }
}


