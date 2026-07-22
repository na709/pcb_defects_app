import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../components/custom_app_bar.dart';
import '../services/socket_service.dart';
import '../theme/theme_manager.dart';
import '../screens/pcb_history_tab.dart';
import '../services/api_service.dart';
import '../components/action_bar.dart';
import '../components/result_section.dart';
import '../components/display_zone.dart';
import '../components/custom_bottom_nav_bar.dart';
import '../wrapper/admin_wrapper.dart';
import 'package:image/image.dart' as img;
import 'dart:async';

const Color primaryBlue = Color(0xFF1E88E5);
const Color errorRed = Color(0xFFEF5350);

class AppState {
  static String? lastProcessedImageUrl;
  static List<dynamic>? lastFaults;
}

class PCBDetectorScreen extends StatefulWidget {
  final String? deviceId;
  final int? sessionId;

  const PCBDetectorScreen({Key? key, this.deviceId, this.sessionId}) : super(key: key);

  @override
  State<PCBDetectorScreen> createState() => _PCBDetectorScreenState();
}

class _PCBDetectorScreenState extends State<PCBDetectorScreen> with AutomaticKeepAliveClientMixin {
  String apiProcessingTime = "0ms";
  String pcbStatus = "Chưa kiểm định";
  bool isPcbPassed = false;
  String selectedTab = "Home";
  bool _isAdminLoggedIn = false;
  List<dynamic> rawFaultsData = [];

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

  bool _isAutoMode = false;
  bool _isAutoRunning = false;
  bool _isProcessingFrame = false;

  final SocketService _socketService = SocketService();

  // ham swap mode
  void _switchMode(bool autoModeSelected) {
    setState(() {
      _isAutoMode = autoModeSelected;
      if (!_isAutoMode) {
        _stopAutoCapture(); // swap mode
      }
    });
  }

  // btn start stream
  void _startAutoCapture() {
    if (!_showLiveCamera) {
      _startLiveCameraView().then((_) {
        _activateRealtimeStream();
      });
    } else {
      _activateRealtimeStream();
    }
  }

