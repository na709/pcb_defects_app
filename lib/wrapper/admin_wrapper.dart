import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:doan_local/screens/admin_profile_screen.dart';
import 'package:doan_local/screens/login_screen.dart';



class AdminWrapper extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onLoginSuccess;
  const AdminWrapper({super.key,required this.isDarkMode, required this.onLoginSuccess});

  @override
  State<AdminWrapper> createState() => _AdminWrapperState();
}

class _AdminWrapperState extends State<AdminWrapper> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: 'accessToken');
    if (mounted) {
      setState(() => _isLoggedIn = (token != null));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn == null) return const Center(child: CircularProgressIndicator());

    return _isLoggedIn!
        ? AdminProfileScreen(isDarkMode: widget.isDarkMode)
        : AdminLoginScreen(
        isDarkMode: widget.isDarkMode,
        onSuccess: () {
          widget.onLoginSuccess();
      setState(() => _isLoggedIn = true);
    });
  }
}