import '../utils/parsers.dart';
import 'towing_delivery.dart';

class TowingSchedule {
  TowingSchedule({
    required this.id,
    required this.orderId,
    required this.truckId,
    required this.driverId,
    required this.scheduleDate,
    required this.suratJalanNumber,
    required this.status,
    required this.truckLabel,
    required this.driverName,
    required this.deliveries,
    required this.deliveryCount,
    required this.completedDeliveryCount,
  });

  final int id;
  final int orderId;
  final int truckId;
  final int driverId;
  final DateTime? scheduleDate;
  final String suratJalanNumber;
  final String status;
  final String truckLabel;
  final String driverName;
  final List<TowingDelivery> deliveries;
  final int deliveryCount;
  final int completedDeliveryCount;

  factory TowingSchedule.fromJson(Map<String, dynamic> json) {
    final deliveries = ensureJsonMapList(json['deliveries'])
        .map(TowingDelivery.fromJson)
        .toList(growable: false);

    final derivedCompletedCount =
        deliveries.where((delivery) => delivery.isCompleted).length;
    final totalDeliveryCount = firstPositiveInt([
      json['deliveries_count'],
      json['delivery_count'],
      deliveries.length,
    ], fallback: deliveries.length);
    final completedCount = firstPositiveInt([
      json['completed_deliveries_count'],
      json['completed_count'],
      derivedCompletedCount,
    ], fallback: derivedCompletedCount);

    return TowingSchedule(
      id: parseInt(json['id']),
      orderId: parseInt(json['order_id']),
      truckId: parseInt(json['truck_id']),
      driverId: parseInt(json['driver_id']),
      scheduleDate: parseDateTime(json['schedule_date']),
      suratJalanNumber: firstNonEmptyString([
        json['surat_jalan_number'],
        json['surat_jalan'],
      ], fallback: '-'),
      status: firstNonEmptyString([
        json['status'],
      ], fallback: _deriveStatus(deliveries, totalDeliveryCount, completedCount)),
      truckLabel: _parseTruckLabel(json),
      driverName: _parseDriverName(json),
      deliveries: deliveries,
      deliveryCount: totalDeliveryCount,
      completedDeliveryCount: completedCount,
    );
  }

  String get normalizedStatus => _normalizeStatus(status);

  bool get isCompleted =>
      normalizedStatus == 'completed' ||
      normalizedStatus == 'done' ||
      (deliveryCount > 0 && completedDeliveryCount >= deliveryCount);

  int get remainingDeliveryCount {
    final remaining = deliveryCount - completedDeliveryCount;
    return remaining > 0 ? remaining : 0;
  }

  double get progressValue {
    if (deliveryCount <= 0) {
      return 0;
    }

    return completedDeliveryCount / deliveryCount;
  }

  static String _parseTruckLabel(Map<String, dynamic> json) {
    final direct = firstNonEmptyString([
      json['truck_label'],
      json['truck_name'],
    ]);
    if (direct.isNotEmpty) {
      return direct;
    }

    final truck = ensureJsonMap(json['truck']);
    final combined = joinNonEmpty([
      parseString(truck['name']),
      parseString(truck['plate_number']),
    ], separator: ' • ');

    if (combined.isNotEmpty) {
      return combined;
    }

    final truckId = parseInt(json['truck_id']);
    if (truckId > 0) {
      return 'Truck #$truckId';
    }

    return 'Truck belum diatur';
  }

  static String _parseDriverName(Map<String, dynamic> json) {
    final direct = firstNonEmptyString([
      json['driver_name'],
      json['driver_label'],
    ]);
    if (direct.isNotEmpty) {
      return direct;
    }

    final driver = ensureJsonMap(json['driver']);
    final combined = joinNonEmpty([
      parseString(driver['name']),
      parseString(driver['driver_code']),
    ], separator: ' • ');

    if (combined.isNotEmpty) {
      return combined;
    }

    return 'Driver belum diatur';
  }

  static String _deriveStatus(
    List<TowingDelivery> deliveries,
    int totalDeliveryCount,
    int completedCount,
  ) {
    if (totalDeliveryCount > 0 && completedCount >= totalDeliveryCount) {
      return 'completed';
    }

    if (deliveries.any((delivery) => delivery.isInProgress)) {
      return 'in_progress';
    }

    if (deliveries.isNotEmpty) {
      return 'assigned';
    }

    return 'pending';
  }

  static String _normalizeStatus(String value) {
    return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
  }
}
