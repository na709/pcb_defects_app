import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Admin Console"), backgroundColor: Colors.transparent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),

            // THAY THẾ GRID BẰNG BIỂU ĐỒ
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Thống kê Batch hôm nay",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            _buildStatisticsChart(context),
            const SizedBox(height: 20),
            _buildLegend(),

            const SizedBox(height: 24),
            _buildManagementSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsChart(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,

          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              if (event is FlTapUpEvent &&
                  response != null &&
                  response.spot != null &&
                  response.spot!.touchedBarGroupIndex == 2) { // Index 2 là cột Lỗi
                _showErrorDetailDialog(context); // Gọi hàm hiển thị Dialog
              }
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent, // Ẩn tooltip mặc định vì ta dùng Dialog
            ),
          ),

          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const style = TextStyle(color: Colors.white70, fontSize: 12);
                  switch (value.toInt()) {
                    case 0: return const Text('Tổng', style: style);
                    case 1: return const Text('Đạt', style: style);
                    case 2: return const Text('Lỗi', style: style);
                    default: return const Text('');
                  }
                },
              ),
            ),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(
                  toY: 1000,
                  color: Colors.blue,
                  width: 20,
                  borderRadius: BorderRadius.zero
              )
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(
                  toY: 700,
                  color: Colors.green,
                  width: 20,
                  borderRadius: BorderRadius.zero
              )
            ]),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: 300,
                  width: 20,
                  borderRadius: BorderRadius.zero,
                  rodStackItems: [
                    // Màu lạnh/nhạt ở dưới trước
                    BarChartRodStackItem(0, 27, Colors.blue),      // Open Circuit
                    BarChartRodStackItem(27, 50, Colors.purple),   // Spur
                    BarChartRodStackItem(50, 115, Colors.teal),    // Spurious Copper
                    // Màu đậm/rực ở trên sau
                    BarChartRodStackItem(115, 145, Colors.orange), // Missing Hole
                    BarChartRodStackItem(145, 235, Colors.red),    // Mouse Bite
                    BarChartRodStackItem(235, 300, Colors.yellow), // Short Circuit
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final Map<String, Color> legendItems = {
      "Missing Hole": Colors.orange,
      "Mouse Bite": Colors.red,
      "Open Circuit": Colors.blue,
      "Spur": Colors.purple,
      "Spurious Copper": Colors.teal,
      "Short Circuit": Colors.yellow,
    };

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: legendItems.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, color: entry.value),
            const SizedBox(width: 4),
            Text(entry.key, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }

  void _showErrorDetailDialog(BuildContext context) {
    final Map<String, int> errorDetails = {
      "Missing Hole": 30,
      "Mouse Bite": 90,
      "Open Circuit": 27,
      "Spur": 23,
      "Spurious Copper": 65,
      "Short Circuit": 65,
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Chi tiết các loại lỗi", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: errorDetails.entries.map((entry) => ListTile(
            title: Text(entry.key, style: const TextStyle(color: Colors.white70)),
            trailing: Text("${entry.value}", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 30, backgroundColor: Colors.blueAccent, child: Icon(Icons.admin_panel_settings, size: 30, color: Colors.white)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Đặng Võ Nhật Anh", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Super Admin - TechZ", style: TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard("Thiết bị", "15", Icons.devices_other),
        _buildStatCard("Lỗi đang chờ", "03", Icons.warning_amber),
        _buildStatCard("Batch hôm nay", "128", Icons.fact_check),
        _buildStatCard("Uptime", "99.9%", Icons.speed),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(Icons.manage_accounts, "Quản lý User"),
        _buildMenuItem(Icons.dns, "Cấu hình Server"),
        _buildMenuItem(Icons.summarize, "Xuất báo cáo hệ thống"),
        _buildMenuItem(Icons.logout, "Đăng xuất", color: Colors.redAccent),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = Colors.white}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}