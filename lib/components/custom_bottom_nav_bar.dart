import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final String selectedTab;
  final Function(String) onTabSelected;
  final VoidCallback onCameraTap;
  final Color backgroundColor;
  final Color activeColor;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onCameraTap,
    required this.backgroundColor,
    required this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(Icons.login, "Login"),
              _buildNavButton(Icons.home, "Home"),
              const SizedBox(width: 40),
              _buildNavButton(Icons.history, "History"),
              _buildNavButton(Icons.person, "Admin"),
            ],
          ),
          Positioned(
            top: -16,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: onCameraTap,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label) {
    final isSelected = selectedTab == label;
    return InkWell(
      onTap: () => onTabSelected(label),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? activeColor : Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}