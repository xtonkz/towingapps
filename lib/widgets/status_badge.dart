import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = _resolvePalette(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatStatusLabel(status),
        style: TextStyle(
          color: palette.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  _BadgePalette _resolvePalette(String rawStatus) {
    final status = rawStatus.trim().toLowerCase().replaceAll('-', '_');

    if (const ['completed', 'done', 'delivered', 'finished', 'success']
        .contains(status)) {
      return const _BadgePalette(
        background: Color(0xFFDDF6E8),
        foreground: Color(0xFF177245),
      );
    }

    if (const [
      'in_progress',
      'process',
      'processing',
      'started',
      'on_delivery',
      'ongoing',
    ].contains(status)) {
      return const _BadgePalette(
        background: Color(0xFFFFF2D8),
        foreground: Color(0xFFA16207),
      );
    }

    return const _BadgePalette(
      background: Color(0xFFDDEAFB),
      foreground: Color(0xFF0F4C81),
    );
  }
}

class _BadgePalette {
  const _BadgePalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
