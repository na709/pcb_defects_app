import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/pcb_history_tab.dart';
import '../services/api_service.dart';

const Color primaryBlue = Color(0xFF1E88E5);
const Color errorRed = Color(0xFFEF5350);

class PCBDetectorScreen extends StatefulWidget {
  const PCBDetectorScreen({super.key});

  @override
  State<PCBDetectorScreen> createState() => _PCBDetectorScreenState();
}

class _PCBDetectorScreenState extends State<PCBDetectorScreen>
{
  String apiProcessingTime = "0ms";
  String pcbStatus = "Chưa kiểm định";
  bool isPcbPassed = false;
  String selectedTab = "Home";
  bool isDarkMode = true;

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _showLiveCamera = false;
  bool isFlashOn = false;

  File? _selectedImageFile;
  String? _serverImageUrl;

  bool _isAnalyzing = false;
  bool hasServerResult = false;
  String pcbInfoText = "Chưa có dữ liệu. Vui lòng sử dụng camera hoặc thêm ảnh từ thư viện.";
  List<String> mockFaults = [];

  @override
  void initState() {
    super.initState();
    _initializeCameraSystem();
  }

  Future<void> _initializeCameraSystem() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint("Lỗi nạp phần cứng camera: $e");
    }
  }

  Future<void> _startLiveCameraView() async {
    if (_cameras == null || _cameras!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không tìm thấy thiết bị camera!")),
      );
      return;
    }

    setState(() {
      selectedTab = "Home";
      _showLiveCamera = true;
      _selectedImageFile = null;
      _serverImageUrl = null;
      hasServerResult = false;
    });

    if (_cameraController == null) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      } catch (e) {
        debugPrint("Lỗi khởi tạo camera: $e");
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        if (_cameraController != null && isFlashOn) {
          await _cameraController!.setFlashMode(FlashMode.off);
          isFlashOn = false;
        }

        setState(() {
          _selectedImageFile = File(image.path);
          _serverImageUrl = null;
          _showLiveCamera = false;
          hasServerResult = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      XFile file = await _cameraController!.takePicture();
      setState(() {
        _showLiveCamera = false;
        _selectedImageFile = File(file.path);
        _serverImageUrl = null;
        hasServerResult = false;
      });
    } catch (e) {
      debugPrint("Lỗi chụp ảnh: $e");
    }
  }

  Future<void> _analyzeImageFromServer() async {
    if (_selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chụp ảnh hoặc chọn ảnh từ thư viện trước khi phân tích!"),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      mockFaults = [];
      hasServerResult = false;
    });

    final result = await ApiService.analyzePcbImage(_selectedImageFile!);

    setState(() {
      _isAnalyzing = false;
    });

    if (result != null && result['success'] == true) {
      setState(() {
        hasServerResult = true;
        pcbInfoText = result['pcb_info'] ?? "Không rõ mã bo mạch";

        final List<dynamic> serverFaults = result['faults'] ?? [];
        mockFaults = serverFaults.map((f) {
          final String className = f['class'] ?? 'Khuyết tật';
          final double conf = (f['confidence'] ?? 0.0) * 100;
          final List<dynamic> bbox = f['bbox'] ?? [0,0,0,0];
          return "$className (${conf.toStringAsFixed(0)}%) found at [${bbox.map((e) => e.toStringAsFixed(0)).join(', ')}]";
        }).toList();

        _serverImageUrl = result['result_image_url'];
        apiProcessingTime = result['processing_time'] ?? "0ms";
        pcbStatus = result['status'] ?? "Không rõ";
        isPcbPassed = result['is_passed'] ?? false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phân tích mạch thành công!"), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi phân tích hoặc không kết nối được tới Server API local!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      if (isFlashOn) {
        await _cameraController!.setFlashMode(FlashMode.off);
      } else {
        await _cameraController!.setFlashMode(FlashMode.torch);
      }
      setState(() => isFlashOn = !isFlashOn);
    } catch (e) {
      debugPrint("Lỗi Flash: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color currentBackground = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final Color currentSurface = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color currentTextColor = isDarkMode ? Colors.white : const Color(0xFF212121);

    return Scaffold(
      backgroundColor: currentBackground,
      body: SafeArea(child: _buildBodyContent(currentSurface, currentTextColor)),
      bottomNavigationBar: _buildBottomNavBar(currentSurface),
    );
  }

  Widget _buildBodyContent(Color currentSurface, Color currentTextColor) {
    switch (selectedTab) {
      case "Home":
        return _buildHomeTab(currentSurface, currentTextColor);
      case "History":
        return PCBHistoryTab(
          surfaceCard: currentSurface,
          errorRed: errorRed,
          primaryBlue: primaryBlue,
        );
      default:
        return Center(
          child: Text("Màn hình $selectedTab đang phát triển", style: TextStyle(color: currentTextColor, fontSize: 16)),
        );
    }
  }

  Widget _buildHomeTab(Color currentSurface, Color currentTextColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("PCB Detector", currentTextColor),
            const SizedBox(height: 12),
            _buildDisplayZone(),
            const SizedBox(height: 20),
            _buildActionBar(currentSurface),
            const SizedBox(height: 24),
            Text("Kết quả phân tích từ Server", style: TextStyle(color: currentTextColor, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildServerResultSection(currentSurface, currentTextColor),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title, Color currentTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: primaryBlue, size: 28),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: currentTextColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: isDarkMode ? Colors.amber : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 4),
              Switch(
                value: isDarkMode,
                activeColor: primaryBlue,
                activeTrackColor: primaryBlue.withOpacity(0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.3),
                onChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayZone() {
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
            if (_showLiveCamera) ...[
              _isCameraInitialized
                  ? Positioned.fill(child: CameraPreview(_cameraController!))
                  : const Center(child: CircularProgressIndicator(color: primaryBlue)),
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleFlash,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                    child: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: isFlashOn ? Colors.yellow : Colors.white, size: 22),
                  ),
                ),
              ),
            ]
            else if (_serverImageUrl != null) ...[
              Positioned.fill(
                child: Image.network(
                  _serverImageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: primaryBlue));
                  },
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: GridPainter())),
            ]
            else if (_selectedImageFile != null) ...[
                Positioned.fill(child: Image.file(_selectedImageFile!, fit: BoxFit.contain)),
                Positioned.fill(child: CustomPaint(painter: GridPainter())),
                if (_isAnalyzing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: primaryBlue),
                          SizedBox(height: 12),
                          Text("Đang truyền dữ liệu ảnh...", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ]
              else ...[
                  const Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_camera_back_outlined, color: Colors.grey, size: 48),
                        SizedBox(height: 12),
                        Text(
                          "Khung hiển thị hình ảnh quét mạch",
                          style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Sử dụng camera hoặc nút thư viện phía dưới",
                          style: TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar(Color currentSurface) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(icon: Icons.folder_open, label: "Thư viện", currentSurface: currentSurface, onTap: _pickImageFromGallery),
        GestureDetector(
          onTap: _showLiveCamera ? _takePicture : _startLiveCameraView,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.2), shape: BoxShape.circle),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
              child: Icon(_showLiveCamera ? Icons.camera_alt : Icons.photo_camera, color: Colors.white, size: 30),
            ),
          ),
        ),
        _buildActionButton(
          icon: Icons.analytics_outlined,
          label: "Phân tích ảnh",
          currentSurface: currentSurface,
          onTap: _analyzeImageFromServer,
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color currentSurface, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: currentSurface, shape: BoxShape.circle),
            child: Icon(icon, color: isDarkMode ? Colors.white : const Color(0xFF424242)),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildServerResultSection(Color currentSurface, Color currentTextColor) {
    if (_isAnalyzing) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: currentSurface, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text("Đang kết nối Server AI để kiểm định mô hình...", style: TextStyle(color: Colors.amber, fontSize: 13)),
        ),
      );
    }

    if (!hasServerResult) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: currentSurface, borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: Text(pcbInfoText, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: currentSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPcbPassed ? Colors.green.withOpacity(0.3) : errorRed.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(pcbInfoText, style: TextStyle(color: currentTextColor, fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: isPcbPassed ? Colors.green.withOpacity(0.15) : errorRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6)
                ),
                child: Text(
                    "Phát hiện: ${mockFaults.length} lỗi",
                    style: TextStyle(color: isPcbPassed ? Colors.green : errorRed, fontWeight: FontWeight.bold, fontSize: 12)
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildResultDetailRow(
              "Trạng thái kiểm định:",
              pcbStatus,
              isPcbPassed ? Colors.green : errorRed
          ),
          _buildResultDetailRow("Thời gian xử lý API:", apiProcessingTime, Colors.green),
          const SizedBox(height: 8),
          if (mockFaults.isNotEmpty) ...[
            const Text("Chi tiết các tọa độ lỗi tìm thấy:", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 6),
            ...mockFaults.map((fault) => _buildFaultLabel(fault, currentTextColor)),
          ] else ...[
            const SizedBox(height: 10),
            Center(
              child: Text(
                "🎉 Bo mạch hoàn hảo, không phát hiện khiếm khuyết!",
                style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultDetailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(width: 6),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFaultLabel(String description, Color currentTextColor) {
    final parts = description.split(" found at ");
    final String errorTitle = parts.isNotEmpty ? parts[0] : description;
    final String coordinates = parts.length > 1 ? "Vị trí: ${parts[1]}" : "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(Icons.report_problem, color: errorRed, size: 16),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorTitle,
                  style: TextStyle(
                    color: isDarkMode ? Colors.amber : const Color(0xFF0D47A1),
                    fontSize: 13,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (coordinates.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    coordinates,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar(Color currentSurface) {
    return Container(
      color: currentSurface,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavButton(Icons.home, "Home"),
              _buildNavButton(Icons.search, "Search"),
              const SizedBox(width: 48),
              _buildNavButton(Icons.history, "History"),
              _buildNavButton(Icons.person, "Profile"),
            ],
          ),
          Positioned(
            top: -16,
            left: MediaQuery.of(context).size.width / 2 - 28,
            child: GestureDetector(
              onTap: _showLiveCamera ? _takePicture : _startLiveCameraView,
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Icon(_showLiveCamera ? Icons.camera_alt : Icons.center_focus_strong, color: Colors.white, size: 28),
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
      onTap: () => setState(() => selectedTab = label),
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? primaryBlue : Colors.grey, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: isSelected ? primaryBlue : Colors.grey, fontSize: 11)),
          ],
        ),
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