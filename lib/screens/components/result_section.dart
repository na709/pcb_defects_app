import 'package:flutter/material.dart';

class ResultSection extends StatelessWidget {
  final bool isAnalyzing;
  final bool hasServerResult;
  final String pcbInfoText;
  final List<String> mockFaults;
  final Color surfaceColor;
  final Color textColor;
  final bool isDarkMode;
  final bool isPcbPassed;
  final String pcbStatus;
  final String apiProcessingTime;
  final Color errorRed; // Thêm biến này để dùng chung

  const ResultSection({
    Key? key,
    required this.isAnalyzing,
    required this.hasServerResult,
    required this.pcbInfoText,
    required this.mockFaults,
    required this.surfaceColor,
    required this.textColor,
    required this.isDarkMode,
    required this.isPcbPassed,
    required this.pcbStatus,
    required this.apiProcessingTime,
    required this.errorRed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isAnalyzing) {
      return _buildContainer(child: const Text("Đang kết nối Server AI...", style: TextStyle(color: Colors.amber)));
    }
    if (!hasServerResult) {
      return _buildContainer(child: Text(pcbInfoText, style: const TextStyle(color: Colors.grey)));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPcbPassed ? Colors.green.withOpacity(0.3) : errorRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pcbInfoText, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)),
          const Divider(height: 20),
          _buildResultDetailRow("Trạng thái:", pcbStatus, isPcbPassed ? Colors.green : errorRed),
          _buildResultDetailRow("Thời gian xử lý:", apiProcessingTime, Colors.green),
          const SizedBox(height: 8),
          ...mockFaults.map((f) => _buildFaultLabel(f)),
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
    final parts = description.split(" found at ");
    final String errorTitle = parts.isNotEmpty ? parts[0] : description;
    final String coordinates = parts.length > 1 ? "Vị trí: ${parts[1]}" : "";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: isDarkMode ? Colors.black26 : Colors.black12, borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2.0), child: Icon(Icons.report_problem, color: errorRed, size: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorTitle, style: TextStyle(color: isDarkMode ? Colors.amber : const Color(0xFF0D47A1), fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                if (coordinates.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(coordinates, style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54, fontSize: 11, fontFamily: 'monospace')),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(12)), child: Center(child: child));
  }
}