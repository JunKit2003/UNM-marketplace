import 'package:intl/intl.dart';

final _whole = NumberFormat('#,##0', 'en_US');
final _cents = NumberFormat('#,##0.00', 'en_US');

/// `RM 1,234`, or `RM 12.50` when there are cents.
String formatPrice(num price) =>
    'RM ${price == price.roundToDouble() ? _whole.format(price) : _cents.format(price)}';

/// "just now", "5m ago", "2h ago", "3d ago", then a date like "1 Sep".
String timeAgo(DateTime when, {DateTime? now}) {
  final d = (now ?? DateTime.now().toUtc()).difference(when.toUtc());
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return DateFormat('d MMM', 'en_US').format(when.toLocal());
}

/// Clock time for chat bubbles, e.g. "14:05".
String clockTime(DateTime when) =>
    DateFormat('HH:mm', 'en_US').format(when.toLocal());
