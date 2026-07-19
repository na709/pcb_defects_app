import 'package:flutter/material.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onGalleryTap;
  final IconData? cameraIcon;
  final VoidCallback onCameraTap;
  final VoidCallback onAnalyzeTap;
  final bool isAutoMode;
  final Function(bool) onModeChanged;
  final Color surfaceColor;
  final bool isDarkMode;

  const ActionBar({
    Key? key,
    required this.onGalleryTap,
    this.cameraIcon,
    required this.onCameraTap,
    required this.onAnalyzeTap,
    required this.isAutoMode,
    required this.onModeChanged,
    required this.surfaceColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //  chọn mode
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildModeText("THỦ CÔNG", !isAutoMode, () => onModeChanged(false)),
            const SizedBox(width: 30),
            _buildModeText("TỰ ĐỘNG", isAutoMode, () => onModeChanged(true)),
          ],
        ),
        const SizedBox(height: 16),

        // các btn chức năng
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(icon: Icons.folder_open, label: "Thư viện", onTap: onGalleryTap),

            // nút camera
            GestureDetector(
              onTap: onCameraTap,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: (isAutoMode ? Colors.green : const Color(0xFF1E88E5)).withOpacity(0.2),
                    shape: BoxShape.circle
                ),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: isAutoMode ? Colors.green : const Color(0xFF1E88E5),
                      shape: BoxShape.circle
                  ),
                  child: Icon(
                      cameraIcon ?? (isAutoMode ? Icons.play_arrow : Icons.camera_alt),
                      color: Colors.white,
                      size: 30
                  ),
                ),
              ),
            ),

            _buildActionButton(icon: Icons.analytics_outlined, label: "Phân tích", onTap: onAnalyzeTap),
          ],
        ),
      ],
    );
  }

  //dòng chọn mode
  Widget _buildModeText(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? (isAutoMode ? Colors.green.withOpacity(0.2) : const Color(0xFF1E88E5).withOpacity(0.2)) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: isActive ? (isAutoMode ? Colors.green : const Color(0xFF4CABFF)) : Colors.grey,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              letterSpacing: 1.1
          ),
        ),
      ),
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