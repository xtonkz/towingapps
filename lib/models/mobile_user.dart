import '../utils/parsers.dart';

class MobileUser {
  MobileUser({
    required this.id,
    required this.username,
    required this.name,
    required this.phone,
    required this.driverCode,
    required this.isActive,
  });

  final int id;
  final String username;
  final String name;
  final String phone;
  final String driverCode;
  final bool isActive;

  String get displayName => name.isNotEmpty ? name : username;

  String get identityLabel {
    if (driverCode.isEmpty) {
      return username;
    }

    return '$driverCode • $username';
  }

  factory MobileUser.fromJson(Map<String, dynamic> json) {
    return MobileUser(
      id: parseInt(json['id']),
      username: parseString(json['username']),
      name: firstNonEmptyString([json['name'], json['full_name']]),
      phone: parseString(json['phone']),
      driverCode: firstNonEmptyString([
        json['driver_code'],
        json['code'],
      ]),
      isActive: parseBool(json['is_active'], fallback: true),
    );
  }
}
