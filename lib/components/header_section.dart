import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final Color textColor;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HeaderSection({
    Key? key,
    required this.title,
    required this.textColor,
    required this.isDarkMode,
    required this.onThemeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.memory, color: Colors.blueAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Switch(
            value: isDarkMode,
            onChanged: onThemeChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
}