import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/botton_nav_provider.dart';
import 'package:tiies_attendance_app/Providers/checkIn_checkOut_provider.dart';
import 'package:tiies_attendance_app/Providers/activity_provider.dart';
import '../../Providers/google_Map_Provider.dart';
import '../../Utils/Components/animatedCheckInOut.dart';
import '../../Utils/Constant/AppColors.dart';

class CheckOutScreen extends StatefulWidget {
  const CheckOutScreen({super.key});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Load activities
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
      _fabAnimationController.forward();
    });
  }

  Future<void> _loadActivities() async {
    final activityProvider = Provider.of<ActivityProvider>(context, listen: false);
    await activityProvider.loadTodayActivities();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: () {
            // Navigate to add activity screen or show bottom sheet
            _showAddActivitySheet(context);
          },
          backgroundColor: const Color(0xff560542),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Add Activity',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      appBar: AppBar(
        title: const Text(
          "TIIES Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors().mainColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          
              /// =================== HEADER ===================
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    "Time Clock",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          
              /// =================== TOP CARD ===================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<CheckInCheckoutProvider>(
                    builder: (_, provider, __) {
                      var placeName = Provider.of<GoogleMapProvider>(context, listen: false).currentPlaceName;
          
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            colors: [
                              AppColors().mainColor,
                              AppColors().mainColor.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
          
                            /// Location Row
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Current Location",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        placeName,
                                        style: const TextStyle(fontSize: 12, color: Colors.white),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
          
                            /// Timer
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                provider.formattedDuration(provider.totalWorkDuration),
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
          
                            /// Work Hours Footer
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF313149),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children:  [
                                  const Text(
                                    "Today Check-In Time",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  Text(
                                    provider.checkInTime != null
                                        ? DateFormat('hh:mm a').format(provider.checkInTime!)
                                        : "--",
                                    style: const TextStyle(color: Colors.cyanAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                ),
              ),

          
              /// =================== ACTIVITY CARD ===================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<ActivityProvider>(
                  builder: (context, activityProvider, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Header with refresh button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "My Day Activity",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: _loadActivities,
                                color: const Color(0xff560542),
                              ),
                            ],
                          ),
          
                          const SizedBox(height: 12),
          
                          /// Activity List
                          if (activityProvider.isLoading)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: Color(0xff560542),
                                ),
                              ),
                            )
                          else if (activityProvider.todayActivities.isEmpty)
                            _buildEmptyState()
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activityProvider.todayActivities.length > 5
                                  ? 5
                                  : activityProvider.todayActivities.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final activity = activityProvider.todayActivities[index];
                                return _buildActivityRow(activity);
                              },
                            ),
          
                          /// View all button if more than 5 activities
                          if (activityProvider.todayActivities.length > 5)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Center(
                                child: TextButton(
                                  onPressed: _showAllActivities,
                                  child: Text(
                                    'View all ${activityProvider.todayActivities.length} activities',
                                    style: const TextStyle(
                                      color: Color(0xff560542),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          
              /// =================== CHECK OUT BUTTON ===================
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: AnimatedCheckInOutButton(
                  buttonName: "CHECK-OUT",
                  isCheckIn: true,
                  onTap: () {
                    showCheckOutSheet(context);
                  },
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Center(
            child: Icon(
              Icons.assignment_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No activities yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add your first activity',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'task';
    final title = activity['title'] ?? 'Activity';
    final description = activity['description'] ?? '';
    final startTime = activity['startTime'] as DateTime?;
    final endTime = activity['endTime'] as DateTime?;

    // Get icon and color based on activity type
    final typeConfig = _getActivityTypeConfig(type);

    String timeDisplay = '';
    if (startTime != null) {
      if (endTime != null && endTime != startTime) {
        timeDisplay = '${DateFormat('hh:mm a').format(startTime)} - ${DateFormat('hh:mm a').format(endTime)}';
      } else {
        timeDisplay = DateFormat('hh:mm a').format(startTime);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          /// Activity icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: typeConfig['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              typeConfig['icon'],
              size: 18,
              color: typeConfig['color'],
            ),
          ),
          const SizedBox(width: 12),

          /// Activity details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (timeDisplay.isNotEmpty)
                  Text(
                    timeDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),

          /// Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: typeConfig['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: typeConfig['color'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getActivityTypeConfig(String type) {
    switch (type.toLowerCase()) {
      case 'check-in':
        return {
          'icon': Icons.login,
          'color': Colors.green,
        };
      case 'check-out':
        return {
          'icon': Icons.logout,
          'color': Colors.red,
        };
      case 'break':
        return {
          'icon': Icons.free_breakfast,
          'color': Colors.orange,
        };
      case 'meeting':
        return {
          'icon': Icons.meeting_room,
          'color': Colors.blue,
        };
      case 'task':
        return {
          'icon': Icons.task,
          'color': Colors.purple,
        };
      default:
        return {
          'icon': Icons.access_time,
          'color': Colors.grey,
        };
    }
  }

  void _showAllActivities() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<ActivityProvider>(
          builder: (context, activityProvider, child) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Today's Activities",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: activityProvider.todayActivities.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final activity = activityProvider.todayActivities[index];
                            return _buildActivityRow(activity);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddActivitySheet(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String selectedType = 'task';

    // Time selection variables
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    TimeOfDay selectedEndTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

    // Format time for display
    String formatTimeOfDay(TimeOfDay time) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
      return DateFormat('h:mm a').format(dt);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height *.8,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag indicator
                      Center(
                        child: Container(
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                  
                      // Header with icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xff560542).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_task,
                              color: Color(0xff560542),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            "Add New Activity",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff1a1a1a),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                  
                      // Activity Type Section
                      _buildSectionLabel("Activity Type"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: selectedType,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          ),
                          icon: Icon(Icons.arrow_drop_down, color: const Color(0xff560542)),
                          items: [
                            _buildDropdownItem('task', Icons.task, 'Task'),
                            _buildDropdownItem('meeting', Icons.meeting_room, 'Meeting'),
                            _buildDropdownItem('break', Icons.free_breakfast, 'Break'),
                            _buildDropdownItem('other', Icons.more_horiz, 'Other'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                  
                      // Title Section
                      _buildSectionLabel("Activity Title"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: titleController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "e.g., Client Meeting, Code Review",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(Icons.title, color: Colors.grey[500], size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                  
                      // Time Selection Section
                      _buildSectionLabel("Time Duration"),
                      const SizedBox(height: 8),
                  
                      // Start Time
                      _buildTimePickerRow(
                        label: "Start Time",
                        time: selectedStartTime,
                        icon: Icons.play_circle_outline,
                        color: Colors.green,
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedStartTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xff560542),
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedStartTime = picked;
                              // Auto-adjust end time if it's before start time
                              if (selectedEndTime.hour < picked.hour ||
                                  (selectedEndTime.hour == picked.hour && selectedEndTime.minute <= picked.minute)) {
                                selectedEndTime = picked.replacing(hour: picked.hour + 1);
                              }
                            });
                          }
                        },
                      ),
                  
                      const SizedBox(height: 8),
                  
                      // End Time
                      _buildTimePickerRow(
                        label: "End Time",
                        time: selectedEndTime,
                        icon: Icons.stop_circle_outlined,
                        color: Colors.red,
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: selectedEndTime,
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Color(0xff560542),
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            // Validate end time is after start time
                            if (picked.hour < selectedStartTime.hour ||
                                (picked.hour == selectedStartTime.hour && picked.minute <= selectedStartTime.minute)) {
                              _showErrorSnackBar(context, "End time must be after start time");
                              return;
                            }
                            setState(() {
                              selectedEndTime = picked;
                            });
                          }
                        },
                      ),
                  
                      const SizedBox(height: 20),
                  
                      // Description Section
                      _buildSectionLabel("Description (Optional)"),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextField(
                          controller: descriptionController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Add more details about this activity...",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                  
                      const SizedBox(height: 24),
                  
                      // Duration Summary (if both times selected)
                      if (selectedStartTime != null && selectedEndTime != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xff560542).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timer, size: 18, color: const Color(0xff560542)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _calculateDuration(selectedStartTime, selectedEndTime),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff560542),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  
                      const SizedBox(height: 20),
                  
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff560542),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                if (titleController.text.trim().isEmpty) {
                                  _showErrorSnackBar(context, "Please enter an activity title");
                                  return;
                                }
                  
                                // Combine date with time
                                final startDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedStartTime.hour,
                                  selectedStartTime.minute,
                                );
                  
                                final endDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  selectedEndTime.hour,
                                  selectedEndTime.minute,
                                );
                  
                                // Validate end time is after start time
                                if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
                                  _showErrorSnackBar(context, "End time must be after start time");
                                  return;
                                }
                  
                                final activityProvider = Provider.of<ActivityProvider>(
                                  context,
                                  listen: false,
                                );
                  
                                final success = await activityProvider.addActivity(
                                  type: selectedType,
                                  title: titleController.text.trim(),
                                  description: descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                                  startTime: startDateTime,
                                  endTime: endDateTime,
                                );
                  
                                if (success && context.mounted) {
                                  Navigator.pop(context);
                                  _showSuccessSnackBar(context, "Activity added successfully!");
                                }
                              },
                              child: const Text(
                                "Add Activity",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper method for section labels
  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
        letterSpacing: 0.3,
      ),
    );
  }

