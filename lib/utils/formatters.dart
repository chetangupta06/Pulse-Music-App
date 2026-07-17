import 'package:intl/intl.dart';

String formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(1, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (duration.inHours > 0) {
    return '${duration.inHours}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String compactNumber(num value) {
  return NumberFormat.compact(locale: 'en_IN').format(value);
}

String friendlyDate(DateTime value) {
  return DateFormat('d MMM').format(value);
}
