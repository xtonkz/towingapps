import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

class ApiService {
  /// LOGIN
  Future<String> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Login failed');
    }

    final data = jsonDecode(response.body);
    return data['access_token'];
  }

  ///GET TOKEN
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// AUTH HEADER (UNTUK REQUEST SELANJUTNYA)
  Future<Map<String, String>> authHeader() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    return {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// LOGOUT
  Future<void> logout() async {
    final headers = await authHeader();
    await http.post(
      Uri.parse(ApiConfig.logout),
      headers: headers,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  /// GET CURRENT USER (TOKEN VALIDATION)
  Future<Map<String, dynamic>> me() async {
    final headers = await authHeader();

    final response = await http.get(
      Uri.parse(ApiConfig.me),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Unauthorized');
    }

    return jsonDecode(response.body);
  }
}
