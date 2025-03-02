// Benachrichtigungsdienst für Frost Guard
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:frost_guard/core/constants/app_constants.dart';

// Konstanten für Benachrichtigungskanäle
const String frostWarningChannelId = AppConstants.FROST_WARNING_CHANNEL_ID;
const String dailyCheckChannelId = AppConstants.DAILY_CHECK_CHANNEL_ID;

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
  NotificationService._internal();
  
  // Instanz des Flutter Local Notifications Plugins
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  
  // Zustand der App (im Vordergrund oder nicht)
  bool _isAppInForeground = false;
  
  // Initialisiere App-Lebenszyklus-Listener
  void _initAppLifecycleListener() {
    // Wird durch das WidgetsBindingObserver in der MainApp implementiert
    debugPrint('App-Lebenszyklus-Listener initialisiert');
  }
  
  // Setze den App-Vordergrund-Status
  void setAppInForeground(bool isInForeground) {
    _isAppInForeground = isInForeground;
    debugPrint('App-Zustand geändert: ${_isAppInForeground ? 'im Vordergrund' : 'im Hintergrund'}');
  }
  
  // Initialisiere Benachrichtigungen
  Future<void> initNotifications() async {
    debugPrint('Initialisiere Benachrichtigungen');
    
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
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _onNotificationResponse(response);
        },
      );
      
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung der Benachrichtigungen: $e');
      throw NotificationException('Fehler bei der Initialisierung: $e');
    }
  }
  
  // Handler für Benachrichtigungsantworten
  void _onNotificationResponse(NotificationResponse details) {
    debugPrint('Benachrichtigungsantwort empfangen: ${details.payload}');
    
    // Wenn die Benachrichtigung für eine Frost-Überprüfung ist, führe diese durch
    if (details.payload == 'checking_frost' || details.payload == 'check_frost') {
      debugPrint('Löse Frost-Überprüfung aus Benachrichtigungsantwort aus');
      _performFrostCheck();
    }
  }
  
  // Führe die Frost-Überprüfung durch
  void _performFrostCheck() {
    debugPrint('Führe Frost-Überprüfung durch');
    // Löse den statischen Callback aus
    triggerFrostCheck();
    
    // Zeige eine Benachrichtigung an, dass die Überprüfung läuft
    showFrostWarning(
      'Frostwächter aktiv', 
      'Überprüfe Wettervorhersage auf Frostgefahr...',
      forceShow: true
    );
  }
  
  // Registriere einen Callback für die Frost-Überprüfung
  static Function? _frostCheckCallback;
  
  // Setze den Callback für die Frost-Überprüfung
  static void setFrostCheckCallback(Function callback) {
    _frostCheckCallback = callback;
    debugPrint('Frost-Überprüfungs-Callback registriert');
  }
  
  // Löse die Frost-Überprüfung aus
  static void triggerFrostCheck() {
    debugPrint('Löse Frost-Überprüfung aus');
    if (_frostCheckCallback != null) {
      _frostCheckCallback!();
    } else {
      debugPrint('Kein Frost-Überprüfungs-Callback registriert');
    }
  }
  
  // Überprüfe und beantrage Berechtigungen für Benachrichtigungen
  Future<bool> checkAndRequestNotificationPermissions() async {
    try {
      // Überprüfe aktuelle Berechtigungen
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        final bool? areEnabled = await androidPlugin.areNotificationsEnabled();
        return areEnabled ?? false;
      }
      
      // Für iOS/andere Plattformen
      return true;
    } catch (e) {
      debugPrint('Fehler beim Überprüfen der Benachrichtigungsberechtigungen: $e');
      return false;
    }
  }
  
  // Zeige eine Frostwarnung an
  Future<void> showFrostWarning(String title, String body, {bool forceShow = false}) async {
    debugPrint('Zeige Frostwarnung an: $title - $body, Force: $forceShow');
    
    // Wenn die App im Vordergrund ist und nicht erzwungen wird, keine Benachrichtigung anzeigen
    if (_isAppInForeground && !forceShow) {
      debugPrint('App ist im Vordergrund, überspringe Benachrichtigung');
      return;
    }
    
    // Android-spezifische Einstellungen
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      frostWarningChannelId,
      'Frostwarnungen',
      channelDescription: 'Warnungen vor Frost an Ihren Standorten',
      importance: Importance.high,  // Wichtigkeit erhöht
      priority: Priority.high,      // Priorität erhöht
      playSound: true,              // Sound aktiviert
      enableVibration: true,        // Vibration aktiviert
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      // Stellt sicher, dass die Benachrichtigung auch angezeigt wird, wenn Bildschirm gesperrt ist
      fullScreenIntent: true,
    );
    
    // iOS-spezifische Einstellungen
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,   // Zeigt eine Alert-Nachricht an
      presentBadge: true,   // Aktualisiert das App-Badge
      presentSound: true,   // Spielt einen Sound ab
      sound: 'default',     // Verwendet den Standard-Sound
      badgeNumber: 1,       // Setzt das Badge auf 1
      // Sorgt dafür, dass die Benachrichtigung kritisch ist und DND umgeht
      interruptionLevel: InterruptionLevel.timeSensitive,
    );
    
    // Kombiniere Plattform-Einstellungen
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    // Zeige die Benachrichtigung an
    await flutterLocalNotificationsPlugin.show(
      _generateNotificationId(),  // Eindeutige ID für jede Benachrichtigung
      title,
      body,
      platformDetails,
      payload: 'frost_warning',
    );
  }
  
  // Generiert eine eindeutige ID für Benachrichtigungen
  static int _generateNotificationId() {
    return DateTime.now().millisecondsSinceEpoch % 10000;
  }
  
  // Zeige eine Test-Benachrichtigung an
  Future<void> showTestNotification() async {
    debugPrint('Zeige Test-Benachrichtigung an');
    
    // Zeige immer eine Test-Benachrichtigung an, auch wenn App im Vordergrund
    await showFrostWarning(
      'Test-Benachrichtigung', 
      'Dies ist ein Test der Benachrichtigungsfunktion.',
      forceShow: true
    );
  }
  
  // Zeige eine Frostwarnung für einen bestimmten Standort an
  Future<void> showFrostWarningNotification(String locationName, double temperature) async {
    debugPrint('Zeige Frostwarnung für $locationName an: ${temperature.toStringAsFixed(1)}°C');
    
    final String title = 'Frostwarnung für $locationName';
    final String body = 'Die Temperatur wird voraussichtlich auf ${temperature.toStringAsFixed(1)}°C fallen.';
    await showFrostWarning(title, body);
  }
  
  // Plane tägliche Überprüfung
  Future<void> scheduleDailyCheck(int hour, int minute) async {
    try {
      debugPrint('Plane tägliche Überprüfung für $hour:$minute Uhr');
      
      // Überprüfe zuerst die Berechtigung
      final bool hasPermission = await checkAndRequestNotificationPermissions();
      
      if (!hasPermission) {
        debugPrint('Keine Berechtigung für Benachrichtigungen');
        throw NotificationException('Benachrichtigungsberechtigungen nicht erteilt');
      }
      
      // Lösche vorherige geplante Benachrichtigungen
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Vorherige Benachrichtigungen gelöscht');
      
      // Erstelle eine Zeit für die tägliche Überprüfung
      final tz.TZDateTime scheduledTime = _nextInstanceOfTime(hour, minute);
      debugPrint('Berechnete nächste Zeit: ${scheduledTime.toString()}');
      debugPrint('Nächste geplante Zeit: ${scheduledTime.toString()}');
      
      // Android-spezifische Einstellungen
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        dailyCheckChannelId,
        'Tägliche Überprüfungen',
        channelDescription: 'Hintergrundüberprüfungen der Wettervorhersage',
        importance: Importance.high,  // Wichtigkeit erhöht
        priority: Priority.high,      // Priorität erhöht
        playSound: true,              // Sound aktiviert
        enableVibration: true,        // Vibration aktiviert
        icon: '@mipmap/ic_launcher',
        // Wichtig: Stelle sicher, dass die Benachrichtigung auch im Vordergrund angezeigt wird
        fullScreenIntent: true,       // Volle Bildschirmabsicht
      );
      
      // iOS-spezifische Einstellungen
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,   // Zeigt eine Alert-Nachricht an
        presentBadge: true,   // Aktualisiert das App-Badge
        presentSound: true,   // Spielt einen Sound ab
        sound: 'default',     // Verwendet den Standard-Sound
        // Umgeht Do Not Disturb für wichtige Benachrichtigungen
        interruptionLevel: InterruptionLevel.active,
      );
      
      // Kombiniere Plattform-Einstellungen
      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Versuche zuerst, einen exakten Zeitplan zu verwenden
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          AppConstants.DAILY_CHECK_ID,
          'Frost-Überprüfung',
          'Überprüfe Wettervorhersage auf Frostgefahr',
          scheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'check_frost',
        );
        
        debugPrint('Tägliche Überprüfung mit exakter Planung eingerichtet');
      } catch (e) {
        // Wenn exakter Zeitplan nicht erlaubt ist, verwende periodischen Zeitplan
        debugPrint('Exakte Alarme nicht erlaubt, verwende ungefähre Planung: $e');
        
        await flutterLocalNotificationsPlugin.periodicallyShow(
          AppConstants.DAILY_CHECK_ID,
          'Frost-Überprüfung',
          'Überprüfe Wettervorhersage auf Frostgefahr',
          RepeatInterval.daily,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'check_frost',
        );
        
        debugPrint('Tägliche Überprüfung mit ungefährer Planung eingerichtet');
      }
      
      debugPrint('Benachrichtigungen für $hour:$minute Uhr neu geplant');
      
    } catch (e) {
      debugPrint('Fehler beim Planen der täglichen Überprüfung: $e');
      throw NotificationException('Fehler beim Planen der täglichen Überprüfung: $e');
    }
  }
  
  // Berechne die nächste Zeit für eine tägliche Überprüfung
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.Location location = tz.UTC;
    final tz.TZDateTime now = tz.TZDateTime.now(location);
    debugPrint('Aktuelle Zeit: $now, Zeitzone: ${location.name}');
    
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      location, 
      now.year, 
      now.month, 
      now.day, 
      hour, 
      minute
    );
    
    // Wenn die Zeit bereits vergangen ist, plane für morgen
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }
  
  // Lösche alle Benachrichtigungen
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
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
}
