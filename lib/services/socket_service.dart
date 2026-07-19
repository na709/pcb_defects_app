import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:typed_data';
import '../utils/device_helper.dart';


class SocketService {
  IO.Socket? _socket;
  final String _serverUrl = "http://192.168.1.214:3000";


  Future<void> connect({
    required Function(Map<String, dynamic>) onResultReceived,
    required Function(Map<String, dynamic>) onErrorReceived,
  }) async {
    if (_socket != null && _socket!.connected) return;

  //lấy id tbi
    final String? deviceId = await DeviceHelper.getDeviceId();

    _socket = IO.io(_serverUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .setExtraHeaders({
      'x-device-id': deviceId ?? 'unknown'
    })
        .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint("[SOCKET] Kết nối thành công với x-device-id: ${deviceId ?? 'unknown'}");
    });

    _socket!.on('realtime-result', (data) {
      if (data != null) onResultReceived(Map<String, dynamic>.from(data));
    });

    _socket!.on('realtime-error', (data) {
      if (data != null) onErrorReceived(Map<String, dynamic>.from(data));
    });

    _socket!.onDisconnect((_) {
      debugPrint("[SOCKET] Đã ngắt kết nối.");
    });
  }


  void streamFrame({
    required Uint8List imageBytes,
    required int? sessionId,
  }) {
    if (_socket == null || !_socket!.connected) return;

    _socket!.emit('stream-frame', {
      'imageBuffer': imageBytes,
      'session_id': sessionId ?? 1,
    });
  }

  void stopStream() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('stop-stream');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}