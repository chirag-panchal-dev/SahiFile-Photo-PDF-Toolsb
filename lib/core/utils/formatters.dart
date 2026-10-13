import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      final kb = bytes / 1024.0;
      final str =
          kb == kb.roundToDouble()
              ? kb.toStringAsFixed(0)
              : kb.toStringAsFixed(kb >= 100 ? 0 : 1);
      return '$str KB';
    }
    final mb = bytes / (1024.0 * 1024.0);
    final str =
        mb == mb.roundToDouble()
            ? mb.toStringAsFixed(0)
            : mb.toStringAsFixed(mb >= 100 ? 0 : 1);
    return '$str MB';
  }

  static String formatDimensions(int width, int height) {
    if (width <= 0 || height <= 0) return 'Unknown size';
    return '$width × $height px';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes <= 1) return 'Just now';
        return '${difference.inMinutes} mins ago';
      }
      return DateFormat('hh:mm a').format(date);
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('hh:mm a').format(date)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, hh:mm a').format(date);
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  static String formatSafeFileName(String baseName, String extension) {
    final cleanBase = baseName
        .replaceAll(RegExp(r'[^\w\s\-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '$cleanBase.$ext';
  }

  static String generateTimestampFileName(String prefix, String extension) {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd_HHmm').format(now);
    final ext = extension.startsWith('.') ? extension.substring(1) : extension;
    return '${prefix}_$dateStr.$ext';
  }
}
