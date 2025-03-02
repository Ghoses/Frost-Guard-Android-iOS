// Benachrichtigungsdienst für Frost Guard
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:frost_guard/core/constants/app_constants.dart';
import 'package:frost_guard/core/errors/exceptions.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  // Definiere die Kanal-IDs
  static const String frostWarningChannelId = 'frost_warning_channel';
  static const String dailyCheckChannelId = 'daily_check_channel';
  
  // Initialisiere Benachrichtigungen
  Future<void> initNotifications() async {
    try {
      // Initialisiere Zeitzonen
      tz.initializeTimeZones();
      
      // Initialisiere Android-Einstellungen
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
          
      // Initialisiere iOS-Einstellungen
      final DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,  // Frage Berechtigungen automatisch an
        requestBadgePermission: true,
        requestSoundPermission: true,
        notificationCategories: [
          DarwinNotificationCategory(
            frostWarningChannelId,
            actions: <DarwinNotificationAction>[
              DarwinNotificationAction.plain(
                'OPEN_APP',
                'App öffnen',
                options: <DarwinNotificationActionOption>{
                  DarwinNotificationActionOption.foreground,
                },
              ),
            ],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
          DarwinNotificationCategory(
            dailyCheckChannelId,
            actions: <DarwinNotificationAction>[],
            options: <DarwinNotificationCategoryOption>{
              DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
            },
          ),
        ],
      );
      
      // Kombiniere Plattform-Einstellungen
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      
      // Initialisiere Plugin
      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Notification clicked: ${details.payload}');
        },
      );
      
    } catch (e) {
      throw NotificationException('Fehler bei der Initialisierung der Benachrichtigungen: $e');
    }
  }
  
  // Überprüfe und fordere Berechtigungen an
  Future<bool> checkAndRequestNotificationPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Prüfe, ob die Android-Version >= 13 (API 33) ist
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
            flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
          
          // Wenn Berechtigungen nicht aktiviert sind, zeige Hinweis
          if (areEnabled == false) {
            debugPrint('Benachrichtigungen sind nicht aktiviert. Bitte in den Einstellungen aktivieren.');
            // In Android 13+ können wir nicht direkt Berechtigungen anfordern, 
            // wir zeigen nur einen Hinweis an und der Benutzer muss selbst die Einstellungen öffnen
            return false;
          }
          return areEnabled ?? false;
        }
      } else if (Platform.isIOS) {
        // Auf iOS/Darwin können wir einfach true zurückgeben, da die Berechtigungen
        // beim ersten Aufruf automatisch angefordert werden und im AppDelegate.swift behandelt werden
        debugPrint('iOS-Benachrichtigungen werden beim ersten Aufruf automatisch angefordert');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Fehler bei der Berechtigungsanfrage: $e');
      return false;
    }
  }
  
  // Sende eine Frostwarnung
  Future<void> showFrostWarning(String title, String body) async {
    try {
      // Überprüfe zuerst die Berechtigung
      final bool hasPermission = await checkAndRequestNotificationPermissions();
      
      if (!hasPermission) {
        throw NotificationException('Benachrichtigungsberechtigungen nicht erteilt');
      }
      
      // Konfiguriere Android-Details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        frostWarningChannelId,
        'Frost-Warnungen',
        channelDescription: 'Benachrichtigungen über Frostgefahr',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );
      
      // Konfiguriere iOS-Details mit besserer Sichtbarkeit
      final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
        interruptionLevel: InterruptionLevel.timeSensitive, // Höher priorisiert
        categoryIdentifier: frostWarningChannelId,
        threadIdentifier: 'frost_warnings',
      );
      
      // Kombiniere Plattform-Details
      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );
      
      // Zeige Benachrichtigung
      await flutterLocalNotificationsPlugin.show(
        1, // Notification ID
        title,
        body,
        platformDetails,
        payload: 'frost_warning',
      );
    } catch (e) {
      debugPrint('Fehler beim Senden der Frostwarnung: $e');
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
      // Überprüfe zuerst die Berechtigung
      final bool hasPermission = await checkAndRequestNotificationPermissions();
      
      if (!hasPermission) {
        throw NotificationException('Benachrichtigungsberechtigungen nicht erteilt');
      }
      
      // Lösche vorherige geplante Benachrichtigungen
      await flutterLocalNotificationsPlugin.cancelAll();
      
      // Erstelle eine Zeit für die tägliche Überprüfung
      final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);
      
      // iOS-spezifische Einstellungen für Hintergrundbenachrichtigungen
      final DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
        presentAlert: false, // Hintergrundüberprüfungen sollen nicht sichtbar sein
        presentBadge: false,
        presentSound: false,
        categoryIdentifier: dailyCheckChannelId,
        threadIdentifier: 'daily_checks',
      );
      
      // Konfiguriere Benachrichtigungsdetails (niedrigere Priorität für Hintergrundaufgaben)
      final NotificationDetails notificationDetails = NotificationDetails(
          android: const AndroidNotificationDetails(
            dailyCheckChannelId,
            'Tägliche Überprüfungen',
            channelDescription: 'Hintergrundüberprüfungen der Wettervorhersage',
            importance: Importance.low,
            priority: Priority.low,
            playSound: false,
            enableVibration: false,
          ),
          iOS: darwinNotificationDetails,
        );
      
      // Plane tägliche Benachrichtigung
      await flutterLocalNotificationsPlugin.zonedSchedule(
        0, // Notification ID
        'Wetterüberprüfung',
        'Überprüfung der Wettervorhersage auf Frost',
        scheduledTime,
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exact,
      );
    } catch (e) {
      debugPrint('Fehler beim Planen der täglichen Überprüfung: $e');
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
