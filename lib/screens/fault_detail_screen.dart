import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:doan_local/models/fault_detail_model.dart';

import '../services/dio_instances.dart';
import '../theme/theme_manager.dart';
import '../utils/device_helper.dart';


class FaultDetailScreen extends StatefulWidget {
  final int historyId;


  const FaultDetailScreen({
    Key? key,
    required this.historyId,

  }) : super(key: key);

  @override
  State<FaultDetailScreen> createState() => _FaultDetailScreenState();
}

class _FaultDetailScreenState extends State<FaultDetailScreen> {
  FaultDetailResponse? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final String? deviceId = await DeviceHelper.getDeviceId();
      final response = await DioClient.deviceDio.get(
        "/fault-detail/${widget.historyId}",
        options: Options(headers: {"x-device-id": deviceId}),
      );

      setState(() {
        _data = FaultDetailResponse.fromJson(response.data);
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải chi tiết: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkModeNotifier,
      builder: (context, isDarkMode, child) {
        final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors
            .white;
        final textColor = isDarkMode ? Colors.white : Colors.black;
        final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text("Chi tiết phiên quét #${widget.historyId}",
                style: TextStyle(color: textColor)),
            backgroundColor: backgroundColor,
            iconTheme: IconThemeData(color: textColor),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildImageCard(
                    "Ảnh gốc", _data!.originalImage, cardColor, textColor),
                const SizedBox(height: 10),
                _buildImageCard(
                    "Ảnh đã xử lý", _data!.resultImage, cardColor, textColor),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text("Danh sách lỗi phát hiện:",
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor)),
                ),

                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _data!.faults.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: textColor.withOpacity(0.2)),
                  itemBuilder: (context, index) {
                    final fault = _data!.faults[index];
                    return ListTile(
                      leading: const Icon(Icons.bug_report, color: Colors.red),
                      title: Text(fault.faultClass, style: TextStyle(
                          color: textColor)),
                      subtitle: Text("Độ tin cậy: ${(fault.confidence * 100)
                          .toStringAsFixed(1)}%",
                          style: TextStyle(color: textColor.withOpacity(0.6))),
                      trailing: Text(
                        "[${fault.bbox[0].toInt()}, ${fault.bbox[1].toInt()}, ${fault.bbox[2].toInt()}, ${fault.bbox[3].toInt()}]",
                        style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard(String title, String imageUrl, Color cardColor,
      Color textColor) {
    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(title, style: TextStyle(
                  fontWeight: FontWeight.bold, color: textColor))
          ),
        ],
      ),
    );
  }
}