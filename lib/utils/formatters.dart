String formatDate(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String formatTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTime(DateTime? value) {
  if (value == null) {
    return '-';
  }

  return '${formatDate(value)} ${formatTime(value)}';
}

String formatDateForApi(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String formatStatusLabel(String status) {
  final normalized = status.trim();
  if (normalized.isEmpty) {
    return 'Belum Diatur';
  }

  return normalized
      .split(RegExp(r'[_\-\s]+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}
