import 'package:flutter/material.dart';

class HeaderSection extends StatelessWidget {
  final String title;
  final Color textColor;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Color(0xFF1E88E5), size: 28),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Switch(
            value: isDarkMode,
            activeColor: const Color(0xFF1E88E5),
            onChanged: onThemeChanged,
          ),
        ],
      ),
    );
  }
}