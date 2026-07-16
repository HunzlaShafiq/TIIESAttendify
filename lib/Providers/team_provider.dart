import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeamProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Team categories
  static const List<String> teamCategories = [
    "Mobile App Developer",
    "Web Developer",
    "Artificial Intelligence",
    "Others"
  ];

  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  String _selectedCategory = "Mobile App Developer";
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _selectedMember;

  // Getters
  List<Map<String, dynamic>> get filteredMembers => _filteredMembers;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get selectedMember => _selectedMember;

  // Helper method to convert Timestamp to DateTime
  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // Load all team members
  Future<void> loadTeamMembers() async {
    _setLoading(true);
    _error = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final snapshot = await _firestore.collection('users').get();

      _allMembers = snapshot.docs.map((doc) {
        final data = doc.data();

        // Process timestamps
        final Map<String, dynamic> processedData = {
          'id': doc.id,
          ...data,
        };

        // Convert timestamps
        if (data['userJoiningDate'] != null) {
          processedData['userJoiningDate'] = _toDateTime(data['userJoiningDate']);
        }
        if (data['updatedAt'] != null) {
          processedData['updatedAt'] = _toDateTime(data['updatedAt']);
        }
        if (data['lastActive'] != null) {
          processedData['lastActive'] = _toDateTime(data['lastActive']);
        }

        return processedData;
      }).toList();

      // Filter by selected category
      _filterMembers(_selectedCategory);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Filter members by category
  void _filterMembers(String category) {
    if (category == "Others") {
      _filteredMembers = _allMembers.where((member) {
        final designation = member['userDesignation'] ?? '';
        return !teamCategories.take(3).contains(designation);
      }).toList();
    } else {
      _filteredMembers = _allMembers.where((member) {
        return member['userDesignation'] == category;
      }).toList();
    }
    notifyListeners();
  }

  // Select category
  void selectCategory(String category) {
    if (_selectedCategory == category) return;

    _selectedCategory = category;
    _filterMembers(category);
    notifyListeners();
  }

  // Select member for details
  void selectMember(Map<String, dynamic> member) {
    _selectedMember = member;
    notifyListeners();
  }

  // Clear selected member
  void clearSelectedMember() {
    _selectedMember = null;
    notifyListeners();
  }

  // Get member count for category
  int getMemberCount(String category) {
    if (category == "Others") {
      return _allMembers.where((member) {
        final designation = member['userDesignation'] ?? '';
        return !teamCategories.take(3).contains(designation);
      }).length;
    }
    return _allMembers.where((member) => member['userDesignation'] == category).length;
  }

  // Get status color
  Color getStatusColor(Map<String, dynamic> member) {
    final isCheckedIn = member['userCheckIn'] == true;
    final isOnBreak = member['onBreak'] == true;

    if (isOnBreak) return Colors.orange;
    if (isCheckedIn) return Colors.green;
    return Colors.grey;
  }

  // Get status text
  String getStatusText(Map<String, dynamic> member) {
    final isCheckedIn = member['userCheckIn'] == true;
    final isOnBreak = member['onBreak'] == true;

    if (isOnBreak) return 'On Break';
    if (isCheckedIn) return 'Checked In';
    return 'Offline';
  }

  // Format join date
  String formatJoinDate(DateTime? date) {
    if (date == null) return 'Not specified';
    return DateFormat('dd MMM yyyy').format(date);
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