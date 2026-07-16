import 'package:flutter/material.dart';
import 'package:tiies_attendance_app/Utils/Constant/AppColors.dart';

class AnimatedCheckInOutButton extends StatefulWidget {
  final VoidCallback onTap;
  final String buttonName;
  final bool isCheckIn;
  const AnimatedCheckInOutButton({required this.onTap, super.key, required this.buttonName, required this.isCheckIn});

  @override
  State<AnimatedCheckInOutButton> createState() =>
      _AnimatedCheckInOutButtonState();
}

class _AnimatedCheckInOutButtonState extends State<AnimatedCheckInOutButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.92,
      upperBound: 1,
      value: 1,
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: GestureDetector(
        onTapDown: (_) => _controller.reverse(),
        onTapUp: (_) {
          _controller.forward();
          widget.onTap();
        },
        child:Opacity(
            opacity: widget.isCheckIn ? 1 : 0.4,
            child: Container(
          height: 180,
          width: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors().mainColor,
            boxShadow: [
              BoxShadow(
                color: AppColors().mainColor.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child:  Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, size: 60, color: Colors.white),
              SizedBox(height: 10),
              Text(widget.buttonName,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        )),
      ),
    );
  }
}
