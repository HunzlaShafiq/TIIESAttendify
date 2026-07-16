import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:tiies_attendance_app/Providers/botton_nav_provider.dart';

import '../../Providers/break_provider.dart';
import 'active_break_screen.dart';

class BreakDetails extends StatefulWidget {
  final String breakType;

  const BreakDetails({
    super.key,
    required this.breakType,
  });

  @override
  State<BreakDetails> createState() => _BreakDetailsState();
}

class _BreakDetailsState extends State<BreakDetails> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  TimeOfDay? _selectedTime;
  int? _selectedDuration; // Store selected duration in minutes
  bool _isCustomTime = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Set default time to now
    final now = TimeOfDay.now();
    _selectedTime = now;
    _timeController.text = _formatTimeOfDay(now);

    // Set default duration for "Other" breaks
    if (widget.breakType == 'Other') {
      _selectedDuration = 15; // Default to 15 minutes
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _reasonController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xff560542),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _timeController.text = _formatTimeOfDay(picked);
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  Future<void> _startBreak() async {
    final provider = Provider.of<BreakProvider>(context, listen: false);

    // Validate for "Other" breaks
    if (widget.breakType == 'Other' && _selectedDuration == null) {
      _showErrorSnackBar('Please select a break duration');
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xff560542)),
      ),
    );

    final success = await provider.startBreak(context,
      type: widget.breakType,
      reason: _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
      customDuration: widget.breakType == 'Other' ? _selectedDuration : null,
    );

    if (!mounted) return;

    Navigator.pop(context); // Remove loading dialog

    if (success) {
      Navigator.pop(context);
      // Get the active break and navigate
      final activeBreak = await provider.getActiveBreak();
      if (activeBreak != null && mounted) {
        Provider.of<BottomNavProvider>(context, listen: false).yesOnBreak(activeBreak);
              }
    } else {
      _showErrorSnackBar(provider.error ?? 'Failed to start break');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = Provider.of<BreakProvider>(context);
    final duration = widget.breakType == 'Other'
        ? (_selectedDuration ?? 15)
        : (BreakProvider.breakDurations[widget.breakType] ?? 15);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios, color: Color(0xff560542)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),

                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xff560542).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getBreakIcon(widget.breakType),
                                size: 50,
                                color: const Color(0xff560542),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              widget.breakType,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1a1a1a),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.breakType == 'Other'
                                  ? 'Custom break duration'
                                  : 'Duration: $duration minutes',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (widget.breakType == 'Other' && _selectedDuration != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Selected: $_selectedDuration minutes',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff560542),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Time selection (for Other breaks)
                      if (widget.breakType == 'Other') ...[
                        _buildSectionTitle("Break Duration"),
                        const SizedBox(height: 12),
                        _buildDurationSelector(),
                        const SizedBox(height: 24),
                      ],

                      // Time picker
                      _buildSectionTitle("Start Time"),
                      const SizedBox(height: 12),
                      _buildTimePicker(),

                      const SizedBox(height: 24),

                      // Reason field
                      _buildSectionTitle("Reason (Optional)"),
                      const SizedBox(height: 12),
                      _buildReasonField(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: "Cancel",
                          onTap: () => Navigator.pop(context),
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          label: "Start Break",
                          onTap: _startBreak,
                          isLoading: provider.isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xff1a1a1a),
      ),
    );
  }

  Widget _buildDurationSelector() {
    final List<Map<String, dynamic>> durationOptions = [
      {'label': '15 minutes', 'minutes': 15},
      {'label': '30 minutes', 'minutes': 30},
      {'label': '1 hour', 'minutes': 60},
      {'label': '2 hours', 'minutes': 120},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: durationOptions.map((option) {
          return _buildDurationOption(
            option['label'],
            option['minutes'],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationOption(String label, int minutes) {
    final isSelected = _selectedDuration == minutes;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = minutes;
          _isCustomTime = true;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xff560542).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xff560542)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xff560542)
                      : Colors.grey[800],
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xff560542),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: const Color(0xff560542),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Start Time",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeController.text.isEmpty
                        ? "Select time"
                        : _timeController.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _timeController.text.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                      color: _timeController.text.isEmpty
                          ? Colors.grey[400]
                          : const Color(0xff1a1a1a),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 3,
        maxLength: 200,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: "Enter reason for break (optional)",
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    bool isOutlined = false,
    bool isLoading = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey[600],
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff560542),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getBreakIcon(String breakType) {
    switch (breakType) {
      case 'Lunch/Dinner':
        return Icons.lunch_dining;
      case 'Tea':
        return Icons.emoji_food_beverage;
      case 'Other':
        return Icons.more_horiz;
      case 'Quick break':
        return Icons.timer;
      case '1/2 hour':
        return Icons.timer_10;
      case '1 hour':
        return Icons.timer_10_select;
      case 'Half day':
        return Icons.wb_sunny;
      default:
        return Icons.free_breakfast;
    }
  }
}