import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/storage_service.dart';


final Dio _dio = Dio(BaseOptions(
  baseUrl: "http://10.0.2.2:3000/api",
  connectTimeout: const Duration(seconds: 5),
));

class AdminLoginScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onSuccess;
  const AdminLoginScreen({super.key, required this.isDarkMode ,required this.onSuccess});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {

  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    debugPrint("Đang gửi login request tới: ${_dio.options.baseUrl}/admin/login");
    debugPrint("Username: ${_userController.text}");
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _dio.post('/admin/login', data: {
        "username": _userController.text,
        "password": _passController.text,
      });
      debugPrint("Kết quả server: ${response.data}");

      if (response.statusCode == 200) {
        final accessToken = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];
        await StorageService.saveTokens(accessToken, refreshToken);

        debugPrint("Token đã lưu thành công vào StorageService!");
        widget.onSuccess();
      }
    } on DioException catch (e) {
      debugPrint("LỖI CHI TIẾT: $e");
      String message = "Lỗi kết nối server";
      if (e.response?.statusCode == 401) {
        message = "Sai tài khoản hoặc mật khẩu";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? const Color(0xFF0F0F0F) : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final inputBg = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[200]!;
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text("Admin Login", style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),

              TextField(
                controller: _userController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  hintText: "Username",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputBg,
                  hintText: "Password",
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      :  Text("Login", style: TextStyle(fontSize: 16,color: textColor, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}