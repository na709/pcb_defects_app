import 'package:flutter/material.dart';

// Hệ màu chủ đạo Dark UI
const Color primaryBlue = Color(0xFF1E88E5);
const Color darkBackground = Color(0xFF121212);
const Color surfaceCard = Color(0xFF1E1E1E);
const Color errorRed = Color(0xFFEF5350);

class PCBDetectorScreen extends StatefulWidget {
  const PCBDetectorScreen({super.key});

  @override
  State<PCBDetectorScreen> createState() => _PCBDetectorScreenState();
}

class _PCBDetectorScreenState extends State<PCBDetectorScreen> {
  String selectedTab = "Home";
  String selectedFilter = "Tất cả";
  bool isFlashOn = false;

  // Giả lập trạng thái đã nhận dữ liệu từ server trả về hay chưa
  // (Sau này nhận từ API Node.js thành công thì set bằng true)
  bool hasServerResult = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      body: SafeArea(
        child: _buildBodyContent(),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // Điều hướng nội dung Body dựa theo Tab đang chọn
  Widget _buildBodyContent() {
    switch (selectedTab) {
      case "Home":
        return _buildHomeTab();
      case "History":
        return _buildHistoryTab();
      default:
        return Center(
          child: Text(
            "Màn hình $selectedTab đang phát triển",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
    }
  }

  // ==========================================
  // [TAB HOME] - CHỈ CÓ CAMERA & THÔNG TIN BACKEND
  // ==========================================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("PCB Detector"),
            const SizedBox(height: 12),
            _buildCameraLiveView(),
            const SizedBox(height: 20),
            _buildActionBar(),
            const SizedBox(height: 24),

            // Khu vực hiển thị thông tin mạch từ Server trả về
            const Text(
              "Kết quả phân tích từ Server",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildServerResultSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // [TAB HISTORY] - BỘ LỌC VÀ LỊCH SỬ QUÉT CŨ
  // ==========================================
  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Nhật ký quét lỗi"),
            const SizedBox(height: 12),
            _buildFilterChips(),
            const SizedBox(height: 24),
            _buildRecentScansList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENT: HEADER
  // ==========================================
  Widget _buildHeader(String title) {
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
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.notifications, color: Colors.white), onPressed: () {}),
              IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENT: CAMERA LIVE VIEW
  // ==========================================
  Widget _buildCameraLiveView() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: GridPainter())),
            const Center(
              child: Text("[ Live Camera View ]", style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: GestureDetector(
                onTap: () => setState(() => isFlashOn = !isFlashOn),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                  child: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: isFlashOn ? Colors.yellow : Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // COMPONENT: ACTION BAR
  // ==========================================
  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(icon: Icons.folder_open, label: "Thư viện", onTap: () {}),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: primaryBlue.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.photo_camera, color: Colors.white, size: 30),
            ),
          ),
        ),
        _buildActionButton(icon: Icons.upload, label: "Tải tệp lên", onTap: () {}),
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
            decoration: const BoxDecoration(color: surfaceCard, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  // ==========================================
  // NEW COMPONENT: HỂN THỊ DỮ LIỆU TỪ SERVER (TAB HOME)
  // ==========================================
  Widget _buildServerResultSection() {
    if (!hasServerResult) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: surfaceCard, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Text("Chưa có dữ liệu. Vui lòng chụp hoặc tải ảnh bo mạch lên.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }

    // Giao diện mẫu khi nhận kết quả thành công từ API
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: errorRed.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Mã bo mạch: PCB_MODEL_X1", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: errorRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: const Text("Phát hiện: 3 lỗi", style: TextStyle(color: errorRed, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          _buildResultDetailRow("Trạng thái kiểm định:", "Không Đạt (Failed)", errorRed),
          _buildResultDetailRow("Thời gian xử lý API:", "145ms", Colors.green),
          const SizedBox(height: 8),
          const Text("Chi tiết các tọa độ lỗi tìm thấy:", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          // Giả lập danh bạ mảng lỗi trả về từ AI Model
          _buildFaultLabel("1. Mouse Bite found at [X: 142, Y: 58]"),
          _buildFaultLabel("2. Open Circuit found at [X: 310, Y: 215]"),
          _buildFaultLabel("3. Short Circuit found at [X: 85, Y: 190]"),
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

  Widget _buildFaultLabel(String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
          const Icon(Icons.report_problem, color: errorRed, size: 16),
          const SizedBox(width: 8),
          Text(description, style: const TextStyle(color: Colors.amber, fontSize: 12, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  // ==========================================
  // COMPONENT: FILTER CHIPS (CHUYỂN SANG TAB HISTORY)
  // ==========================================
  Widget _buildFilterChips() {
    final filters = ["Tất cả", "Missing Hole", "Mouse Bite", "Open Circuit", "Short Circuit"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Bộ lọc quét lỗi AI", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = filters[index];
              final isSelected = filter == selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => selectedFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: isSelected ? primaryBlue : surfaceCard, borderRadius: BorderRadius.circular(20)),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPONENT: RECENT SCANS LIST (DẠNG DANH SÁCH DỌC TRONG TAB HISTORY)
  // ==========================================
  Widget _buildRecentScansList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Danh sách lịch sử quét", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: surfaceCard, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.broken_image, color: Colors.white30, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PCB_BATCH_00${6 - index}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text("Quét lúc: 10:02 - 18/06/2026", style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // COMPONENT: BOTTOM NAVIGATION BAR
  // ==========================================
  Widget _buildBottomNavBar() {
    return Container(
      color: surfaceCard,
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
              onTap: () => setState(() => selectedTab = "Home"), // Nút giữa tự động kích hoạt lại Home Cam
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.center_focus_strong, color: Colors.white, size: 28),
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
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.2)..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height / 3), Offset(size.width, size.height / 3), paint);
    canvas.drawLine(Offset(0, 2 * size.height / 3), Offset(size.width, 2 * size.height / 3), paint);
    canvas.drawLine(Offset(size.width / 3, 0), Offset(size.width / 3, size.height), paint);
    canvas.drawLine(Offset(2 * size.width / 3, 0), Offset(2 * size.width / 3, size.height), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}