import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiies_attendance_app/Providers/botton_nav_provider.dart';
import 'package:tiies_attendance_app/Utils/Constant/AppColors.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        return Scaffold(
          body: bottomNavProvider.pages[bottomNavProvider.index],
          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors().mainColor.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BottomNavigationBar(
                currentIndex: bottomNavProvider.index,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white.withOpacity(0.6),
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 10,
                ),
                showUnselectedLabels: true,
                backgroundColor: AppColors().mainColor,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  bottomNavProvider.updateIndex(index);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: _buildNavItem(
                      icon: Icons.home_rounded,
                      isSelected: bottomNavProvider.index == 0,
                    ),
                    label: "Home",
                    activeIcon: _buildNavItem(
                      icon: Icons.home_rounded,
                      isSelected: true,
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavItem(
                      icon: Icons.request_page_rounded,
                      isSelected: bottomNavProvider.index == 1,
                    ),
                    label: "My Request",
                    activeIcon: _buildNavItem(
                      icon: Icons.request_page_rounded,
                      isSelected: true,
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavItem(
                      icon: Icons.people_alt_rounded,
                      isSelected: bottomNavProvider.index == 2,
                    ),
                    label: "Team",
                    activeIcon: _buildNavItem(
                      icon: Icons.people_alt_rounded,
                      isSelected: true,
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavItem(
                      icon: Icons.free_breakfast_rounded,
                      isSelected: bottomNavProvider.index == 3,
                    ),
                    label: "Take Break",
                    activeIcon: _buildNavItem(
                      icon: Icons.free_breakfast_rounded,
                      isSelected: true,
                    ),
                  ),
                  BottomNavigationBarItem(
                    icon: _buildNavItem(
                      icon: Icons.person_rounded,
                      isSelected: bottomNavProvider.index == 4,
                    ),
                    label: "Profile",
                    activeIcon: _buildNavItem(
                      icon: Icons.person_rounded,
                      isSelected: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({required IconData icon, required bool isSelected}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(isSelected ? 10 : 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(
        icon,
        size: isSelected ? 26 : 22,
      ),
    );
  }
}