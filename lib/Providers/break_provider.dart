import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'activity_provider.dart';

class BreakProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Break types
  static const Map<String, int> breakDurations = {
    'Quick break': 15,
    '1/2 hour': 30,
    '1 hour': 60,
    'Half day': 240,
    'Lunch/Dinner': 45,
    'Tea': 10,
    'Other': 0,
  };

  // State variables
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _todayBreaks = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get todayBreaks => _todayBreaks;

  // Helper method to convert Timestamp to DateTime
  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // Get today's breaks
  Future<void> loadTodayBreaks() async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('myDailyActivities')
          .doc(user.uid)
          .collection('breaks')
          .where('startTime', isGreaterThanOrEqualTo: startOfDay)
          .where('startTime', isLessThan: endOfDay)
          .orderBy('startTime', descending: true)
          .get();

      _todayBreaks = snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert timestamps to DateTime
        final Map<String, dynamic> processedData = {};
        data.forEach((key, value) {
          if (value is Timestamp) {
            processedData[key] = value.toDate();
          } else {
            processedData[key] = value;
          }
        });
        return {
          'id': doc.id,
          ...processedData,
        };
      }).toList();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Start a break
  Future<bool> startBreak(context,{
    required String type,
    String? reason,
    int? customDuration,
  }) async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final now = DateTime.now();
      final duration = customDuration ?? breakDurations[type] ?? 15;
      final endTime = now.add(Duration(minutes: duration));

      // Check if there's an active break
      final activeBreak = await _checkActiveBreak();
      if (activeBreak != null) {
        throw Exception('You already have an active break');
      }

      final breakData = {
        'type': type,
        'reason': reason ?? '',
        'startTime': now,
        'endTime': endTime,
        'duration': duration,
        'status': 'active',
        'userId': user.uid,
        'userName': user.displayName ?? 'Employee',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('myDailyActivities')
          .doc(user.uid)
          .collection('breaks')
          .add(breakData);

      await loadTodayBreaks();
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "onBreak":true
      });

      // In startBreak method after successful break start
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      await activityProvider.addBreakActivity(
        breakType: type,
        startTime: now,
        endTime: endTime,
        reason: reason,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // End a break
  Future<bool> endBreak(String breakId,context,breakType) async {
    _setLoading(true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final now = DateTime.now();

      await _firestore
          .collection('myDailyActivities')
          .doc(user.uid)
          .collection('breaks')
          .doc(breakId)
          .update({
        'status': 'completed',
        'actualEndTime': now,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await loadTodayBreaks();
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({
        "onBreak":false
      });

      // In endBreak method
      final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
      await activityProvider.addActivity(
        type: 'break-end',
        title: 'Break Ended',
        description: 'Completed $breakType break',
        startTime: DateTime.now(),
        endTime: DateTime.now(),
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Check for active break
  Future<Map<String, dynamic>?> _checkActiveBreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final snapshot = await _firestore
          .collection('myDailyActivities')
          .doc(user.uid)
          .collection('breaks')
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        // Convert timestamps to DateTime
        final Map<String, dynamic> processedData = {};
        data.forEach((key, value) {
          if (value is Timestamp) {
            processedData[key] = value.toDate();
          } else {
            processedData[key] = value;
          }
        });
        return {
          'id': snapshot.docs.first.id,
          ...processedData,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get active break
  Future<Map<String, dynamic>?> getActiveBreak() async {
    return _checkActiveBreak();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }




}