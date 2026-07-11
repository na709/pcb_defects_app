import 'package:flutter/material.dart';

class ThemeService {
  // 0: Light, 1: Dark
  static Color textColor = Colors.white;
  static bool isDarkMode = true;
  static final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(true);
}