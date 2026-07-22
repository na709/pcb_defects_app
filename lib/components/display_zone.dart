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

  final List<dynamic>? rawFaultsData;

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
    this.rawFaultsData, // Đưa vào constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double zoneWidth = constraints.maxWidth;
            final double zoneHeight = constraints.maxHeight;

            return Stack(
              children: [
                // ---- TRƯỜNG HỢP 1: HIỂN THỊ CAMERA LIVE STREAM ----
                if (showLiveCamera) ...[
                  isCameraInitialized
                      ? Positioned.fill(child: CameraPreview(cameraController!))
                      : const Center(child: CircularProgressIndicator(color: primaryBlue)),

                  // Lưới Grid căn chỉnh bo mạch
                  Positioned.fill(child: CustomPaint(painter: GridPainter())),

                  // Vẽ các Bounding Box Realtime từ Socket lên luồng Live
                  if (isCameraInitialized && rawFaultsData != null)
                    ..._buildBoundingBoxes(rawFaultsData!, zoneWidth, zoneHeight),

                  // Nút bật/tắt Flash
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

                  // ---- TRƯỜNG HỢP 2: HIỂN THỊ ẢNH KẾT QUẢ CŨ TỪ URL SERVER ----
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

                  // ---- TRƯỜNG HỢP 3: HIỂN THỊ ẢNH THỦ CÔNG TỪ THƯ VIỆN CỤ CỤC BỘ ----
                ] else if (selectedImageFile != null) ...[
                  Positioned.fill(child: Image.file(selectedImageFile!, fit: BoxFit.contain)),
                  Positioned.fill(child: CustomPaint(painter: GridPainter())),
                  if (isAnalyzing) _buildLoadingOverlay(),
                ] else
                  _buildPlaceholder(),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBoundingBoxes(List<dynamic> faults, double zoneWidth, double zoneHeight) {
    if (cameraController == null || !cameraController!.value.isInitialized) return [];

    // 1. LẤY ĐỘ PHÂN GIẢI THỰC TẾ CỦA FILE ẢNH/PREVIEW CAMERA XUẤT RA
    // Lưu ý: Hệ điều hành Android/iOS thường đảo ngược chiều rộng và chiều cao của preview size khi cầm máy đứng
    final Size previewSize = cameraController!.value.previewSize!;
    final double previewWidth = previewSize.height;  // Chiều rộng ảnh

    final double previewHeight = previewSize.width; // Chiều cao ảnh

    return faults.map((fault) {
      final List<dynamic> bbox = fault['bbox'] ?? [0, 0, 0, 0];
      final String label = fault['class'] ?? 'Lỗi';

      // 2. TÍNH TỶ LỆ CO GIÃN ĐỘNG (SCALE FACTOR)
      // Tỷ lệ = (Kích thước khung hiển thị nhỏ trên app) / (Kích thước ảnh gốc camera chụp ra)
      double scaleX = zoneWidth / previewWidth;
      double scaleY = zoneHeight / previewHeight;

      // 3. NHÂN TỶ LỆ ĐỂ ĐƯA TOẠ ĐỘ LỚN VỀ KHỚP VỚI KHUNG NHỎ
      double left = bbox[0].toDouble() * scaleX;
      double top = bbox[1].toDouble() * scaleY;
      double width = (bbox[2].toDouble() - bbox[0].toDouble()) * scaleX;
      double height = (bbox[3].toDouble() - bbox[1].toDouble()) * scaleY;

      return Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: errorRed, width: 2.0),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -16,
                left: -2,
                child: Container(
                  color: errorRed,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
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