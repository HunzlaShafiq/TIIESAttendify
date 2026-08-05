import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Providers/botton_nav_provider.dart';
import '../../Providers/profile_provider.dart';
import '../login/login_screen.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  bool isEdit = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController designationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  // Join date controller
  DateTime? _selectedJoinDate;

  // Work duration
  String _totalWorkDuration = '';
  Timer? _workDurationTimer;

  @override
  void initState() {
    super.initState();

    // Initialize animations
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {

    // Calculate initial work duration
    _calculateWorkDuration();

    // Start timer to update work duration every minute
    _startWorkDurationTimer();

    _animationController.forward();
  }

  void _startWorkDurationTimer() {
    _workDurationTimer?.cancel();
    _workDurationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _calculateWorkDuration();
      }
    });
  }

  void _calculateWorkDuration() {
    if (_selectedJoinDate != null) {
      final now = DateTime.now();
      final difference = now.difference(_selectedJoinDate!);

      final years = (difference.inDays / 365).floor();
      final months = ((difference.inDays % 365) / 30).floor();
      final days = (difference.inDays % 365) % 30;

      String duration = '';
      if (years > 0) {
        duration += '$years ${years == 1 ? 'year' : 'years'}';
      }
      if (months > 0) {
        if (duration.isNotEmpty) duration += ' ';
        duration += '$months ${months == 1 ? 'month' : 'months'}';
      }
      if (days > 0 && years == 0) {
        if (duration.isNotEmpty) duration += ' ';
        duration += '$days ${days == 1 ? 'day' : 'days'}';
      }

      if (duration.isEmpty) {
        duration = 'Less than a day';
      }

      setState(() {
        _totalWorkDuration = duration;
      });
    } else {
      setState(() {
        _totalWorkDuration = 'Not available';
      });
    }
  }

  @override
  void dispose() {
    _workDurationTimer?.cancel();
    _animationController.dispose();
    nameController.dispose();
    designationController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectJoinDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
        _selectedJoinDate = picked;
        _calculateWorkDuration(); // Recalculate when join date changes
      });
    }
  }

  Future<void> _handleUpdate() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    final success = await provider.updateProfile(
      name: nameController.text.trim(),
      designation: designationController.text.trim(),
      phone: phoneController.text.trim(),
      joinDate: _selectedJoinDate,
    );

    if (success && mounted) {
      setState(() {
        isEdit = false;
      });

      _showSnackBar(
        'Profile updated successfully!',
        Colors.green,
      );
    } else if (mounted) {
      _showSnackBar(
        provider.error ?? 'Failed to update profile',
        Colors.red,
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        Provider.of<BottomNavProvider>(context).updateIndex(0);
      }
    }
  }

  // Change Password Function
  Future<void> _changePassword() async {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
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
                      const SizedBox(height: 20),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xff560542).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_outline,
                                color: Color(0xff560542),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            // Old Password
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: oldPasswordController,
                                obscureText: obscureOldPassword,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Current Password',
                                  labelStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.lock, color: Color(0xff560542)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[500],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureOldPassword = !obscureOldPassword;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // New Password
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: newPasswordController,
                                obscureText: obscureNewPassword,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  labelStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xff560542)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[500],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureNewPassword = !obscureNewPassword;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: TextFormField(
                                controller: confirmPasswordController,
                                obscureText: obscureConfirmPassword,
                                style: const TextStyle(fontSize: 16),
                                decoration: InputDecoration(
                                  labelText: 'Confirm New Password',
                                  labelStyle: TextStyle(color: Colors.grey[600]),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Color(0xff560542)),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey[500],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        obscureConfirmPassword = !obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Password Requirements
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Password Requirements:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRequirement(
                                    'At least 6 characters',
                                    newPasswordController.text.length >= 6,
                                  ),
                                  _buildRequirement(
                                    'Contains a number',
                                    RegExp(r'[0-9]').hasMatch(newPasswordController.text),
                                  ),
                                  _buildRequirement(
                                    'Contains a letter',
                                    RegExp(r'[a-zA-Z]').hasMatch(newPasswordController.text),
                                  ),
                                  _buildRequirement(
                                    'Passwords match',
                                    newPasswordController.text.isNotEmpty &&
                                        newPasswordController.text == confirmPasswordController.text,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

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
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isLoading ? null : () async {
                                      // Validate inputs
                                      if (oldPasswordController.text.isEmpty) {
                                        _showSnackBar('Please enter current password', Colors.red);
                                        return;
                                      }
                                      if (newPasswordController.text.length < 6) {
                                        _showSnackBar('Password must be at least 6 characters', Colors.red);
                                        return;
                                      }
                                      if (!RegExp(r'[0-9]').hasMatch(newPasswordController.text)) {
                                        _showSnackBar('Password must contain at least one number', Colors.red);
                                        return;
                                      }
                                      if (!RegExp(r'[a-zA-Z]').hasMatch(newPasswordController.text)) {
                                        _showSnackBar('Password must contain at least one letter', Colors.red);
                                        return;
                                      }
                                      if (newPasswordController.text != confirmPasswordController.text) {
                                        _showSnackBar('Passwords do not match', Colors.red);
                                        return;
                                      }

                                      setState(() => isLoading = true);

                                      try {
                                        final user = FirebaseAuth.instance.currentUser;
                                        if (user != null) {
                                          // Reauthenticate user
                                          final credential = EmailAuthProvider.credential(
                                            email: user.email!,
                                            password: oldPasswordController.text,
                                          );
                                          await user.reauthenticateWithCredential(credential);

                                          // Change password
                                          await user.updatePassword(newPasswordController.text);

                                          if (mounted) {
                                            Navigator.pop(context);
                                            _showSnackBar('Password changed successfully!', Colors.green);
                                          }
                                        }
                                      } on FirebaseAuthException catch (e) {
                                        String message = 'Failed to change password';
                                        if (e.code == 'wrong-password') {
                                          message = 'Current password is incorrect';
                                        } else if (e.code == 'weak-password') {
                                          message = 'Password is too weak';
                                        } else if (e.code == 'requires-recent-login') {
                                          message = 'Please log in again to change password';
                                        }
                                        _showSnackBar(message, Colors.red);
                                      } catch (e) {
                                        _showSnackBar('An error occurred: $e', Colors.red);
                                      } finally {
                                        if (mounted) {
                                          setState(() => isLoading = false);
                                        }
                                      }
                                    },
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
                                        : const Text('Update Password'),
                                  ),
                                ),
                              ],
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
      },
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Forgot Password Function
  Future<void> _forgotPassword() async {
    final TextEditingController emailController = TextEditingController();
    bool isLoading = false;
    bool isEmailSent = false;

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.5,
              minChildSize: 0.4,
              maxChildSize: 0.6,
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
                      const SizedBox(height: 20),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xff560542).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_reset,
                                color: Color(0xff560542),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff1a1a1a),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            if (!isEmailSent) ...[
                              // Email Field
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: TextFormField(
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    labelStyle: TextStyle(color: Colors.grey[600]),
                                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xff560542)),
                                    hintText: 'Enter your registered email',
                                    hintStyle: TextStyle(color: Colors.grey[400]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Info Text
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'We will send a password reset link to your email address.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Send Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : () async {
                                    if (emailController.text.isEmpty) {
                                      _showSnackBar('Please enter your email', Colors.red);
                                      return;
                                    }
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text)) {
                                      _showSnackBar('Please enter a valid email', Colors.red);
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    try {
                                      await FirebaseAuth.instance.sendPasswordResetEmail(
                                        email: emailController.text.trim(),
                                      );
                                      setState(() {
                                        isEmailSent = true;
                                        isLoading = false;
                                      });
                                    } on FirebaseAuthException catch (e) {
                                      String message = 'Failed to send reset email';
                                      if (e.code == 'user-not-found') {
                                        message = 'No user found with this email';
                                      } else if (e.code == 'invalid-email') {
                                        message = 'Invalid email address';
                                      }
                                      _showSnackBar(message, Colors.red);
                                      setState(() => isLoading = false);
                                    } catch (e) {
                                      _showSnackBar('An error occurred: $e', Colors.red);
                                      setState(() => isLoading = false);
                                    }
                                  },
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
                                      : const Text('Send Reset Link'),
                                ),
                              ),
                            ] else ...[
                              // Success Message
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 40,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Reset Link Sent!',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'We have sent a password reset link to\n${emailController.text}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Close Button
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
                                  child: const Text('Close'),
                                ),
                              ),
                            ],
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
      },
    );
  }

  // Settings Menu
  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1a1a1a),
                ),
              ),
              const SizedBox(height: 20),

              // Change Password Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff560542).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Color(0xff560542),
                  ),
                ),
                title: const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Update your account password'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _changePassword();
                },
              ),

              const Divider(height: 1, indent: 70, endIndent: 20),

              // Forgot Password Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset,
                    color: Colors.orange,
                  ),
                ),
                title: const Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Reset your password via email'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _forgotPassword();
                },
              ),

              const Divider(height: 1, indent: 70, endIndent: 20),

              // Privacy Policy Option
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text('Read our privacy policy'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pop(context);
                  _showPrivacyPolicy();
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Privacy Policy
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your personal information when you use our attendance management system.\n\n'
                    'Information We Collect:\n'
                    '• Personal information (name, email, phone number)\n'
                    '• Attendance records and check-in/out times\n'
                    '• Break times and durations\n'
                    '• Device information and location data\n\n'
                    'How We Use Your Information:\n'
                    '• To manage attendance and track work hours\n'
                    '• To communicate with you about your account\n'
                    '• To improve our services and user experience\n'
                    '• To comply with legal obligations\n\n'
                    'Data Security:\n'
                    'We implement appropriate security measures to protect your personal information from unauthorized access, alteration, or disclosure.\n\n'
                    'Contact Us:\n'
                    'If you have any questions about this privacy policy, please contact our support team.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final provider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1a1a1a),
          ),
        ),
        actions: [
          // Settings Icon
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_outlined,
                color: Color(0xff560542),
                size: 20,
              ),
            ),
            onPressed: _showSettingsMenu,
          ),
          const SizedBox(width: 5),

          // Edit/Close Icon
          if (!provider.isLoading)
            IconButton(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEdit
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xff560542).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isEdit ? Icons.close : Icons.edit,
                  color: isEdit ? Colors.red : const Color(0xff560542),
                  size: 20,
                ),
              ),
              onPressed: () {
                if (!isEdit) {
                  // Reset controllers when entering edit mode
                  nameController.text = provider.name;
                  designationController.text = provider.designation;
                  phoneController.text = provider.phone;
                  _selectedJoinDate = provider.joinDate;
                  _calculateWorkDuration();
                }
                setState(() {
                  isEdit = !isEdit;
                });
              },
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: Consumer<ProfileProvider>(
          builder: (context,profileProvider,child){

            // Update controllers with loaded data
            nameController.text = profileProvider.name;
            designationController.text = profileProvider.designation;
            phoneController.text = profileProvider.phone;
            _selectedJoinDate = profileProvider.joinDate;

            if( provider.isLoading)
            {
              return const Center(
              child: CircularProgressIndicator(
                color: Color(0xff560542),
              ),
            );}
            else{
              return SingleChildScrollView(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.05),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Profile Avatar with animation
                          _buildAnimatedAvatar(provider),

                          const SizedBox(height: 16),

                          // Employee ID badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.badge,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  provider.employeeId,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Profile Fields
                          _buildProfileField(
                            icon: Icons.person_outline,
                            label: 'Full Name',
                            controller: nameController,
                            hint: "Enter your full name",
                            isEdit: isEdit,
                          ),

                          _buildProfileField(
                            icon: Icons.work_outline,
                            label: 'Designation',
                            controller: designationController,
                            hint: "Enter your designation",
                            isEdit: isEdit,
                          ),

                          // Join Date Field (Editable)
                          _buildJoinDateField(
                            provider: provider,
                            isEdit: isEdit,
                          ),

                          // Total Work Duration Card
                          _buildWorkDurationCard(),

                          _buildProfileField(
                            icon: Icons.email_outlined,
                            label: 'Email Address',
                            controller: TextEditingController(text: provider.email),
                            hint: "Email",
                            isEdit: false, // Email cannot be edited
                            enabled: false,
                          ),

                          _buildProfileField(
                            icon: Icons.phone_outlined,
                            label: 'Phone Number',
                            controller: phoneController,
                            hint: "Enter your phone number",
                            isEdit: isEdit,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 30),

                          // Logout Button
                          _buildLogoutButton(),

                          const SizedBox(height: 20),

                          // Update Button (only in edit mode)
                          if (isEdit) ...[
                            const SizedBox(height: 20),
                            _buildUpdateButton(provider),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );}
      })

    );
  }

  Widget _buildWorkDurationCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xff560542).withOpacity(0.1),
            const Color(0xff560542).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xff560542).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff560542).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.work_history,
              color: Color(0xff560542),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Work Duration',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff560542),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _totalWorkDuration,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff1a1a1a),
                  ),
                ),
                if (_selectedJoinDate != null)
                  Text(
                    'Since ${DateFormat('dd MMM yyyy').format(_selectedJoinDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff560542).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timer,
              color: Color(0xff560542),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinDateField({
    required ProfileProvider provider,
    required bool isEdit,
  }) {
    return GestureDetector(
      onTap: isEdit ? _selectJoinDate : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEdit
                ? const Color(0xff560542).withOpacity(0.3)
                : Colors.grey[200]!,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: isEdit
                        ? const Color(0xff560542)
                        : Colors.grey[500],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Join Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (isEdit) ...[
                    const Spacer(),
                    Icon(
                      Icons.edit_calendar,
                      size: 16,
                      color: const Color(0xff560542).withOpacity(0.7),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedJoinDate != null
                            ? DateFormat('dd MMMM yyyy').format(_selectedJoinDate!)
                            : 'Not set',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedJoinDate != null
                              ? const Color(0xff1a1a1a)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                    if (isEdit && _selectedJoinDate != null)
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedJoinDate = null;
                            _totalWorkDuration = 'Not available';
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedAvatar(ProfileProvider provider) {
    return Hero(
      tag: 'profile-avatar',
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: provider.avatarColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: provider.avatarColor.withOpacity(0.2),
              child: provider.profileImageUrl.isNotEmpty
                  ? ClipOval(
                child: Image.network(
                  provider.profileImageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildInitialsAvatar(provider);
                  },
                ),
              )
                  : _buildInitialsAvatar(provider),
            ),
            if (isEdit)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xff560542),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(ProfileProvider provider) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: provider.avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          provider.initials,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isEdit,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEdit && enabled
              ? const Color(0xff560542).withOpacity(0.3)
              : Colors.grey[200]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isEdit && enabled
                      ? const Color(0xff560542)
                      : Colors.grey[500],
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            isEdit && enabled
                ? TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: keyboardType,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xff1a1a1a),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.only(left: 28),
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(
                controller.text.isEmpty ? hint : controller.text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: controller.text.isEmpty
                      ? Colors.grey[400]
                      : const Color(0xff1a1a1a),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleLogout,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Sign out from your account',
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
                color: Colors.red.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton(ProfileProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isSaving ? null : _handleUpdate,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff560542),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: provider.isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Update Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}