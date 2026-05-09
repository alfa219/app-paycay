import 'package:intl/intl.dart';

abstract class AppFormatters {
  static final _currencyFmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String currency(num amount) {
    final sign = amount < 0 ? '-' : '';
    return sign + _currencyFmt.format(amount.abs());
  }

  static String duration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String durationMinutes(int seconds) {
    return '${seconds ~/ 60} menit';
  }

  static String countdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String compactAmount(num amount) {
    final sign = amount < 0 ? '' : '+';
    return '$sign${currency(amount)}';
  }

  static String relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('d MMM yyyy', 'id_ID').format(time);
  }
}
