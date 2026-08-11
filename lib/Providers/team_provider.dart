import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TeamProvider extends ChangeNotifier {

  TeamProvider(){
    loadTeamMembers();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Team categories
  static const List<String> teamCategories = [
    "Mobile App Developer",
    "Web Developer",
    "Artificial Intelligence",
    "Others"
  ];

  // Cache control
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);
  static bool _isDataLoaded = false;

  // Data storage
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  Map<String, List<Map<String, dynamic>>> _categoryCache = {};

  String _selectedCategory = "Mobile App Developer";
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _error;
  Map<String, dynamic>? _selectedMember;

  // Getters
  List<Map<String, dynamic>> get filteredMembers => _filteredMembers;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  bool get isInitialLoad => _isInitialLoad;
  String? get error => _error;
  Map<String, dynamic>? get selectedMember => _selectedMember;
  bool get hasData => _allMembers.isNotEmpty;

  // Helper method to convert Timestamp to DateTime
  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  // Check if cache is valid
  bool _isCacheValid() {
    if (!_isDataLoaded) return false;
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  // Load team members with caching
  Future<void> loadTeamMembers({bool forceRefresh = false}) async {
    // Return cached data if valid
    if (!forceRefresh && _isCacheValid()) {
      _filterMembers(_selectedCategory);
      _isInitialLoad = false;
      return;
    }

    // Check if data is already loading
    if (_isLoading) return;

    _setLoading(true);
    _error = null;

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('No user logged in');

      final snapshot = await _firestore.collection('users').get();

      // Process and cache data
      _allMembers = snapshot.docs.map((doc) {
        final data = doc.data();
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

      // Cache by category for faster filtering
      _buildCategoryCache();

      // Update last fetch time
      _lastFetchTime = DateTime.now();
      _isDataLoaded = true;
      _isInitialLoad = false;

      // Filter by selected category
      _filterMembers(_selectedCategory);

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  // Build category cache for faster filtering
  void _buildCategoryCache() {
    _categoryCache.clear();

    // Initialize categories
    for (String category in teamCategories) {
      _categoryCache[category] = [];
    }

    // Group members by category
    for (var member in _allMembers) {
      final designation = member['userDesignation'] ?? '';
      String category = designation;

      if (!teamCategories.take(3).contains(designation)) {
        category = "Others";
      }

      if (_categoryCache.containsKey(category)) {
        _categoryCache[category]!.add(member);
      }
    }
  }

  // Filter members by category
  void _filterMembers(String category) {
    if (_categoryCache.containsKey(category)) {
      _filteredMembers = List.from(_categoryCache[category] ?? []);
    } else {
      // Fallback filtering
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
    }
    notifyListeners();
  }

  // Select category
  void selectCategory(String category) {
    if (_selectedCategory == category) return;

    _selectedCategory = category;

    // Use cache if available
    if (_categoryCache.containsKey(category)) {
      _filteredMembers = List.from(_categoryCache[category] ?? []);
      notifyListeners();
    } else {
      _filterMembers(category);
    }
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
    if (_categoryCache.containsKey(category)) {
      return _categoryCache[category]!.length;
    }

    // Fallback calculation
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

  // Force refresh data
  Future<void> refreshData() async {
    await loadTeamMembers(forceRefresh: true);
  }

  // Clear cache
  void clearCache() {
    _isDataLoaded = false;
    _lastFetchTime = null;
    _allMembers.clear();
    _filteredMembers.clear();
    _categoryCache.clear();
    _isInitialLoad = true;
    notifyListeners();
  }

  // Check if data needs refresh
  bool needsRefresh() {
    return !_isCacheValid();
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