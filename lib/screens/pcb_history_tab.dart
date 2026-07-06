import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:doan_local/components/header_section.dart';
import 'package:doan_local/theme/theme_manager.dart';
import 'package:doan_local/models/scan_result.dart';
import 'package:cached_network_image/cached_network_image.dart';



class PCBHistoryTab extends StatefulWidget {
  final Color surfaceCard;
  final Color errorRed;
  final Color primaryBlue;
  final Color textColor;
  final bool isDarkMode;

  const PCBHistoryTab({super.key, required this.surfaceCard, required this.errorRed, required this.primaryBlue, required this.textColor, required this.isDarkMode});

  @override
  State<PCBHistoryTab> createState() => _PCBHistoryTabState();
}

class _PCBHistoryTabState extends State<PCBHistoryTab> {
  String selectedFilter = "Tất cả";
  List<ScanResult> _historyList = [];
  bool _isLoading = true;
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:3000'));

  @override
  void initState() {
    super.initState();
    _fetchHistory("Tất cả");
  }

  Future<void> _fetchHistory(String filter) async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get('/api/history',
          queryParameters: {'type': filter},
          options: Options(headers: {'x-device-id': 'BE2A.250530.026.F3'})
      );
      setState(() {
        _historyList = (response.data as List).map((i) => ScanResult.fromJson(i)).toList();
      });
    } catch (e) {
      debugPrint("Lỗi tải lịch sử: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderSection(title: "Lịch sử quét lỗi", textColor: widget.textColor, isDarkMode: isDarkMode, onThemeChanged: (val) => ThemeService.isDarkModeNotifier.value = val),
              _buildFilterChips(),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildRecentScansList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final Map<String, String> _filterMap = {
      "Tất cả": "Tất cả",
      "Missing Hole": "missing_hole",
      "Mouse Bite": "mouse_bite",
      "Open Circuit": "open_circuit",
      "Spur": "spur",
      "Short Circuit": "short"
    };
    final displayFilters = _filterMap.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bộ lọc quét lỗi AI", style: TextStyle(color: widget.textColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayFilters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final display = displayFilters[index];
              final apiValue = _filterMap[display];
              final isSelected = display == selectedFilter;

              return GestureDetector(
                onTap: () {
                  setState(() => selectedFilter = display);
                  _fetchHistory(apiValue!);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? widget.primaryBlue : widget.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      display,
                      style: TextStyle(
                        color: isSelected ? Colors.white : widget.textColor,
                        fontSize: 13,
                      ),
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

  Widget _buildRecentScansList() {
    if (_historyList.isEmpty) return Center(child: Text("Không có lịch sử quét", style: TextStyle(color: widget.textColor.withOpacity(0.5))));

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _historyList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _historyList[index];
        final date = DateTime.tryParse(item.createdAt) ?? DateTime.now();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: widget.surfaceCard,
              borderRadius: BorderRadius.circular(12)
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.originalImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(color: Colors.grey[800]),
                  errorWidget: (context, url, error) => Icon(Icons.broken_image),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        "PCB_BATCH_${item.id}",
                        style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 4),
                    Text(
                        "Quét lúc: ${DateFormat('HH:mm - dd/MM/yyyy').format(date)}",
                        style: TextStyle(color: widget.textColor.withOpacity(0.5), fontSize: 11)
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (item.faultCount == 0 ? Colors.green : Colors.redAccent).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.faultCount == 0 ? "Đạt" : "Lỗi: ${item.faultCount}",
                  style: TextStyle(
                    color: item.faultCount == 0 ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}