import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInCheckoutProvider with ChangeNotifier {

  CheckInCheckoutProvider() {
    _currentDateTime = DateTime.now(); // initialize
    startTimeUpdater();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCheckIn = false;
  bool get isCheckIn => _isCheckIn;

  late DateTime _currentDateTime; // fixed

  /// ================= ATTENDANCE =================
  DateTime? _checkInTime;
  Duration _totalWorkDuration = Duration.zero;

  DateTime? get checkInTime => _checkInTime;
  Duration get totalWorkDuration => _totalWorkDuration;

  Timer? _workTimer;
  Timer? _timeTimer;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
  
  Future<void> refreshCheckInData() async{

    final user = FirebaseAuth.instance.currentUser?.uid;
    var userData= await FirebaseFirestore.instance.collection("users").doc(user).get();
    var checkInStatus=userData.data()!["userCheckIn"];
    if(checkInStatus==true){

    }
    
  }



  // ================= CHECK IN =================
  Future<void> checkIn({required String location}) async {
    try {
      setLoading(true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

      final fireStore = FirebaseFirestore.instance;

      final docRef = fireStore
          .collection("Attendance")
          .doc(user.uid)
          .collection("Records")
          .doc(formattedDate);

      final snapshot = await docRef.get();
      if (snapshot.exists) {
        throw Exception("Already checked in today");
      }

      _checkInTime = now;
      _totalWorkDuration = Duration.zero;

      await docRef.set({
        "id": formattedDate,
        "checkInTime": now,
        "date": formattedDate,
        "location": location,
        "checkOutTime": null,
        "totalDuration": null,
        "createdAt": FieldValue.serverTimestamp(),
      });

      await fireStore
          .collection('users')
          .doc(user.uid)
          .update({"userCheckIn": true});

      _startWorkTimer();

    } catch (e) {
      debugPrint("CheckIn Error: $e");
    } finally {
      _isCheckIn=true;
      setLoading(false);
    }
  }

  // ================= CHECK OUT =================
  Future<void> checkOut() async {
    try {
      setLoading(true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _checkInTime == null) return;

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

      final fireStore = FirebaseFirestore.instance;

      final docRef = fireStore
          .collection("Attendance")
          .doc(user.uid)
          .collection("Records")
          .doc(formattedDate);

      _workTimer?.cancel();

      _totalWorkDuration = now.difference(_checkInTime!);

      await docRef.update({
        "checkOutTime": now,
        "totalDuration": _totalWorkDuration.inSeconds,
      });

      await fireStore
          .collection('users')
          .doc(user.uid)
          .update({"userCheckIn": false});

      _checkInTime = null;

    } catch (e) {
      debugPrint("CheckOut Error: $e");
    } finally {
      _isCheckIn=false;
      setLoading(false);
    }
  }

  // ================= WORK TIMER =================
  void _startWorkTimer() {
    _workTimer?.cancel();

    _workTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (_checkInTime == null) return;

        _totalWorkDuration =
            DateTime.now().difference(_checkInTime!);

        notifyListeners();
      },
    );
  }

  // ================= DATE & TIME =================
  void startTimeUpdater() {
    _timeTimer?.cancel();

    _timeTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        _currentDateTime = DateTime.now();
        notifyListeners();
      },
    );
  }

  String getFormattedDate() {
    return DateFormat('EEEE, MMM d, yyyy')
        .format(_currentDateTime);
  }

  String getFormattedTime(BuildContext context) {
    return TimeOfDay.fromDateTime(_currentDateTime)
        .format(context);
  }

  String formattedDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:"
        "${two(d.inMinutes % 60)}:"
        "${two(d.inSeconds % 60)}";
  }

  void fetchCheckInTime(DateTime time) {
    _checkInTime = time;
    _startWorkTimer();
    notifyListeners();
  }


  @override
  void dispose() {
    _workTimer?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }
}
