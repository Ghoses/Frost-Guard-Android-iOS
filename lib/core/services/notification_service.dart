// Benachrichtigungsdienst für Frost Guard
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:frost_guard/core/constants/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';

// Eigene Exception-Klasse für Benachrichtigungsfehler
class NotificationException implements Exception {
  final String message;
  NotificationException(this.message);
  
  @override
  String toString() => 'NotificationException: $message';
}

class NotificationService {
  // Singleton-Instanz
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal() {
    // Initialisiere Zeitzonen beim Erstellen der Instanz
    tz.initializeTimeZones();
  }

  // Benachrichtigungsplugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  // Konstante Benachrichtigungs-IDs
  static const int DAILY_FROST_CHECK_ID = 1;

  // Benachrichtigungskanäle
  static const String frostWarningChannelId = 'frost_warning_channel';
  static const String dailyCheckChannelId = 'daily_check_channel';

  // Flag zur Überprüfung der Initialisierung
  bool _isInitialized = false;

  // Status, ob die App im Vordergrund ist
  bool _isAppInForeground = true;
  
  // Callback-Funktionen
  static VoidCallback? _frostCheckCallback;
  
  // Setter für den Frost-Check-Callback
  static void setFrostCheckCallback(VoidCallback callback) {
    _frostCheckCallback = callback;
    debugPrint('Frost-Check-Callback gesetzt');
  }
  
  // Funktion zum Auslösen des Frost-Checks
  static void triggerFrostCheck() {
    if (_frostCheckCallback != null) {
      debugPrint('Frost-Check-Callback wird ausgelöst');
      _frostCheckCallback!();
    } else {
      debugPrint('Frost-Check-Callback nicht gesetzt');
    }
  }
  
  // Setze den App-Vordergrund-Status
  void setAppInForeground(bool isInForeground) {
    _isAppInForeground = isInForeground;
    debugPrint('App-Zustand geändert: ${_isAppInForeground ? 'im Vordergrund' : 'im Hintergrund'}');
  }
  
