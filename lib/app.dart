import 'package:flutter/material.dart';
import 'routes/app_routes.dart';

class DriverTowingApp extends StatelessWidget {
  const DriverTowingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F4C5C),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF0F4C5C),
      onPrimary: Colors.white,
      secondary: const Color(0xFFF4B942),
      onSecondary: const Color(0xFF1E1E1E),
      surface: const Color(0xFFF6F8FB),
      onSurface: const Color(0xFF17212B),
      error: const Color(0xFFB3261E),
      onError: Colors.white,
    );

    return MaterialApp(
      title: 'Driver Towing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF1F4F8),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF1F4F8),
          foregroundColor: Color(0xFF17212B),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFE1E7EF)),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD4DCE6)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD4DCE6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(
              color: Color(0xFF0F4C5C),
              width: 1.4,
            ),
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
