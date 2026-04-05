import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/mobile_user.dart';
import '../models/towing_delivery.dart';
import '../models/towing_schedule.dart';
import '../utils/formatters.dart';
import '../utils/parsers.dart';

class ApiService {
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    final body = _decodeBody(response.body);
    if (!_isSuccess(response.statusCode)) {
      throw Exception(
        _extractErrorMessage(
          body,
          fallback: 'Login gagal. Periksa username dan password.',
        ),
      );
    }

    final payload = _extractObjectPayload(body);
    final token = firstNonEmptyString([
      body['access_token'],
      body['token'],
      payload['access_token'],
      payload['token'],
    ]);

    if (token.isEmpty) {
      throw Exception('Token login tidak ditemukan pada response backend.');
    }

    await saveToken(token);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, String>> authHeader({
    bool includeJsonContentType = false,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    if (includeJsonContentType) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Future<void> logout() async {
    try {
      final headers = await authHeader();
      await http.post(
        Uri.parse(ApiConfig.logout),
        headers: headers,
      );
    } finally {
      await clearToken();
    }
  }

  Future<MobileUser> me() async {
    final headers = await authHeader();
    final response = await http.get(
      Uri.parse(ApiConfig.me),
      headers: headers,
    );

    final body = _decodeBody(response.body);
    if (response.statusCode == 401) {
      await clearToken();
      throw Exception('Sesi login berakhir. Silakan masuk lagi.');
    }

    if (!_isSuccess(response.statusCode)) {
      throw Exception(
        _extractErrorMessage(body, fallback: 'Gagal memuat profil driver.'),
      );
    }

    return MobileUser.fromJson(
      _extractObjectPayload(body, preferredKeys: const ['data', 'user']),
    );
  }

  Future<List<TowingSchedule>> fetchSchedules({
    DateTime? date,
  }) async {
    final headers = await authHeader();
    final uri = Uri.parse(ApiConfig.schedules).replace(
      queryParameters: <String, String>{
        if (date != null) 'date': formatDateForApi(date),
      },
    );

    final response = await http.get(uri, headers: headers);
    final body = _decodeBody(response.body);

    if (!_isSuccess(response.statusCode)) {
      throw Exception(
        _extractErrorMessage(body, fallback: 'Gagal memuat jadwal driver.'),
      );
    }

    return _extractListPayload(
      body,
      preferredKeys: const ['data', 'schedules', 'items'],
    ).map(TowingSchedule.fromJson).toList(growable: false);
  }

  Future<TowingSchedule> fetchScheduleDetail(int scheduleId) async {
    final headers = await authHeader();
    final response = await http.get(
      Uri.parse(ApiConfig.scheduleDetail(scheduleId)),
      headers: headers,
    );
    final body = _decodeBody(response.body);

    if (!_isSuccess(response.statusCode)) {
      throw Exception(
        _extractErrorMessage(body, fallback: 'Gagal memuat detail jadwal.'),
      );
    }

    return TowingSchedule.fromJson(
      _extractObjectPayload(
        body,
        preferredKeys: const ['data', 'schedule'],
      ),
    );
  }

  Future<TowingDelivery> fetchDeliveryDetail(int deliveryId) async {
    final headers = await authHeader();
    final response = await http.get(
      Uri.parse(ApiConfig.deliveryDetail(deliveryId)),
      headers: headers,
    );
    final body = _decodeBody(response.body);

    if (!_isSuccess(response.statusCode)) {
      throw Exception(
        _extractErrorMessage(body, fallback: 'Gagal memuat detail delivery.'),
      );
    }

    return TowingDelivery.fromJson(
      _extractObjectPayload(
        body,
        preferredKeys: const ['data', 'delivery'],
      ),
    );
  }

  Future<void> startDelivery(int deliveryId) async {
    await _postWithoutBody(
      Uri.parse(ApiConfig.startDelivery(deliveryId)),
      failureMessage: 'Gagal memulai pengiriman.',
    );
  }

  Future<void> completeDelivery(int deliveryId) async {
    await _postWithoutBody(
      Uri.parse(ApiConfig.completeDelivery(deliveryId)),
      failureMessage: 'Gagal menyelesaikan pengiriman.',
    );
  }

  Future<void> uploadDeliveryPhoto({
    required int deliveryId,
    required String photoType,
    required XFile file,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.deliveryPhotos(deliveryId)),
    )
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      })
      ..fields['photo_type'] = photoType
      ..files.add(
        await http.MultipartFile.fromPath(
          'photo',
          file.path,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decodeBody(response.body);

    if (!_isSuccess(response.statusCode)) {
      throw Exception(
        _extractErrorMessage(body, fallback: 'Upload foto gagal.'),
      );
    }
  }

  Future<void> _postWithoutBody(
    Uri uri, {
    required String failureMessage,
  }) async {
    final headers = await authHeader(includeJsonContentType: true);
    final response = await http.post(uri, headers: headers);
    final body = _decodeBody(response.body);

    if (!_isSuccess(response.statusCode)) {
      throw Exception(_extractErrorMessage(body, fallback: failureMessage));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  dynamic _decodeBody(String body) {
    if (body.trim().isEmpty) {
      return const <String, dynamic>{};
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  Map<String, dynamic> _extractObjectPayload(
    dynamic body, {
    List<String> preferredKeys = const ['data'],
  }) {
    final root = ensureJsonMap(body);
    for (final key in preferredKeys) {
      final value = root[key];
      if (value is Map) {
        return ensureJsonMap(value);
      }
    }

    return root;
  }

  List<Map<String, dynamic>> _extractListPayload(
    dynamic body, {
    List<String> preferredKeys = const ['data'],
  }) {
    if (body is List) {
      return ensureJsonMapList(body);
    }

    final root = ensureJsonMap(body);
    for (final key in preferredKeys) {
      final value = root[key];
      if (value is List) {
        return ensureJsonMapList(value);
      }

      if (value is Map) {
        final nested = ensureJsonMap(value);
        for (final nestedKey in preferredKeys) {
          if (nested[nestedKey] is List) {
            return ensureJsonMapList(nested[nestedKey]);
          }
        }
      }
    }

    return const <Map<String, dynamic>>[];
  }

  String _extractErrorMessage(
    dynamic body, {
    required String fallback,
  }) {
    final root = ensureJsonMap(body);
    final message = parseString(root['message']);
    if (message.isNotEmpty) {
      return message;
    }

    final errors = root['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return parseString(value.first, fallback: fallback);
        }

        final item = parseString(value);
        if (item.isNotEmpty) {
          return item;
        }
      }
    }

    return fallback;
  }
}
