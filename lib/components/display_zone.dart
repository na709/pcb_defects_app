import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../screens/pcb_detector_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DisplayZone extends StatelessWidget {
  final bool showLiveCamera;
  final bool isCameraInitialized;
  final CameraController? cameraController;
  final String? serverImageUrl;
  final File? selectedImageFile;
  final bool isAnalyzing;
  final VoidCallback onToggleFlash;
  final bool isFlashOn;

  const DisplayZone({
    Key? key,
    required this.showLiveCamera,
    required this.isCameraInitialized,
    this.cameraController,
    this.serverImageUrl,
    this.selectedImageFile,
    required this.isAnalyzing,
    required this.onToggleFlash,
    required this.isFlashOn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (showLiveCamera) ...[
              isCameraInitialized
                  ? Positioned.fill(child: CameraPreview(cameraController!))
                  : const Center(child: CircularProgressIndicator(color: primaryBlue)),
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
              Positioned(
                top: 12, right: 12,
                child: GestureDetector(
                  onTap: onToggleFlash,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: isFlashOn ? Colors.yellow : Colors.white, size: 22),
                  ),
                ),
              ),
            ] else if (serverImageUrl != null) ...[
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: serverImageUrl!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                  errorWidget: (context, url, error) {
                    debugPrint("Lỗi tải ảnh từ server: $error");
                    return selectedImageFile != null
                        ? Image.file(selectedImageFile!, fit: BoxFit.contain)
                        : const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
                    );
                  },
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
            ] else if (selectedImageFile != null) ...[
              Positioned.fill(child: Image.file(selectedImageFile!, fit: BoxFit.contain)),
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
              if (isAnalyzing) _buildLoadingOverlay(),
            ] else _buildPlaceholder(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            SizedBox(height: 12),
            Text("Đang truyền dữ liệu...", style: TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_back_outlined, color: Colors.grey, size: 48),
          Text("Chưa có ảnh/camera", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.2)..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}