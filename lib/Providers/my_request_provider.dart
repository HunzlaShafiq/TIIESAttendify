import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyRequestProvider extends ChangeNotifier {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isFetched = false;

  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _confirmed = [];
  List<Map<String, dynamic>> _rejected = [];

  List<Map<String, dynamic>> get pending => _pending;
  List<Map<String, dynamic>> get confirmed => _confirmed;
  List<Map<String, dynamic>> get rejected => _rejected;

  //=========================================================
  // Add Leave Request
  //=========================================================

  Future<void> addRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {

    try {

      _isLoading = true;
      notifyListeners();

      final user = FirebaseAuth.instance.currentUser!;

      final doc = _firestore.collection("myRequest").doc();

      await doc.set({

        "requestID": doc.id,
        "userID": user.uid,

        "startDate": Timestamp.fromDate(startDate),
        "endDate": Timestamp.fromDate(endDate),

        "reason": reason,

        "status": "pending",

        "createdAt": FieldValue.serverTimestamp(),

      });

      await fetchMyRequests(forceRefresh: true);

    } catch (e) {

      debugPrint(e.toString());

    } finally {

      _isLoading = false;
      notifyListeners();

    }

  }

  //=========================================================
  // Fetch Requests
  //=========================================================

  Future<void> fetchMyRequests({bool forceRefresh = false}) async {

    if (_isFetched && !forceRefresh) return;

    try {

      _isLoading = true;
      notifyListeners();

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final snapshot = await _firestore
          .collection("myRequest")
          .where("userID", isEqualTo: uid)
          .orderBy("createdAt", descending: true)
          .get();

      _pending.clear();
      _confirmed.clear();
      _rejected.clear();

      for (final doc in snapshot.docs) {

        final data = doc.data();

        switch (data["status"]) {

          case "pending":
            _pending.add(data);
            break;

          case "confirmed":
            _confirmed.add(data);
            break;

          case "rejected":
            _rejected.add(data);
            break;
        }

      }

      _isFetched = true;

    } catch (e) {

      debugPrint(e.toString());

    } finally {

      _isLoading = false;
      notifyListeners();

    }

  }

  //=========================================================
  // Withdraw Request
  //=========================================================

  Future<void> withdrawRequest(String requestID) async {

    try {

      await _firestore
          .collection("myRequest")
          .doc(requestID)
          .delete();

      _pending.removeWhere(
            (e) => e["requestID"] == requestID,
      );

      notifyListeners();

    } catch (e) {

      debugPrint(e.toString());

    }

  }

  //=========================================================
  // Refresh
  //=========================================================

  Future<void> refresh() async {

    await fetchMyRequests(forceRefresh: true);

  }

}