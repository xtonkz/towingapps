import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DeliveryListScreen extends StatefulWidget {
  const DeliveryListScreen({super.key});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  final ApiService _apiService = ApiService();
  String _status = 'Checking token...';

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    try {
      final token = await _apiService.getToken();
      setState(() {
        _status = token != null ? 'JWT OK' : 'Token missing';
      });
    } catch (e) {
      setState(() {
        _status = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Deliveries')),
      body: Center(
        child: Text(
          _status,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