  // Initialisierung der Benachrichtigungsdienste
  Future<void> initialize() async {
    try {
      // Verhindere mehrfache Initialisierung
      if (_isInitialized) return;

      // Android-Initialisierungseinstellungen
      const AndroidInitializationSettings androidInitializationSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS-Initialisierungseinstellungen
      const DarwinInitializationSettings darwinInitializationSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Gesamte Initialisierungseinstellungen
      final InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings,
      );

      // Plugin initialisieren
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Berechtigungen anfordern
      await requestNotificationPermissions();

      // Benachrichtigungskanäle für Android erstellen
      await _createNotificationChannels();

      // Initialisierungsstatus setzen
      _isInitialized = true;
      debugPrint('NotificationService erfolgreich initialisiert');
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung: $e');
    }
  }

  // Öffentliche Methode zur Berechtigungsanfrage
  Future<bool> requestNotificationPermissions() async {
    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    return true;
  }

  // Handler für Benachrichtigungstaps
  void _handleNotificationTap(NotificationResponse notificationResponse) {
    debugPrint('Benachrichtigung getippt: ${notificationResponse.payload}');
    // Hier können spezifische Aktionen beim Tippen auf eine Benachrichtigung definiert werden
  }

  // Erstelle Benachrichtigungskanäle für Android
  Future<void> _createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = 
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Frost-Warnungs-Kanal
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          frostWarningChannelId,
          'Frost-Warnungen',
          description: 'Benachrichtigungen über Frostgefahren',
          importance: Importance.high,
        ),
      );

      // Täglicher Check-Kanal
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          dailyCheckChannelId,
          'Tägliche Überprüfungen',
          description: 'Tägliche Hintergrundüberprüfungen',
          importance: Importance.high,
        ),
      );
    }
  }

  // Plane tägliche Frost-Checks
  Future<void> scheduleDailyFrostCheck(TimeOfDay checkTime) async {
    try {
      // Aktuelle Zeit in der lokalen Zeitzone
      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      
      // Erstelle das geplante Datum für den nächsten Check
      tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        checkTime.hour,
        checkTime.minute,
      );
      
      // Stelle sicher, dass die Zeit in der Zukunft liegt
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      // Benachrichtigungsdetails
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_frost_check',
          'Tägliche Frost-Checks',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      try {
        // Versuche zuerst mit exaktem Alarm
        await flutterLocalNotificationsPlugin.zonedSchedule(
          DAILY_FROST_CHECK_ID,
          'Frost-Überprüfung',
          'Tägliche Überprüfung der Frostgefahr',
          scheduledTime,
          notificationDetails,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'daily_frost_check',
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      } on PlatformException catch (e) {
        // Fallback, wenn exakte Alarme nicht erlaubt sind
        if (e.code == 'exact_alarms_not_permitted') {
          debugPrint('Exakte Alarme nicht erlaubt. Verwende ungenaueren Alarm.');
          
          await flutterLocalNotificationsPlugin.zonedSchedule(
            DAILY_FROST_CHECK_ID,
            'Frost-Überprüfung',
            'Tägliche Überprüfung der Frostgefahr',
            scheduledTime,
            notificationDetails,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: 'daily_frost_check',
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } else {
          // Andere Fehler weiterleiten
          rethrow;
        }
      }

      debugPrint('Täglicher Frost-Check geplant für: $scheduledTime');
    } catch (e) {
      debugPrint('Fehler beim Planen des täglichen Frost-Checks: $e');
    }
  }

  // Sofortige Benachrichtigung zum Testen
  Future<void> testNotification() async {
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test-Benachrichtigungen',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Test-Benachrichtigung',
      'Dies ist eine Test-Benachrichtigung',
      notificationDetails,
    );
  }

  // Führe die Frost-Überprüfung durch
  void _performFrostCheck() {
    debugPrint('Führe Frost-Überprüfung durch');
    // Löse den statischen Callback aus
    triggerFrostCheck();
    
    // Zeige eine Benachrichtigung an, dass die Überprüfung läuft
    showImmediateNotification(
      id: 1,
      title: 'Frostwächter aktiv', 
      body: 'Überprüfe Wettervorhersage auf Frostgefahr...',
      payload: 'frost_warning',
    );
  }

  // Zeige eine Frostwarnung an
  Future<void> showFrostWarning(String title, String body, {bool forceShow = false}) async {
    debugPrint('Zeige Frostwarnung an: $title - $body, Force: $forceShow');
    
    // Benachrichtigungsdetails mit hoher Priorität
    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'frost_warning_channel',
        'Frostwarnungen',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    // Immer Benachrichtigung senden, unabhängig vom App-Zustand
    await flutterLocalNotificationsPlugin.show(
      2,  // Feste ID für Frostwarnungen
      title,
      body,
      notificationDetails,
      payload: 'frost_warning',
    );
  }

  // Zeige eine Frostwarnung für einen bestimmten Standort an
  Future<void> showFrostWarningNotification(String locationName, double temperature) async {
    debugPrint('Zeige Frostwarnung für $locationName an: ${temperature.toStringAsFixed(1)}°C');
    
    final String title = 'Frostwarnung für $locationName';
    final String body = 'Die Temperatur wird voraussichtlich auf ${temperature.toStringAsFixed(1)}°C fallen.';
    
    // Immer Benachrichtigung senden
    await showFrostWarning(title, body, forceShow: true);
  }

  // Plane tägliche Überprüfung
  Future<void> scheduleDailyCheck(int hour, int minute) async {
    try {
      debugPrint('Plane tägliche Überprüfung für $hour:$minute Uhr');
      
      // Überprüfe zuerst die Berechtigung
      final bool hasPermission = await requestNotificationPermissions();
      
      if (!hasPermission) {
        debugPrint('Keine Berechtigung für Benachrichtigungen');
        throw NotificationException('Benachrichtigungsberechtigungen nicht erteilt');
      }
      
      // Lösche vorherige geplante Benachrichtigungen
      await cancelAllNotifications();
      debugPrint('Vorherige Benachrichtigungen gelöscht');
      
      // Erstelle eine Zeit für die tägliche Überprüfung
      final DateTime scheduledDate = DateTime(
        DateTime.now().year, 
        DateTime.now().month, 
        DateTime.now().day, 
        hour, 
        minute,
      );
      
      // Stelle sicher, dass das Datum in der Zukunft liegt
      final DateTime finalScheduledDate = scheduledDate.isBefore(DateTime.now())
          ? scheduledDate.add(const Duration(days: 1))
          : scheduledDate;
      
      await scheduleNotification(
        id: 0, // Konstante ID für täglichen Frost-Check
        title: 'Frost-Überprüfung',
        body: 'Tägliche Überprüfung der Frostgefahr',
        scheduledDate: finalScheduledDate,
        payload: 'daily_frost_check',
      );
      
      debugPrint('Benachrichtigungen für $hour:$minute Uhr neu geplant');
      
    } catch (e) {
      debugPrint('Fehler beim Planen der täglichen Überprüfung: $e');
      throw NotificationException('Fehler beim Planen der täglichen Überprüfung: $e');
    }
  }

  // Teste die Frostbenachrichtigungen
  Future<void> testFrostNotification() async {
    debugPrint('Teste Frostbenachrichtigungen');
    
    try {
      // Simuliere eine Frostwarnung für einen Teststandort
      // Verwende forceShow: true, um sicherzustellen, dass die Benachrichtigung auch im Vordergrund angezeigt wird
      await showFrostWarning(
        "Frostwarnung für Teststandort", 
        "Die Temperatur wird heute Nacht auf -2,5°C fallen.",
        forceShow: true
      );
      
      debugPrint('Frostbenachrichtigung erfolgreich angezeigt');
      
      // Löse den Frost-Check aus (falls ein Callback registriert ist)
      NotificationService.triggerFrostCheck();
    } catch (e) {
      debugPrint('Fehler beim Testen der Frostbenachrichtigung: $e');
      throw NotificationException('Fehler beim Testen der Frostbenachrichtigung: $e');
    }
    
    debugPrint('Frostbenachrichtigungstest abgeschlossen');
  }

  // Sofortige Benachrichtigung anzeigen
  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          frostWarningChannelId,
          'Frost-Warnungen',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // Plane eine Benachrichtigung
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      // Konvertiere DateTime in TZDateTime
      final tz.TZDateTime zonedScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      // Benachrichtigungsdetails
      const NotificationDetails notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'scheduled_notification',
          'Geplante Benachrichtigungen',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      // Plane die Benachrichtigung
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        zonedScheduledDate,
        notificationDetails,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      debugPrint('Benachrichtigung geplant für: $zonedScheduledDate');
    } catch (e) {
      debugPrint('Fehler beim Planen der Benachrichtigung: $e');
    }
  }

  // Einzelne Benachrichtigung abbrechen
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // Alle Benachrichtigungen abbrechen
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
