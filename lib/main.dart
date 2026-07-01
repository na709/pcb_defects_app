import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:doan_local/screens/pcb_detector_screen.dart';


void main() {
  runApp(const SessionManagerApp());
}


class SessionManagerApp extends StatefulWidget {
  const SessionManagerApp({super.key});

  @override
  State<SessionManagerApp> createState() => _SessionManagerAppState();
}

class _SessionManagerAppState extends State<SessionManagerApp> with WidgetsBindingObserver {
  final Dio _dio = Dio();
  String? _deviceId;
  int? _currentSessionId;
  final String serverUrl = 'http://192.168.1.214:3000';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeviceAndSession();
  }

  Future<void> _initDeviceAndSession() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      _deviceId = (await deviceInfo.androidInfo).id;
    } else if (Platform.isIOS) {
      _deviceId = (await deviceInfo.iosInfo).identifierForVendor;
    }
    await _startSession();
  }

  Future<void> _startSession() async {
    try {
      final response = await _dio.post(
        '$serverUrl/api/sessions/start',
        data: {'device_id': _deviceId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      setState(() => _currentSessionId = response.data['session_id']);
    } catch (e) {
      if (e is DioException) {
        print("Lỗi từ server: ${e.response?.data}");
      }
    }
  }

  Future<void> _endSession() async {
    if (_currentSessionId != null) {
      try {
        await _dio.post(
            '$serverUrl/api/sessions/end',
            data: {'session_id': _currentSessionId}
        );
        print("🔴 Chốt phiên thành công: $_currentSessionId");
      } catch (e) {
        print("Lỗi chốt phiên: $e");
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached || state == AppLifecycleState.paused) _endSession();
  }

  @override
    Widget build (BuildContext context){
    return MaterialApp(
      home: Scaffold(
        body: PCBDetectorScreen(deviceId:  _deviceId, sessionId: _currentSessionId,),
      )
    );
  }
}
