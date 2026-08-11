import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../Providers/my_request_provider.dart';

class MyRequest extends StatefulWidget {
  const MyRequest({super.key});

  @override
  State<MyRequest> createState() => _MyRequestState();
}

class _MyRequestState extends State<MyRequest>
    with TickerProviderStateMixin {

  late TabController _tabController;

  final TextEditingController _reasonController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickStartDate(StateSetter setSheetState) async {

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (date != null) {
      setSheetState(() {
        _startDate = date;

        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate(StateSetter setSheetState) async {

    if (_startDate == null) return;

    final date = await showDatePicker(
      context: context,
      firstDate: _startDate!,
      lastDate: DateTime(2035),
      initialDate: _startDate!,
    );

    if (date != null) {
      setSheetState(() {
        _endDate = date;
      });
    }
  }

// 🔥 Professional BottomSheet with StatefulBuilder - FIXED
  void _showAddRequestSheet(BuildContext context) {
    final provider = context.read<MyRequestProvider>();

    // Move state variables outside the builder to persist
    DateTime? startDate;
    DateTime? endDate;
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with drag indicator
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      "New Leave Request",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff1a1a1a),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Fill in the details for your leave request",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start Date Card - now shows selected date
                    _buildDateCard(
                      label: "Start Date",
                      date: startDate,
                      icon: Icons.event_available,
                      color: const Color(0xff560542),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: startDate ?? DateTime.now(),
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
                            startDate = picked;
                            // Optional: Auto-set end date to same as start if not set
                            if (endDate == null || endDate!.isBefore(picked)) {
                              endDate = picked;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // End Date Card - now shows selected date
                    _buildDateCard(
                      label: "End Date",
                      date: endDate,
                      icon: Icons.event_busy,
                      color: const Color(0xff560542),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: startDate ?? DateTime.now(),
                          lastDate: DateTime(2100),
                          initialDate: endDate ?? startDate ?? DateTime.now(),
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
                            endDate = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Reason Field with character count
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: reasonController,
                            maxLines: 3,
                            maxLength: 200,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: "Enter your reason for leave",
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              counterText: '', // Hide default counter
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: Icon(Icons.message, color: Colors.grey[400], size: 20),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {}); // Update UI for character count
                            },
                          ),
                          // Custom character counter
                          Padding(
                            padding: const EdgeInsets.only(right: 16, bottom: 8),
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${reasonController.text.length}/200',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: reasonController.text.length > 180
                                      ? Colors.orange
                                      : Colors.grey[500],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary section when dates are selected
                    if (startDate != null && endDate != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff560542).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xff560542).withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xff560542).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time,
                                color: Color(0xff560542),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Leave duration: ${_calculateDays(startDate!, endDate!)} days',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff560542),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff560542),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (startDate == null ||
                              endDate == null ||
                              reasonController.text.trim().isEmpty) {
                            _showValidationError(context);
                            return;
                          }

                          try {
                            await provider.addRequest(
                              startDate: startDate!,
                              endDate: endDate!,
                              reason: reasonController.text.trim(),
                            );

                            Navigator.pop(context);
                            _showSuccessMessage(context);
                          } catch (e) {
                            _showErrorMessage(context, e.toString());
                          }
                        },
                        child: const Text(
                          "Submit Request",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper method for date cards
  Widget _buildDateCard({
    required String label,
    required DateTime? date,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: date != null ? color.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: date != null ? color.withOpacity(0.3) : Colors.grey[200]!,
            width: date != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: date != null ? color.withOpacity(0.1) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: date != null ? color : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: date != null ? color : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? _formatDate(date)
                        : "Select date",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                      color: date != null ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: date != null ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: date != null ? color : Colors.grey[400],
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper method to format date
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

// Helper method to calculate days between dates
  int _calculateDays(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

// Helper methods for messages
  void _showValidationError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Please fill in all fields"),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text("Leave request submitted successfully!"),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text("Error: $error")),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


@override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MyRequestProvider>().fetchMyRequests();
    });
  }

  @override
  void dispose() {

    _tabController.dispose();
    _reasonController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRequestProvider>(
      builder: (_, provider, child) {
        return Scaffold(

          backgroundColor: const Color(0xffF6F7FB),

          floatingActionButton: FloatingActionButton.extended(

            backgroundColor: const Color(0xff560542),

            icon: const Icon(Icons.add, color: Colors.white),

            label: const Text(
              "New Leave",
              style: TextStyle(color: Colors.white),
            ),

            onPressed: () {
              _showAddRequestSheet(context);
            },

          ),

          appBar: AppBar(

            elevation: 0,

            backgroundColor: Colors.white,

            centerTitle: true,

            title: const Text(

              "My Leave Requests",

              style: TextStyle(

                color: Colors.black,

                fontWeight: FontWeight.bold,

              ),

            ),

            bottom: TabBar(

              controller: _tabController,

              labelColor: const Color(0xff560542),

              unselectedLabelColor: Colors.grey,

              indicatorColor: const Color(0xff560542),

              tabs: [

                Tab(

                  text:
                  "Pending (${provider.pending.length})",

                ),

                Tab(

                  text:
                  "Approved (${provider.confirmed.length})",

                ),

                Tab(

                  text:
                  "Rejected (${provider.rejected.length})",

                ),

              ],

            ),

          ),

          body: provider.isLoading

              ? const Center(

            child: CircularProgressIndicator(color: Color(0xff560542),),

          )

              : TabBarView(

            controller: _tabController,

            children: [

              _requestList(provider.pending, true),

              _requestList(provider.confirmed, false),

              _requestList(provider.rejected, false),

            ],

          ),

        );
      },
    );
  }

  Widget _requestList(List<Map<String, dynamic>> list,
      bool pending,) {
    if (list.isEmpty) {
      return RefreshIndicator(

        onRefresh: () =>
            context
                .read<MyRequestProvider>()
                .refresh(),

        child: ListView(

          children: [

            SizedBox(height: 150),

            Icon(Icons.inbox,
                size: 80,
                color: Colors.grey),

            SizedBox(height: 15),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.assignment_outlined,
                    size: 90,
                    color: Colors.grey.shade400,
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "No Leave Requests",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Tap + New Leave to submit\nyour first request.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            )

          ],

        ),

      );
    }

    return RefreshIndicator(

      color: const Color(0xff560542),

      onRefresh: () =>
          context
              .read<MyRequestProvider>()
              .refresh(),

      child: ListView.builder(

        padding: const EdgeInsets.all(16),

        itemCount: list.length,

        itemBuilder: (_, index) {
          final request = list[index];

          return _requestCard(
              request,
              pending
          );
        },

      ),

    );
  }

  Widget _requestCard(Map<String, dynamic> data,
      bool pending,) {
    final start = (data['startDate']).toDate();

    final end = (data['endDate']).toDate();

    final days = end
        .difference(start)
        .inDays + 1;

    Color statusColor;
    Color statusBackground;
    IconData statusIcon;

    switch (data['status']) {

      case "confirmed":

        statusColor = Colors.green;
        statusBackground = Colors.green.shade50;
        statusIcon = Icons.check_circle;

        break;

      case "rejected":

        statusColor = Colors.red;
        statusBackground = Colors.red.shade50;
        statusIcon = Icons.cancel;

        break;

      default:

        statusColor = Colors.orange;
        statusBackground = Colors.orange.shade50;
        statusIcon = Icons.schedule;
    }

    return InkWell(

      onTap: pending
          ? () => _showWithdrawBottomSheet(data)
          : null,

      borderRadius: BorderRadius.circular(18),

      child: Container(

        margin: const EdgeInsets.only(bottom: 18),

        padding: const EdgeInsets.all(18),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: [

            BoxShadow(

              color: Colors.grey.shade200,

              blurRadius: 12,

              offset: const Offset(0, 5),

            )

          ],

        ),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Container(

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(

                    color:
                    statusColor.withOpacity(.12),

                    shape: BoxShape.circle,

                  ),

                  child: Icon(

                    Icons.event,

                    color: statusColor,

                  ),

                ),

                const SizedBox(width: 15),

                Expanded(

                  child: Column(

                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [

                      Text(

                        DateFormat("dd MMM yyyy")
                            .format(start),

                        style: const TextStyle(

                          fontWeight:
                          FontWeight.bold,

                          fontSize: 16,

                        ),

                      ),

                      Text(

                        "${DateFormat("dd MMM").format(start)}  -  ${DateFormat(
                            "dd MMM").format(end)}",

                        style: TextStyle(

                          color: Colors.grey.shade600,

                        ),

                      ),

                    ],

                  ),

                ),

                Container(

                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6),

                  decoration: BoxDecoration(

                    color:
                    statusColor.withOpacity(.12),

                    borderRadius:
                    BorderRadius.circular(30),

                  ),

                  child: Text(

                    data['status']
                        .toString()
                        .toUpperCase(),

                    style: TextStyle(

                      color: statusColor,

                      fontWeight:
                      FontWeight.bold,

                    ),

                  ),

                )

              ],

            ),

            const SizedBox(height: 18),

            Text(

              data['reason'],

              style: const TextStyle(

                fontSize: 15,

                height: 1.5,

              ),

            ),

            const SizedBox(height: 18),

            Row(

              children: [

                const Icon(Icons.schedule,
                    size: 18),

                const SizedBox(width: 6),

                Text("$days Day Leave"),

                if(pending)...[

                  const Spacer(),

                  const Icon(Icons.touch_app,
                      color: Color(0xff560542)),

                  const SizedBox(width: 5),

                  const Text(

                    "Tap to withdraw",

                    style: TextStyle(

                      color: Color(0xff560542),

                      fontWeight: FontWeight.w600,

                    ),

                  ),

                ]

              ],

            )

          ],

        ),

      ),

    );
  }
  void _showWithdrawBottomSheet(Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              const SizedBox(height: 22),

              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.red.shade50,
                child: Icon(
                  Icons.delete_outline,
                  size: 34,
                  color: Colors.red.shade600,
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "Withdraw Leave",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "This leave request is still pending.\nYou can withdraw it now.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Withdraw Request"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmWithdraw(request);
                  },
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),

            ],
          ),
        );
      },
    );
  }

  void _confirmWithdraw(Map<String, dynamic> request) {

    showDialog(
      context: context,
      builder: (_) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),

          title: const Text(
            "Withdraw Application?",
          ),

          content: const Text(
            "Are you sure you want to withdraw this leave application?",
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("No"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {

                Navigator.pop(context);

                await context
                    .read<MyRequestProvider>()
                    .withdrawRequest(
                  request['requestID'],
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(

                  SnackBar(

                    behavior: SnackBarBehavior.floating,

                    backgroundColor: Colors.green,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    content: const Row(
                      children: [

                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),

                        SizedBox(width: 10),

                        Expanded(
                          child: Text(
                            "Leave request withdrawn successfully.",
                          ),
                        ),

                      ],
                    ),
                  ),
                );
              },
              child: const Text("Withdraw"),
            ),

          ],
        );
      },
    );
  }
}


