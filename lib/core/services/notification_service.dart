// Benachrichtigungsdienst für Frost Guard
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
      
      // Initialisiere Plugin und fordere Berechtigungen an
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
        'frost_warning_channel',
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
        1, // Notification ID
        title,
        body,
        platformDetails,
      );
    } catch (e) {
      throw NotificationException('Fehler beim Senden der Frostwarnung: $e');
    }
  }
  
  // Methode für den Test-Button
  Future<void> showTestNotification() async {
    await showFrostWarning(
      'Test: Frostwarnung', 
      'Dies ist eine Test-Benachrichtigung. Die Benachrichtigungsfunktion funktioniert!'
    );
  }
  
  // Sende eine Frostwarnung für einen bestimmten Ort
  Future<void> showFrostWarningNotification(String locationName, double temperature) async {
    final String title = 'Frostwarnung für $locationName';
    final String body = 'Die Temperatur wird voraussichtlich auf ${temperature.toStringAsFixed(1)}°C fallen.';
    await showFrostWarning(title, body);
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
            'daily_check_channel',
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
        0, // Notification ID
        'Wetterüberprüfung',
        'Überprüfung der Wettervorhersage auf Frost',
        scheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true,
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
  
  // Lösche alle Benachrichtigungen
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
