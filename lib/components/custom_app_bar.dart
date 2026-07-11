import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Icon(Icons.memory, color: Colors.blueAccent, size: 28),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Switch(
          value: isDarkMode,
          onChanged: onThemeChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}