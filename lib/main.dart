import 'package:flutter/material.dart';
import 'screens/pcb_detector_screen.dart'; // Đảm bảo file pcb_detector_screen.dart nằm cùng thư mục lib

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCB Detector',
      debugShowCheckedModeBanner: false,
      home: const PCBDetectorScreen(),
    );
  }
}