  void _activateRealtimeStream() async {
    setState(() => _isAutoRunning = true);
    debugPrint("[FLUTTER SOCKET] Chuẩn bị stream với Session ID: ${widget.sessionId}");

    // cờ _isAutoRunning quản lý vòng lặp
    while (_isAutoRunning) {
      if (_cameraController == null || !_cameraController!.value.isInitialized) break;

      // Nếu camera đang bận chụp hoặc frame trước chưa xử lý xong thì đợi một chút rồi quét tiếp
      if (_cameraController!.value.isTakingPicture || _isProcessingFrame) {
        await Future.delayed(const Duration(milliseconds: 30));
        continue;
      }

      try {
        _isProcessingFrame = true;

        // 1. Chụp ảnh nhanh bằng phần cứng (Tự động nén thành định dạng JPEG chuẩn)
        XFile file = await _cameraController!.takePicture();

        // 2. Đọc file trực tiếp từ RAM sang mảng bytes hợp lệ
        final Uint8List imageBytes = await file.readAsBytes();

        // 3. Bắn thẳng qua Socket lên Server (Không bao giờ sợ bị lỗi sọc hình nữa)
        _socketService.streamFrame(
          imageBytes: imageBytes,
          sessionId: widget.sessionId,
        );

        // Dọn dẹp file tạm trên thiết bị ngay lập tức
        File(file.path).delete().catchError((e) => debugPrint("Lỗi xóa file tạm: $e"));

      } catch (e) {
        debugPrint("Lỗi chụp luồng Realtime Burst: $e");
      } finally {
        _isProcessingFrame = false;
      }

      // khoảng nghỉ khi gọi socket hiện tại là 5 giây
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // stop stream
  void _stopAutoCapture() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _socketService.stopStream();
    setState(() => _isAutoRunning = false);
  }

  // Hàm xử lý phân tích (dành riêng cho luồng THỦ CÔNG & ảnh từ THƯ VIỆN)
  Future<void> _executeAnalysis() async {
    if (_isProcessingFrame) return;

    File? imageToAnalyze = _selectedImageFile;
    if (imageToAnalyze == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Vui lòng chụp ảnh hoặc chọn ảnh từ thư viện trước khi phân tích!"),
            backgroundColor: Colors.amber,
          ),
        );
      }
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _isProcessingFrame = true;
      mockFaults = [];
      hasServerResult = false;
    });

    try {
      debugPrint("[API MANUAL] Đang gửi ảnh phân tích thủ công với Session ID: ${widget.sessionId}");
      final result = await ApiService.analyzePcbImage(imageToAnalyze, widget.deviceId, widget.sessionId);

      if (result != null && result['success'] == true) {
        setState(() {
          hasServerResult = true;
          _showLiveCamera = _isAutoMode;
          pcbInfoText = result['pcb_info'] ?? "Không rõ mã bo mạch";

          final List<dynamic> serverFaults = result['faults'] ?? [];
          mockFaults = serverFaults.map((f) {
            final String className = f['class'] ?? 'Khuyết tật';
            final double conf = (f['confidence'] ?? 0.0) * 100;
            final List<dynamic> bbox = f['bbox'] ?? [0, 0, 0, 0];
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
    } catch (e) {
      debugPrint("Lỗi xử lý API hệ thống: $e");
    } finally {
      setState(() {
        _isAnalyzing = false;
        _isProcessingFrame = false;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeCameraSystem();

    // Thiết lập kết nối lắng nghe Socket ngầm
    _socketService.connect(
        onResultReceived: (result) {
          if (result['success'] == true && mounted) {
            setState(() {
              hasServerResult = true;
              // Luôn giữ màn hình camera hoạt động liên tục khi chạy realtime stream
              _showLiveCamera = true;
              pcbInfoText = result['pcb_info'] ?? "Không rõ mã bo mạch";
              rawFaultsData = result['faults'] ?? [];

              final List<dynamic> serverFaults = result['faults'] ?? [];
              mockFaults = serverFaults.map((f) {
                final String className = f['class'] ?? 'Khuyết tật';
                final double conf = (f['confidence'] ?? 0.0) * 100;
                final List<dynamic> bbox = f['bbox'] ?? [0, 0, 0, 0];
                return "$className (${conf.toStringAsFixed(0)}%) found at [${bbox.map((e) => e.toStringAsFixed(0)).join(', ')}]";
              }).toList();

              _serverImageUrl = result['result_image_url'];
              apiProcessingTime = result['processing_time'] ?? "0ms";
              pcbStatus = result['status'] ?? "Không rõ";
              isPcbPassed = result['is_passed'] ?? false;
            });
          }
        },
        onErrorReceived: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error['message'] ?? "Lỗi socket realtime"), backgroundColor: Colors.red),
            );
          }
        }
    );
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

    //dpg hình ảnh
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

        if (_isAutoMode) {
          _switchMode(false);
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
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _socketService.disconnect();
    super.dispose();
  }

  String _getAppBarTitle() {
    if (selectedTab == "Admin") {
      return _isAdminLoggedIn ? "Admin Dashboard" : "Admin Login";
    }
    if (selectedTab == "History") return "History";
    return "PCB Detector";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        final Color currentBackground = isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
        final Color currentSurface = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final Color currentTextColor = isDarkMode ? Colors.white : const Color(0xFF212121);

        return Scaffold(
          backgroundColor: currentBackground,
          appBar: CustomAppBar(
            title: _getAppBarTitle(),
            isDarkMode: isDarkMode,
            onThemeChanged: (value) => ThemeService.isDarkModeNotifier.value = value,
          ),
          body: SafeArea(child: _buildBodyContent(currentSurface, currentTextColor, isDarkMode)),
          bottomNavigationBar: CustomBottomNavBar(
            selectedTab: selectedTab,
            onTabSelected: (tab) {
              setState(() => selectedTab = tab);
              if (tab != "Home" && _isAutoRunning) {
                _stopAutoCapture();
              }
            },
            onCameraTap: _showLiveCamera ? _takePicture : _startLiveCameraView,
            backgroundColor: currentSurface,
            activeColor: primaryBlue,
          ),
        );
      },
    );
  }

  Widget _buildBodyContent(Color currentSurface, Color currentTextColor, bool isDarkMode) {
    switch (selectedTab) {
      case "Home":
        return _buildHomeTab(currentSurface, currentTextColor, isDarkMode);
      case "History":
        return PCBHistoryTab(
          surfaceCard: currentSurface,
          errorRed: errorRed,
          primaryBlue: primaryBlue,
          textColor: currentTextColor,
          isDarkMode: isDarkMode,
        );
      case "Admin":
        return AdminWrapper(
            isDarkMode: isDarkMode,
            onLoginSuccess: () => setState(() => _isAdminLoggedIn = true));
      default:
        return Center(
          child: Text("Màn hình $selectedTab đang phát triển", style: TextStyle(color: currentTextColor, fontSize: 16)),
        );
    }
  }

  Widget _buildHomeTab(Color currentSurface, Color currentTextColor, bool isDarkMode) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            DisplayZone(
              showLiveCamera: _showLiveCamera,
              isCameraInitialized: _isCameraInitialized,
              cameraController: _cameraController,
              serverImageUrl: _serverImageUrl,
              selectedImageFile: _selectedImageFile,
              isAnalyzing: _isAnalyzing,
              onToggleFlash: _toggleFlash,
              isFlashOn: isFlashOn,
              rawFaultsData: rawFaultsData,
            ),
            const SizedBox(height: 20),
            ActionBar(
              isAutoMode: _isAutoMode,
              cameraIcon: !_isAutoMode
                  ? Icons.camera_alt
                  : (_isAutoRunning ? Icons.pause : Icons.play_arrow),
              onModeChanged: (isAuto) {
                _switchMode(isAuto);
              },
              isDarkMode: isDarkMode,
              surfaceColor: currentSurface,
              onGalleryTap: _pickImageFromGallery,
              onCameraTap: () {
                if (_isAutoMode) {
                  // Nút stream điều khiển chạy / dừng realtime
                  if (_isAutoRunning) {
                    _stopAutoCapture();
                  } else {
                    _startAutoCapture();
                  }
                } else {
                  // Nút chụp thủ công thông thường
                  if (_showLiveCamera) {
                    _takePicture().then((_) => _executeAnalysis());
                  } else {
                    _startLiveCameraView();
                  }
                }
              },
              onAnalyzeTap: () {
                _executeAnalysis();
              },
            ),
            const SizedBox(height: 24),
            ResultSection(
              isAnalyzing: _isAnalyzing,
              hasServerResult: hasServerResult,
              pcbInfoText: pcbInfoText,
              mockFaults: mockFaults,
              surfaceColor: currentSurface,
              textColor: currentTextColor,
              isDarkMode: isDarkMode,
              isPcbPassed: isPcbPassed,
              pcbStatus: pcbStatus,
              apiProcessingTime: apiProcessingTime,
              errorRed: errorRed,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}