// Helper method for dropdown items with icons
  DropdownMenuItem<String> _buildDropdownItem(String value, IconData icon, String label) {
    return DropdownMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xff560542)),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

// Helper method for time picker rows
  Widget _buildTimePickerRow({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTimeOfDay(time),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1a1a1a),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.access_time,
              color: const Color(0xff560542),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

// Format TimeOfDay to string
  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

// Calculate duration between two times
  String _calculateDuration(TimeOfDay start, TimeOfDay end) {
    int startMinutes = start.hour * 60 + start.minute;
    int endMinutes = end.hour * 60 + end.minute;

    // Handle crossing midnight (though unlikely for daily activities)
    if (endMinutes < startMinutes) {
      endMinutes += 24 * 60;
    }

    int durationMinutes = endMinutes - startMinutes;
    int hours = durationMinutes ~/ 60;
    int minutes = durationMinutes % 60;

    if (hours > 0) {
      return 'Duration: $hours hr ${minutes > 0 ? '$minutes min' : ''}';
    } else {
      return 'Duration: $minutes minutes';
    }
  }

// Show error snackbar
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

// Show success snackbar
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void showCheckOutSheet(BuildContext context) {
    final provider = context.read<CheckInCheckoutProvider>();
    final activityProvider = context.read<ActivityProvider>();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Confirm Check-Out",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _infoTile(
                "Check-In Time",
                provider.checkInTime != null
                    ? DateFormat('hh:mm a').format(provider.checkInTime!)
                    : "--",
              ),
              _infoTile(
                "Total Work Today",
                provider.formattedDuration(provider.totalWorkDuration),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().mainColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () async {
                  // Add check-out activity
                  await activityProvider.addCheckOutActivity(
                    DateTime.now(),
                    provider.totalWorkDuration,
                  );

                  // Perform check-out
                  provider.checkOut();
                  Navigator.pop(context);
                  Provider.of<BottomNavProvider>(context, listen: false).pageCheckOut();
                },
                child: const Text(
                  "Confirm Check-Out",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}