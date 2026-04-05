import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'login_screen.dart';
import 'schedule_list_screen.dart';

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

      await _apiService.me();

      _goSchedules();
    } catch (_) {
      _goLogin();
    }
  }

  void _goLogin() {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _goSchedules() {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F4C5C),
              Color(0xFF1B6678),
              Color(0xFFF1F4F8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Color(0x1AF4B942),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      size: 42,
                      color: Color(0xFFF4B942),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Driver Towing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pantau jadwal pengiriman dan kirim report unit dari satu aplikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFD7E4EA),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 28),
                  CircularProgressIndicator(
                    color: Color(0xFFF4B942),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
