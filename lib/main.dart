import 'package:dio/dio.dart';
import 'package:doan_local/screens/login_screen.dart';

import 'package:doan_local/services/dio_instances.dart';
import 'package:doan_local/theme/theme_manager.dart';
import 'package:doan_local/wrapper/admin_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:doan_local/screens/pcb_detector_screen.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

//http://n2.ckey.vn:2534
final Dio dio = Dio(BaseOptions(baseUrl: 'http://192.168.1.214:3000')); //local
//final Dio dio = Dio(BaseOptions(baseUrl: 'http://n2.ckey.vn:2534')); //server
//final Dio dio = Dio(BaseOptions(baseUrl: 'http://ckc.cntt.cloud:2534')); //server

void main() {
  DioClient.setup();



  runApp(const SessionManagerApp());
}

class SessionManagerApp extends StatefulWidget {
  const SessionManagerApp({super.key});

  @override
  State<SessionManagerApp> createState() => _SessionManagerAppState();
}

class _SessionManagerAppState extends State<SessionManagerApp> with WidgetsBindingObserver {
  int? _currentSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSession();
  }

  Future<void> _startSession() async {
    try {
      final response = await DioClient.deviceDio.post('/sessions/start');

      setState(() => _currentSessionId = response.data['session_id']);
      debugPrint("✅ Session bắt đầu: $_currentSessionId");
    } catch (e) {
      debugPrint("❌ Lỗi bắt đầu phiên: $e");
    }
  }

  Future<void> _endSession() async {
    if (_currentSessionId != null) {
      await DioClient.deviceDio.post(
          'sessions/end', data: {'session_id': _currentSessionId});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      _endSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: '/',
// Sử dụng onGenerateRoute thay thế cho thuộc tính routes tĩnh
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) =>
                  PCBDetectorScreen(
                    sessionId: _currentSessionId,
                  ),
            );

          case '/login':
            return MaterialPageRoute(
              builder: (context) =>
                  AdminLoginScreen(
                    isDarkMode: ThemeService.isDarkModeNotifier.value,
                    onSuccess: () {
                      Navigator.pushReplacementNamed(context, 'Admin');
                    },
                  ),
            );

          case 'Admin':
            return MaterialPageRoute(
              builder: (context) =>
                  ValueListenableBuilder<bool>(
                    valueListenable: ThemeService.isDarkModeNotifier,
                    builder: (context, isDarkMode, child) {
                      return AdminWrapper(
                        onLoginSuccess: () {
                          debugPrint("Đăng nhập thành công!");
                        },
                        isDarkMode: isDarkMode,
                      );
                    },
                  ),
            );

          default:
            return null;
        }
      },
    );
  }
}