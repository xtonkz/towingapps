class ApiConfig {
  static const baseUrl = 'https://kitchenbekasi.com/api';
  static const mobileBase = '$baseUrl/mobile';

  static const login = '$mobileBase/login';
  static const me = '$mobileBase/me';
  static const logout = '$mobileBase/logout';
  static const schedules = '$mobileBase/schedules';
  static const deliveries = '$mobileBase/deliveries';

  static String scheduleDetail(int scheduleId) => '$schedules/$scheduleId';

  static String deliveryDetail(int deliveryId) => '$deliveries/$deliveryId';

  static String startDelivery(int deliveryId) =>
      '$deliveries/$deliveryId/start';

  static String deliveryPhotos(int deliveryId) =>
      '$deliveries/$deliveryId/photos';

  static String completeDelivery(int deliveryId) =>
      '$deliveries/$deliveryId/complete';
}
