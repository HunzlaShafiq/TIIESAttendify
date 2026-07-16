import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Profile data
  String _name = '';
  String _designation = '';
  String _email = '';
  String _phone = '';
  String _employeeId = '';
  String _department = '';
  DateTime? _joinDate;
  String _profileImageUrl = '';

  // State variables
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  // Getters
  String get name => _name;
  String get designation => _designation;
  String get email => _email;
  String get phone => _phone;
  String get employeeId => _employeeId;
  String get department => _department;
  DateTime? get joinDate => _joinDate;
  String get profileImageUrl => _profileImageUrl;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  // Get initials for avatar
  String get initials {
    if (_name.isEmpty) return '?';
    final nameParts = _name.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  // Get avatar color based on name
  Color get avatarColor {
    final colors = [
      const Color(0xff560542),
      const Color(0xff2E5A4C),
      const Color(0xff9E6B4D),
      const Color(0xff4A6FA5),
      const Color(0xffB83B5E),
    ];

    if (_name.isEmpty) return colors[0];

    // Generate consistent color based on name
    final index = _name.codeUnits.fold(0, (prev, element) => prev + element) % colors.length;
    return colors[index];
  }

  // Load user profile
  Future<void> loadUserProfile() async {
    _setLoading(true);
    _error = null;

    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      _email = user.email ?? '';
      _name = user.displayName ?? '';

      // Load from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        _name = data['userName'] ?? _name;
        _designation = data['userDesignation'] ?? 'Not specified';
        _phone = data['userPhone'] ?? 'Not specified';
        _employeeId = data['employeeId'] ?? 'EMP${user.uid.substring(0, 6)}';
                _profileImageUrl = data['profileImageUrl'] ?? '';

        if (data['userJoiningDate'] != null) {
          _joinDate = (data['userJoiningDate'] as Timestamp).toDate();
        }
      } else {
        // Create default profile for new users
        _employeeId = 'EMP${user.uid.substring(0, 6)}';
        _designation = 'Employee';
        _phone = 'Not specified';
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update profile
  Future<bool> updateProfile({
    required String name,
    required String designation,
    required String phone,
    String? department,
    DateTime? joinDate,
  }) async {
    _setSaving(true);
    _error = null;

    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');


      final Map<String, dynamic> updateData = {
        'userName': name,
        'userDesignation': designation,
        'userPhone': phone,

        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add joinDate to update if provided
      if (joinDate != null) {
        updateData['userJoiningDate'] = joinDate;
      }

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).set(
        updateData,
        SetOptions(merge: true),
      );

      // Update local state
      _name = name;
      _designation = designation;
      _phone = phone;
      if (department != null) _department = department;
      if (joinDate != null) _joinDate = joinDate;

      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      _setSaving(false);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _setSaving(false);
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}