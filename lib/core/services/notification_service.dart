// Temporär auskommentiert, um die App ohne Benachrichtigungen zu testen
/*
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:frost_guard/core/constants/app_constants.dart';
import 'package:frost_guard/core/errors/exceptions.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    try {
      // Initialisiere Zeitzonen
      tz.initializeTimeZones();
      
      // Initialisiere Android-Einstellungen
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      // Initialisiere iOS-Einstellungen
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Kombiniere Plattform-Einstellungen
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialisiere Plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
      );
    } catch (e) {
      throw NotificationException('Fehler bei der Initialisierung der Benachrichtigungen: $e');
    }
  }
  
  // Sende eine Frostwarnung
  Future<void> showFrostWarning(String title, String body) async {
    try {
      // Konfiguriere Android-Details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        AppConstants.FROST_WARNING_CHANNEL_ID,
        'Frost-Warnungen',
        channelDescription: 'Benachrichtigungen über Frostgefahr',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
      );
      
      // Konfiguriere iOS-Details
      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      
      // Kombiniere Plattform-Details
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );
      
      // Zeige Benachrichtigung
      await flutterLocalNotificationsPlugin.show(
        AppConstants.FROST_WARNING_ID,
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      throw NotificationException('Fehler beim Senden der Frostwarnung: $e');
    }
  }
  
  // Plane tägliche Überprüfung
  Future<void> scheduleDailyCheck(int hour, int minute) async {
    try {
      // Lösche vorherige geplante Benachrichtigungen
      await flutterLocalNotificationsPlugin.cancelAll();
      
      // Erstelle eine Zeit für die tägliche Überprüfung
      final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);
      
      // Konfiguriere Benachrichtigungsdetails (niedrigere Priorität für Hintergrundaufgaben)
      const notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            AppConstants.DAILY_CHECK_CHANNEL_ID,
            'Tägliche Überprüfungen',
            channelDescription: 'Hintergrundüberprüfungen der Wettervorhersage',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBadge: false,
            presentSound: false,
          ),
        );
      
      // Plane tägliche Benachrichtigung
      await flutterLocalNotificationsPlugin.zonedSchedule(
        AppConstants.DAILY_CHECK_ID,
        'Wetterüberprüfung',
        'Überprüfung der Wettervorhersage auf Frost',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      throw NotificationException('Fehler beim Planen der täglichen Überprüfung: $e');
    }
  }
  
  // Berechne die nächste Instanz der angegebenen Zeit
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
}
*/

// Temporärer Ersatz für die NotificationService-Klasse
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initNotifications() async {
    // Leere Implementierung
  }
  
  Future<void> showFrostWarningNotification(String locationName, double temperature) async {
    // Leere Implementierung
  }
  
  Future<void> scheduleDailyCheck(int hour, int minute) async {
    // Leere Implementierung
  }
  
  Future<void> cancelAllNotifications() async {
    // Leere Implementierung
  }
}
