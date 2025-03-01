import 'package:intl/intl.dart';

class DateTimeUtils {
  // Formatiert ein DateTime-Objekt als Wochentag (z.B. "Montag")
  static String formatWeekday(DateTime dateTime) {
    final DateFormat formatter = DateFormat.EEEE('de');
    return formatter.format(dateTime);
  }
  
  // Formatiert ein DateTime-Objekt als kurzes Datum (z.B. "01.03.")
  static String formatShortDate(DateTime dateTime) {
    final DateFormat formatter = DateFormat.MMMd('de');
    return formatter.format(dateTime);
  }
  
  // Formatiert ein DateTime-Objekt als Uhrzeit (z.B. "14:30 Uhr")
  static String formatTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat.Hm('de');
    return '${formatter.format(dateTime)} Uhr';
  }
  
  // Prüft, ob ein Datum heute ist
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year && 
           dateTime.month == now.month && 
           dateTime.day == now.day;
  }
  
  // Prüft, ob ein Datum morgen ist
  static bool isTomorrow(DateTime dateTime) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dateTime.year == tomorrow.year && 
           dateTime.month == tomorrow.month && 
           dateTime.day == tomorrow.day;
  }
  
  // Prüft, ob eine Uhrzeit in der Nacht liegt (18:00 - 06:00 Uhr)
  static bool isNightTime(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 18 || hour <= 6;
  }
  
  // Konvertiert Unix-Timestamp (Sekunden) zu DateTime
  static DateTime fromUnixTimestamp(int timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }
}
