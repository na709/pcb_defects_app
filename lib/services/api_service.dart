import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = "http://10.0.2.2:3000";

  static Future<Map<String, dynamic>?> analyzePcbImage(File imageFile, String? deviceId, int? sessionId) async {
    try {
      final url = Uri.parse("$_baseUrl/api/analyze-pcb");

      var request = http.MultipartRequest('POST', url);

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.fields['device_id'] = deviceId ?? 'unknown_device';
      request.fields['session_id'] = sessionId?.toString() ?? '1';

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