import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../Providers/team_provider.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();

  // Map to store calculated work durations
  final Map<String, int> _workDurations = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: TeamProvider.teamCategories.length,
      vsync: this,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeamMembers();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final provider = Provider.of<TeamProvider>(context, listen: false);
        provider.selectCategory(TeamProvider.teamCategories[_tabController.index]);
      }
    });

    // Start timer to update work durations every minute
    _startWorkDurationTimer();
  }

  void _startWorkDurationTimer() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _updateAllWorkDurations();
        _startWorkDurationTimer(); // Restart timer
      }
    });
  }

  void _updateAllWorkDurations() {
    setState(() {
      // This will trigger rebuild with updated durations
    });
  }

  // Calculate work duration for a member
  int _calculateWorkDuration(Map<String, dynamic> member) {
    // If member is not checked in, return 0
    if (member['userCheckIn'] != true) return 0;

    // If member is on break, we might still show duration up to break start
    // For now, we'll continue counting even during break

    // Get check-in time from attendance records
    // For now, we'll use a placeholder - you'll need to fetch actual check-in time
    // This should come from your attendance collection
    final checkInTime = member['todayCheckInTime'];

    if (checkInTime == null) return 0;

    final now = DateTime.now();
    final duration = now.difference(checkInTime);

    // Return duration in seconds
    return duration.inSeconds;
  }

  Future<void> _loadTeamMembers() async {
    final provider = Provider.of<TeamProvider>(context, listen: false);
    await provider.loadTeamMembers();

    // After loading members, fetch check-in times for each member
    await _fetchCheckInTimes(provider.filteredMembers);

    _animationController.forward();
  }

  Future<void> _fetchCheckInTimes(List<Map<String, dynamic>> members) async {
    // This method should fetch today's check-in times from attendance collection
    // You'll need to implement this based on your data structure
    for (var member in members) {
      final userId = member['userID'];
      if (userId != null) {
        final now = DateTime.now();
        final todayDate = DateFormat('yyyy-MM-dd').format(now);

        final attendanceDoc = await FirebaseFirestore.instance
            .collection('Attendance')
            .doc(userId)
            .collection('Records')
            .doc(todayDate)
            .get();

        if (attendanceDoc.exists) {
          final checkInTime = (attendanceDoc['checkInTime'] as Timestamp?)?.toDate();
          member['todayCheckInTime'] = checkInTime;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final provider = Provider.of<TeamProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Team",
          style: TextStyle(
            color: Color(0xff1a1a1a),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: _buildCategoryChips(provider),
        ),
      ),
      body: provider.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xff560542),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadTeamMembers,
        color: const Color(0xff560542),
        child: provider.filteredMembers.isEmpty
            ? _buildEmptyState(provider.selectedCategory)
            : FadeTransition(
          opacity: _animationController,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.filteredMembers.length,
            itemBuilder: (context, index) {
              final member = provider.filteredMembers[index];
              return _buildMemberCard(member, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(TeamProvider provider) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TeamProvider.teamCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = TeamProvider.teamCategories[index];
          final isSelected = provider.selectedCategory == category;
          final memberCount = provider.getMemberCount(category);

          return GestureDetector(
            onTap: () {
              _tabController.animateTo(index);
              provider.selectCategory(category);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [Color(0xff560542), Color(0xff8E2A7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color: isSelected ? null : Colors.grey[50],
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xff560542).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ]
                          : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category icon
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.2)
                                : const Color(0xff560542).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _getCategoryIcon(category),
                            style: TextStyle(
                              fontSize: 16,
                              color: isSelected ? Colors.white : const Color(0xff560542),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Category name
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),

                        // Member count badge
                        if (memberCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.2)
                                  : const Color(0xff560542).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              memberCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xff560542),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Small indicator for selected
                  if (isSelected)
                    Positioned(
                      bottom: -4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xff560542),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String category) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated empty illustration
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circles
                        ...List.generate(3, (i) {
                          return Positioned(
                            child: Container(
                              width: 120 + (i * 30),
                              height: 120 + (i * 30),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xff560542).withOpacity(0.1 - (i * 0.03)),
                                  width: 1,
                                ),
                              ),
                            ),
                          );
                        }),

                        // Main icon
                        Icon(
                          _getCategoryIcon(category) == '👥'
                              ? Icons.people_outline
                              : Icons.devices_other,
                          size: 70,
                          color: const Color(0xff560542).withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Empty message
            Text(
              'No team members found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'There are no members in the "$category" category yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Illustration of team members
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Transform.translate(
                  offset: Offset(index * -8, 0),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xff560542).withOpacity(0.1 + (index * 0.05)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getCategoryIcon(category),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                );
              }).reversed.toList(),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member, int index) {
    final statusColor = Provider.of<TeamProvider>(context, listen: false)
        .getStatusColor(member);
    final statusText = Provider.of<TeamProvider>(context, listen: false)
        .getStatusText(member);
    final joinDate = member['userJoiningDate'] as DateTime?;

    // Calculate work duration
    final int workDurationSeconds = _calculateWorkDuration(member);
    final workHours = (workDurationSeconds / 3600).floor();
    final workMinutes = ((workDurationSeconds % 3600) / 60).floor();

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOutQuad,
      child: GestureDetector(
        onTap: () => _showMemberDetails(context, member),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Status indicator
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                  ),
                ),
              ),

              // Member info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Profile image with status dot
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: member['profileImage'] != null
                              ? NetworkImage(member['profileImage'])
                              : null,
                          child: member['profileImage'] == null
                              ? Text(
                            _getInitials(member['userName'] ?? ''),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff560542),
                            ),
                          )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Member details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member['userName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1a1a1a),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Show work duration only if checked in
                              if (member['userCheckIn'] == true && workDurationSeconds > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 10,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${workHours}h ${workMinutes}m',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member['userDesignation'] ?? 'No designation',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(statusText),
                                      size: 12,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      statusText,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (member['onBreak'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        Icons.free_breakfast,
                                        size: 10,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Break',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Color(0xff560542),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }

  void _showMemberDetails(BuildContext context, Map<String, dynamic> member) {
    final statusColor = Provider.of<TeamProvider>(context, listen: false)
        .getStatusColor(member);
    final statusText = Provider.of<TeamProvider>(context, listen: false)
        .getStatusText(member);
    final joinDate = member['userJoiningDate'] as DateTime?;

    // Calculate work duration
    final int workDurationSeconds = _calculateWorkDuration(member);
    final workHours = (workDurationSeconds / 3600).floor();
    final workMinutes = ((workDurationSeconds % 3600) / 60).floor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Drag indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12),
                      height: 4,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Profile header
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: member['profileImage'] != null
                                        ? NetworkImage(member['profileImage'])
                                        : null,
                                    child: member['profileImage'] == null
                                        ? Text(
                                      _getInitials(member['userName'] ?? ''),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff560542),
                                      ),
                                    )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                member['userName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff1a1a1a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff560542).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  member['userDesignation'] ?? 'No designation',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xff560542),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Status card with work duration
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatusChip(
                                    icon: Icons.login,
                                    label: 'Check In',
                                    value: member['userCheckIn'] == true ? 'Yes' : 'No',
                                    color: member['userCheckIn'] == true
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                  Container(
                                    height: 30,
                                    width: 1,
                                    color: Colors.grey[300],
                                  ),
                                  _buildStatusChip(
                                    icon: Icons.free_breakfast,
                                    label: 'On Break',
                                    value: member['onBreak'] == true ? 'Yes' : 'No',
                                    color: member['onBreak'] == true
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                ],
                              ),
                              if (member['userCheckIn'] == true && workDurationSeconds > 0) ...[
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.timer,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Today's Work",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          '$workHours hours $workMinutes minutes',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Contact information
                        _buildDetailSection(
                          title: 'Contact Information',
                          icon: Icons.contact_phone,
                          children: [
                            _buildDetailRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: member['userEmail'] ?? 'Not specified',
                            ),
                            _buildDetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: member['userPhoneNumber'] ?? member['userPhone'] ?? 'Not specified',
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Work information
                        _buildDetailSection(
                          title: 'Work Information',
                          icon: Icons.work_outline,
                          children: [
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Join Date',
                              value: joinDate != null
                                  ? DateFormat('dd MMMM yyyy').format(joinDate)
                                  : 'Not specified',
                            ),
                            _buildDetailRow(
                              icon: Icons.access_time,
                              label: 'Last Active',
                              value: member['updatedAt'] != null
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(
                                (member['updatedAt'] as DateTime).toLocal(),
                              )
                                  : 'Not available',
                            ),
                            _buildDetailRow(
                              icon: Icons.badge_outlined,
                              label: 'Employee ID',
                              value: member['userID']?.substring(0, 8) ?? 'N/A',
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Close button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff560542),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xff560542)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1a1a1a),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xff1a1a1a),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final nameParts = name.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Checked In':
        return Icons.login;
      case 'On Break':
        return Icons.free_breakfast;
      default:
        return Icons.circle;
    }
  }

  String _getCategoryIcon(String category) {
    switch (category) {
      case 'Mobile App Developer':
        return '📱';
      case 'Web Developer':
        return '💻';
      case 'Artificial Intelligence':
        return '🤖';
      default:
        return '👥';
    }
  }
}