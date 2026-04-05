import '../utils/parsers.dart';

class DeliveryPhotoRequirement {
  const DeliveryPhotoRequirement({
    required this.type,
    required this.label,
    this.url,
  });

  final String type;
  final String label;
  final String? url;

  bool get hasPhoto => url != null && url!.trim().isNotEmpty;
}

class TowingDelivery {
  TowingDelivery({
    required this.id,
    required this.orderId,
    required this.scheduleId,
    required this.unitId,
    required this.unitLabel,
    required this.routeLabel,
    required this.routeCategory,
    required this.deliveryPurpose,
    required this.deliveryStatus,
    required this.pickupDateTime,
    required this.deliveryDateTime,
    required this.photoUrlByType,
  });

  static const String photoUnit = 'foto_unit';
  static const String photoUnitDitowing = 'foto_unit_ditowing';
  static const String photoSuratJalan = 'foto_surat_jalan';

  static const Map<String, String> requiredPhotoTypes = {
    photoUnit: 'Foto Unit',
    photoUnitDitowing: 'Foto Unit Ditowing',
    photoSuratJalan: 'Foto Surat Jalan',
  };

  final int id;
  final int orderId;
  final int scheduleId;
  final int unitId;
  final String unitLabel;
  final String routeLabel;
  final String routeCategory;
  final String deliveryPurpose;
  final String deliveryStatus;
  final DateTime? pickupDateTime;
  final DateTime? deliveryDateTime;
  final Map<String, String?> photoUrlByType;

  factory TowingDelivery.fromJson(Map<String, dynamic> json) {
    final photoUrls = _parsePhotoUrls(json);

    return TowingDelivery(
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']),
      scheduleId: parseInt(json['schedule_id']),
      unitId: parseInt(json['unit_id']),
      unitLabel: _parseUnitLabel(json),
      routeLabel: _parseRouteLabel(json),
      routeCategory: parseString(json['route_category']),
      deliveryPurpose: parseString(json['delivery_purpose']),
      deliveryStatus: firstNonEmptyString([
        json['delivery_status'],
        json['status'],
      ], fallback: 'pending'),
      pickupDateTime: parseDateTime(json['pickup_datetime']),
      deliveryDateTime: parseDateTime(json['delivery_datetime']),
      photoUrlByType: Map.unmodifiable(photoUrls),
    );
  }

  String get normalizedStatus => _normalizeStatus(deliveryStatus);

  bool get isCompleted => const [
        'completed',
        'done',
        'delivered',
        'finished',
        'success',
      ].contains(normalizedStatus);

  bool get isInProgress => const [
        'in_progress',
        'process',
        'processing',
        'started',
        'on_delivery',
        'ongoing',
      ].contains(normalizedStatus);

  bool get canStart => !isCompleted && const [
        '',
        'pending',
        'assigned',
        'scheduled',
        'ready',
      ].contains(normalizedStatus);

  int get uploadedRequiredPhotoCount =>
      requiredPhotos.where((photo) => photo.hasPhoto).length;

  bool get hasAllRequiredPhotos =>
      uploadedRequiredPhotoCount == requiredPhotoTypes.length;

  List<DeliveryPhotoRequirement> get requiredPhotos {
    return requiredPhotoTypes.entries
        .map(
          (entry) => DeliveryPhotoRequirement(
            type: entry.key,
            label: entry.value,
            url: photoUrlByType[entry.key],
          ),
        )
        .toList(growable: false);
  }

  static String _parseUnitLabel(Map<String, dynamic> json) {
    final directLabel = firstNonEmptyString([
      json['unit_label'],
      json['unit_name'],
    ]);
    if (directLabel.isNotEmpty) {
      return directLabel;
    }

    final unit = ensureJsonMap(json['unit']);
    final combined = joinNonEmpty([
      parseString(unit['brand']),
      parseString(unit['model']),
      parseString(unit['plate_number']),
    ], separator: ' - ');

    if (combined.isNotEmpty) {
      return combined;
    }

    final unitId = parseInt(json['unit_id']);
    if (unitId > 0) {
      return 'Unit #$unitId';
    }

    return 'Unit belum diatur';
  }

  static String _parseRouteLabel(Map<String, dynamic> json) {
    final direct = parseString(json['route_label']);
    if (direct.isNotEmpty) {
      return direct;
    }

    final unit = ensureJsonMap(json['unit']);
    final fallback = joinNonEmpty([
      parseString(unit['pickup_location']),
      parseString(unit['delivery_location']),
    ], separator: ' -> ');

    if (fallback.isNotEmpty) {
      return fallback;
    }

    return firstNonEmptyString([
      json['delivery_purpose'],
      json['route_category'],
    ], fallback: 'Rute belum diatur');
  }

  static Map<String, String?> _parsePhotoUrls(Map<String, dynamic> json) {
    final urls = <String, String?>{
      for (final type in requiredPhotoTypes.keys) type: null,
    };

    final uploadedPhotos = ensureJsonMap(json['uploaded_photos']);
    for (final type in requiredPhotoTypes.keys) {
      final directUrl = parseString(uploadedPhotos[type]);
      if (directUrl.isNotEmpty) {
        urls[type] = directUrl;
      }
    }

    for (final photo in ensureJsonMapList(json['photos'])) {
      final type = parseString(photo['photo_type']);
      if (type.isEmpty || !requiredPhotoTypes.containsKey(type)) {
        continue;
      }

      final url = firstNonEmptyString([
        photo['photo_url'],
        photo['url'],
        photo['path'],
      ]);

      if (url.isNotEmpty) {
        urls[type] = url;
      }
    }

    return urls;
  }

  static String _normalizeStatus(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }
}
