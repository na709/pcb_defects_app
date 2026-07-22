import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:doan_local/utils/device_helper.dart';

class ApiService {
  //static const String _baseUrl = "http://10.0.2.2:3000"; // local
  //static const String _baseUrl = "http://n2.ckey.vn:2534"; //server test
  static const String _baseUrl = "https://ckc.cntt.cloud"; //server test
  // static const String _baseUrl = "http://192.168.1.214:3000"; //tbi thật
  //static const String _baseUrl = "https://ckc.dvna.site"; //server test


  static Future<Map<String, dynamic>?> analyzePcbImage(File imageFile, String? deviceId, int? sessionId) async {
    try {
      final deviceId = await DeviceHelper.getDeviceId();
      final url = Uri.parse("$_baseUrl/api/analyze-pcb");

      var request = http.MultipartRequest('POST', url);

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      request.fields['device_id'] = deviceId ;
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