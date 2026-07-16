import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyRequestProvider with ChangeNotifier {

  MyRequestProvider(){
    fetchMyRequests();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _confirmed = [];
  List<Map<String, dynamic>> _rejected = [];

  bool _isLoading = false;

  List<Map<String, dynamic>> get pending => _pending;
  List<Map<String, dynamic>> get confirmed => _confirmed;
  List<Map<String, dynamic>> get rejected => _rejected;
  bool get isLoading => _isLoading;

  /// 🔥 ADD NEW REQUEST
  Future<void> addRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser!;
      final docRef = _firestore.collection('myRequest').doc();

      await docRef.set({
        'requestID': docRef.id,
        'userID': user.uid,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'reason': reason,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await fetchMyRequests();
    } catch (e) {
      debugPrint("Add Request Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 FETCH REQUESTS
  Future<void> fetchMyRequests() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      final snapshot = await _firestore
          .collection('myRequest')
          .where('userID', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      _pending.clear();
      _confirmed.clear();
      _rejected.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];

        if (status == 'pending') {
          _pending.add(data);
        } else if (status == 'confirmed') {
          _confirmed.add(data);
        } else {
          _rejected.add(data);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Fetch Request Error: $e");
    }
  }
}
