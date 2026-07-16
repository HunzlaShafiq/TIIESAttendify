import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Providers/break_provider.dart';
import 'break_details.dart';
import 'active_break_screen.dart';

class TakeBreak extends StatefulWidget {
  const TakeBreak({super.key});

  @override
  State<TakeBreak> createState() => _TakeBreakState();
}

class _TakeBreakState extends State<TakeBreak> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward();

    // Check for active break
    _checkActiveBreak();
  }

  Future<void> _checkActiveBreak() async {
    final provider = Provider.of<BreakProvider>(context, listen: false);
    final activeBreak = await provider.getActiveBreak();

    if (activeBreak != null && mounted) {
      // Navigate to active break screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ActiveBreakScreen(breakData: activeBreak),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Take a Break"),
        centerTitle: true,

      ),

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 10),

                // Break Options Grid
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                  child: Column(
                    children: [
                      // Predefined breaks
                      _buildBreakOption(
                        title: "Lunch/Dinner",
                        duration: "45 min",
                        icon: Icons.lunch_dining,
                        color: const Color(0xff560542),
                        onTap: () => _navigateToBreakDetails('Lunch/Dinner'),
                      ),

                      const SizedBox(height: 16),

                      _buildBreakOption(
                        title: "Tea Break",
                        duration: "10 min",
                        icon: Icons.emoji_food_beverage,
                        color: const Color(0xff560542),
                        onTap: () => _navigateToBreakDetails('Tea'),
                      ),

                      const SizedBox(height: 16),

                      _buildBreakOption(
                        title: "Other Break",
                        duration: "Custom",
                        icon: Icons.more_horiz,
                        color: const Color(0xff560542),
                        onTap: () => _navigateToBreakDetails('Other'),
                      ),

                      const SizedBox(height: 15),

                      // Quick break grid
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children:[
                            Align(
                              alignment:Alignment.center,
                              child: Image.asset(
                                'assets/pic1.png',
                                height: 150,
                                fit: BoxFit.contain,

                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Quick Breaks",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff1a1a1a),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.5,
                                  children: [
                                    _buildQuickBreakButton("Quick break", "15 min"),
                                    _buildQuickBreakButton("1/2 hour", "30 min"),
                                    _buildQuickBreakButton("1 hour", "60 min"),
                                    _buildQuickBreakButton("Half day", "4 hours"),
                                  ],
                                ),
                              ],
                            ),

                          ]

                        ),
                      ),

                      const SizedBox(height: 5),

                      // Today's break summary
                      Consumer<BreakProvider>(
                        builder: (context, provider, child) {
                          if (provider.todayBreaks.isEmpty) {
                            return const SizedBox();
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xff560542).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xff560542).withOpacity(0.1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff560542).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.timer,
                                    color: Color(0xff560542),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Today's Breaks",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xff1a1a1a),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${provider.todayBreaks.length} break(s) taken",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom Image

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreakOption({
    required String title,
    required String duration,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickBreakButton(String title, String duration) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToBreakDetails(title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1a1a1a),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBreakDetails(String breakType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BreakDetails(breakType: breakType),
      ),
    );
  }
}