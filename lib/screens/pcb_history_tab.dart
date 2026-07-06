import 'package:flutter/material.dart';
import 'package:doan_local/components/header_section.dart';
import 'package:doan_local/theme/theme_manager.dart';

class PCBHistoryTab extends StatefulWidget {
  final Color surfaceCard;
  final Color errorRed;
  final Color primaryBlue;
  final Color textColor;
  final bool isDarkMode;

  const PCBHistoryTab({
    super.key,
    required this.surfaceCard,
    required this.errorRed,
    required this.primaryBlue,
    required this.textColor,
    required this.isDarkMode,
  });

  @override
  State<PCBHistoryTab> createState() => _PCBHistoryTabState();
}

class _PCBHistoryTabState extends State<PCBHistoryTab> {
  String selectedFilter = "Tất cả";

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeaderSection(
                  title: "Lịch sử quét lỗi",
                  textColor: widget.textColor,
                  isDarkMode: isDarkMode,
                  onThemeChanged: (val) {
                    ThemeService.isDarkModeNotifier.value = val;
                  },
                ),
                _buildFilterChips(),
                const SizedBox(height: 24),
                _buildRecentScansList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    final filters = ["Tất cả", "Missing Hole", "Mouse Bite", "Open Circuit", "Short Circuit"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bộ lọc quét lỗi AI", style: TextStyle(color: widget.textColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
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
                  decoration: BoxDecoration(
                    color: isSelected ? widget.primaryBlue : widget.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? Colors.white : widget.textColor,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Danh sách lịch sử quét", style: TextStyle(color: widget.textColor.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: widget.surfaceCard, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(color: widget.textColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.broken_image, color: widget.textColor.withOpacity(0.3), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("PCB_BATCH_00${6 - index}", style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("Quét lúc: 10:02 - 18/06/2026", style: TextStyle(color: widget.textColor.withOpacity(0.5), fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: widget.textColor.withOpacity(0.3), size: 14),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}