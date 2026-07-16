import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../Providers/botton_nav_provider.dart';
import '../../Providers/break_provider.dart';
import 'take_break.dart';

class ActiveBreakScreen extends StatefulWidget {
  final Map<String, dynamic> breakData;

  const ActiveBreakScreen({
    super.key,
    required this.breakData,
  });

  @override
  State<ActiveBreakScreen> createState() => _ActiveBreakScreenState();
}

class _ActiveBreakScreenState extends State<ActiveBreakScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  // Helper method to safely convert Timestamp to DateTime
  DateTime? _getDateTimeFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return null;
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Add timer to refresh every second
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _endBreak(breakType) async {
    final provider = Provider.of<BreakProvider>(context, listen: false);

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Break'),
        content: const Text('Are you sure you want to end your break?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff560542),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('End Break'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xff560542)),
        ),
      );

      await provider.endBreak(widget.breakData['id'] ?? '',context,breakType);
      Provider.of<BottomNavProvider>(context, listen: false).noOnBreak();


      Navigator.pop(context);

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

    // Safely convert timestamps to DateTime
    final startTime = _getDateTimeFromDynamic(widget.breakData['startTime']) ?? DateTime.now();
    final endTime = _getDateTimeFromDynamic(widget.breakData['endTime']) ?? DateTime.now().add(const Duration(minutes: 15));
    final duration = widget.breakData['duration'] ?? 15;
    final breakType = widget.breakData['type'] ?? 'Break';
    final reason = widget.breakData['reason'] ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Active Break',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xff1a1a1a),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [


            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Animated break icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: const Color(0xff560542).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xff560542).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getBreakIcon(breakType),
                            size: 60,
                            color: const Color(0xff560542),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Break type
                    Text(
                      breakType,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1a1a1a),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Timer
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _formatDuration(startTime, endTime),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff560542),
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'of $duration minutes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Break details
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.access_time,
                            'Started at',
                            _formatTime(startTime),
                          ),
                          const Divider(height: 20),
                          _buildDetailRow(
                            Icons.timer,
                            'Expected end',
                            _formatTime(endTime),
                          ),
                          if (reason.isNotEmpty) ...[
                            const Divider(height: 20),
                            _buildDetailRow(
                              Icons.message,
                              'Reason',
                              reason,
                            ),
                          ],
                        ],
                      ),
                    ),


                  ],
                ),
              ),
            ),
// End break button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 10),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (){
                    _endBreak(breakType);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'End Break',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xff1a1a1a),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final now = DateTime.now();
    final remaining = end.difference(now);

    if (remaining.isNegative) {
      return '00:00';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
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