import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Cấu hình URL Base local:
  // - Dùng '10.0.2.2' nếu bạn chạy trên giả lập Android Emulator mặc định.
  // - Thay bằng IP máy tính của bạn (vídụ: '192.168.1.X') nếu test bằng điện thoại thật chung Wi-Fi.
  static const String _baseUrl = "http://10.0.2.2:3000";

  /// Hàm gửi ảnh bo mạch lên Server Node.js và nhận về kết quả phân tích
  static Future<Map<String, dynamic>?> analyzePcbImage(File imageFile) async {
    try {
      final url = Uri.parse("$_baseUrl/api/analyze-pcb");

      var request = http.MultipartRequest('POST', url);

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        debugPrint("Server báo lỗi phản hồi: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Lỗi kết nối trong ApiService: $e");
      return null;
    }
  }
}