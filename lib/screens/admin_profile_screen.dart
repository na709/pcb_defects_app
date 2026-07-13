import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:doan_local/models/dashboard_model.dart';
import '../services/dio_instances.dart';
import 'package:open_file/open_file.dart';


class AdminProfileScreen extends StatefulWidget {
  final bool isDarkMode;
  const AdminProfileScreen({super.key,required this.isDarkMode});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late Future<DashboardStats> _statsFuture;
  Color get bgColor => widget.isDarkMode ? const Color(0xFF0F0F0F) : Colors.white;
  Color get surfaceColor => widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200]!;
  Color get textColor => widget.isDarkMode ? Colors.white : Colors.black;



  @override
  void initState() {
    super.initState();
    _statsFuture = fetchDashboardData();
  }

  Future<DashboardStats> fetchDashboardData() async {
    final response = await DioClient.adminDio.get('/admin/dashboard-stats');
    debugPrint("--- DEBUG REQUEST ADMIN ---");
    debugPrint("Headers: ${DioClient.adminDio.options.headers}");
    debugPrint("Token đang dùng: ${DioClient.adminDio.options.headers['Authorization']}");
    return DashboardStats.fromJson(response.data);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF0F0F0F) : Colors.white;
    return Scaffold(
      backgroundColor: bgColor,
      body: FutureBuilder<DashboardStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));

          final stats = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(stats.admin),
                const SizedBox(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Thống kê Batch hôm nay", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                _buildStatisticsChart(stats),
                const SizedBox(height: 20),
                _buildLegend(stats.faultBreakdown),
                const SizedBox(height: 24),
                _buildManagementSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsChart(DashboardStats stats) {

    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
      child: BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, BarTouchResponse? touchResponse) {
              if (event is FlTapUpEvent && touchResponse != null && touchResponse.spot != null) {
                int x = touchResponse.spot!.touchedBarGroupIndex;
                if (x == 2) {
                  _showFaultDetailsDialog(context, stats.faultBreakdown);
                }
              }
            },
          ),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
              final style = TextStyle(color: textColor.withOpacity(0.7), fontSize: 12);
              if (v == 0) return  Text('Tổng', style: style);
              if (v == 1) return  Text('Đạt', style: style);
              return  Text('Lỗi', style: style);
            })),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: stats.total.toDouble(), color: Colors.blue, width: 30,
              borderRadius: BorderRadius.circular(4),)]),
            BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: stats.passed.toDouble(), color: Colors.green, width: 30,
              borderRadius: BorderRadius.circular(4),)]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(
                toY: stats.failed.toDouble(),
                width: 30,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                rodStackItems: _generateStackItems(stats.faultBreakdown),
              ),
            ]),
          ],
        ),
      ),
    );
  }
  void _showFaultDetailsDialog(BuildContext context, List<FaultData> faults) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Chi tiết các loại lỗi", style: TextStyle(color: textColor)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: faults.length,
            separatorBuilder: (_, __) => Divider(color: textColor),
            itemBuilder: (context, index) {
              final fault = faults[index];
              return ListTile(
                title: Text(fault.faultClass, style: TextStyle(color: textColor)),
                trailing: Text("${fault.count}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng"))
        ],
      ),
    );
  }

  List<BarChartRodStackItem> _generateStackItems(List<FaultData> faults) {
    double currentY = 0;
    return faults.map((f) {
      double start = currentY;
      currentY += f.count;
      return BarChartRodStackItem(start, currentY, _getColorForFault(f.faultClass));
    }).toList();
  }

  Color _getColorForFault(String faultClass) {
    switch (faultClass.toLowerCase()) {
      case 'spur': return Colors.purple;
      case 'missing_hole': return Colors.orange;
      case 'mouse_bite': return Colors.red;
      case 'open_circuit': return Colors.blue;
      case 'short_circuit': return Colors.yellow;
      case 'spurious_copper': return Colors.teal;
      default: return Colors.grey;
    }
  }

  Future<void> _handleLogout() async {
    final storage = const FlutterSecureStorage();
    String? refreshToken = await storage.read(key: 'refreshToken');

    try {
      await DioClient.adminDio.post('/admin/logout', data: {'refreshToken': refreshToken});
    } catch (e) {
      debugPrint("Lỗi khi hủy token trên server: $e");
    }

    await storage.deleteAll();

    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _buildLegend(List<FaultData> faults) {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: faults.map((f) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: _getColorForFault(f.faultClass)),
          const SizedBox(width: 4),
          Text(f.faultClass, style: TextStyle(color: textColor, fontSize: 12)),
        ],
      )).toList(),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> admin) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.admin_panel_settings, size: 30, color: textColor)
        ),
        const SizedBox(width: 16),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  admin['full_name'] ?? "Admin",
                  style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              Text(
                  (admin['role'] ?? "admin") == 'super_admin'
                      ? "Super Admin"
                      : (admin['role'] as String).toUpperCase(),
                  style: TextStyle(color: textColor)
              ),
            ]
        )
      ],
    ),
  );

  Widget _buildManagementSection(BuildContext context) => Column(
    children: [
      _buildMenuItem(Icons.file_copy,
        "Xuất file báo cáo",
        onTap: () => _handleExportReport(context),
      ),
      _buildMenuItem(
        Icons.logout,
        "Đăng xuất",
        onTap: () => _handleLogout(),
      )
    ],
  );


  Future<void> _handleExportReport(BuildContext context) async {

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tạo và tải báo cáo...")));
    String start = picked.start.toIso8601String().split('T')[0];
    String end = picked.end.toIso8601String().split('T')[0];

    try {
      final response = await DioClient.adminDio.get(
        "/admin/export-pdf",
        queryParameters: {
        "startDate": start,
        "endDate": end,
      },
      );

      if (response.statusCode == 200) {
        final String downloadLink = response.data['downloadLink'];

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tải báo cáo...")));

        // Dùng thư viện này để tải về thư mục Public/Downloads
        await FileDownloader.downloadFile(
          url: downloadLink,
          name: 'BaoCao_PCB_${DateTime.now().millisecondsSinceEpoch}.pdf',
          onDownloadCompleted: (String path) {
            // Khi tải xong, mở file ngay lập tức
            OpenFile.open(path);
          },
          onDownloadError: (String error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Tải lỗi: $error")));
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi hệ thống: $e")));
    }
  }

  Widget _buildMenuItem(IconData icon, String title, {Color color = Colors.white, VoidCallback? onTap}) => Card(
    color: surfaceColor,
    child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor))
    ),
  );
}