import 'package:flutter/material.dart';
import '../screens/delivery_detail_screen.dart';
import '../screens/login_screen.dart';
import '../screens/schedule_detail_screen.dart';
import '../screens/schedule_list_screen.dart';
import '../screens/splash_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String schedules = '/schedules';
  static const String scheduleDetail = '/schedule-detail';
  static const String deliveryDetail = '/delivery-detail';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case schedules:
        return MaterialPageRoute(
          builder: (_) => const ScheduleListScreen(),
          settings: settings,
        );
      case scheduleDetail:
        final scheduleId = settings.arguments as int?;
        if (scheduleId == null) {
          return _errorRoute(settings, 'Schedule ID tidak ditemukan.');
        }

        return MaterialPageRoute(
          builder: (_) => ScheduleDetailScreen(scheduleId: scheduleId),
          settings: settings,
        );
      case deliveryDetail:
        final deliveryId = settings.arguments as int?;
        if (deliveryId == null) {
          return _errorRoute(settings, 'Delivery ID tidak ditemukan.');
        }

        return MaterialPageRoute(
          builder: (_) => DeliveryDetailScreen(deliveryId: deliveryId),
          settings: settings,
        );
      default:
        return _errorRoute(settings, 'Halaman tidak tersedia.');
    }
  }

  static MaterialPageRoute<void> _errorRoute(
    RouteSettings settings,
    String message,
  ) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Oops')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
