import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ActivityProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _todayActivities = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get todayActivities => _todayActivities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Helper method to convert Timestamp to DateTime
  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // Load today's activities
  Future<void> loadTodayActivities() async {
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
          .collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .orderBy('timestamp', descending: true)
          .get();

      _todayActivities = snapshot.docs.map((doc) {
        final data = doc.data();

        // Convert timestamps
        final Map<String, dynamic> processedData = {
          'id': doc.id,
          ...data,
        };

        if (data['timestamp'] != null) {
          processedData['timestamp'] = _toDateTime(data['timestamp']);
        }
        if (data['startTime'] != null) {
          processedData['startTime'] = _toDateTime(data['startTime']);
        }
        if (data['endTime'] != null) {
          processedData['endTime'] = _toDateTime(data['endTime']);
        }

        return processedData;
      }).toList();

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Add a new activity
  Future<bool> addActivity({
    required String type,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final activityData = {
        'type': type, // 'check-in', 'break', 'meeting', 'task', etc.
        'title': title,
        'description': description ?? '',
        'startTime': startTime,
        'endTime': endTime,
        'location': location ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userName': user.displayName ?? 'Employee',
      };

      await _firestore
          .collection('myDailyActivities')
          .doc(user.uid)
          .collection('activities')
          .add(activityData);

      await loadTodayActivities(); // Reload activities
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Update check-in activity
  Future<void> addCheckInActivity(DateTime checkInTime, String location) async {
    await addActivity(
      type: 'check-in',
      title: 'Check In',
      description: 'Started work',
      startTime: checkInTime,
      endTime: checkInTime,
      location: location,
    );
  }

  // Update check-out activity
  Future<void> addCheckOutActivity(DateTime checkOutTime, Duration totalDuration) async {
    await addActivity(
      type: 'check-out',
      title: 'Check Out',
      description: 'Completed work - Total: ${_formatDuration(totalDuration)}',
      startTime: checkOutTime,
      endTime: checkOutTime,
    );
  }

  // Add break activity
  Future<void> addBreakActivity({
    required String breakType,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
  }) async {
    await addActivity(
      type: 'break',
      title: breakType,
      description: reason ?? 'Break taken',
      startTime: startTime,
      endTime: endTime,
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours hr ${minutes} min';
    }
    return '$minutes min';
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