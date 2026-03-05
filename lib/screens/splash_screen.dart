import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'delivery_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      final token = await _apiService.getToken();

      if (token == null) {
        _goLogin();
        return;
      }

      // VALIDATE TOKEN BY CALLING /me
      await _apiService.me();

      _goDelivery();
    } catch (_) {
      _goLogin();
    }
  }

  void _goLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goDelivery() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DeliveryListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Driver Towing App',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
