import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final VoidCallback onCameraTap;
  final VoidCallback onAnalyzeTap;
  final bool isLiveCamera;
  final Color surfaceColor;
  final bool isDarkMode;

  const ActionBar({
    Key? key,
    required this.onGalleryTap,
    required this.onCameraTap,
    required this.onAnalyzeTap,
    required this.isLiveCamera,
    required this.surfaceColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(icon: Icons.folder_open, label: "Thư viện", onTap: onGalleryTap),
        GestureDetector(
          onTap: onCameraTap,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF1E88E5).withOpacity(0.2), shape: BoxShape.circle),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFF1E88E5), shape: BoxShape.circle),
              child: Icon(isLiveCamera ? Icons.camera_alt : Icons.photo_camera, color: Colors.white, size: 30),
            ),
          ),
        ),
        _buildActionButton(icon: Icons.analytics_outlined, label: "Phân tích", onTap: onAnalyzeTap),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
            child: Icon(icon, color: isDarkMode ? Colors.white : const Color(0xFF424242)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}