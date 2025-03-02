import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:frost_guard/providers/weather_provider.dart';
import 'package:frost_guard/ui/screens/home_screen.dart';
import 'package:frost_guard/ui/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lade Umgebungsvariablen
  await dotenv.load(fileName: ".env");
  
  // Initialisiere Lokalisierung
  Intl.defaultLocale = 'de_DE';
  
  // Initialisiere Benachrichtigungsdienst
  try {
    debugPrint('Initialisiere Benachrichtigungsdienst...');
    await NotificationService().initNotifications();
    debugPrint('Benachrichtigungsdienst erfolgreich initialisiert');
    
    // Überprüfe Benachrichtigungsberechtigungen
    final hasPermission = await NotificationService().checkAndRequestNotificationPermissions();
    debugPrint('Benachrichtigungsberechtigungen: ${hasPermission ? 'erteilt' : 'nicht erteilt'}');
    
    // Registriere Hintergrundhandler für Benachrichtigungen
    _setupNotificationHandlers();
  } catch (e) {
    debugPrint('Fehler bei der Initialisierung des Benachrichtigungsdienstes: $e');
  }
  
  // Setze die Statusleiste auf transparent für ein besseres Design
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  
  runApp(const MyApp());
}

// Registriere Handler für Benachrichtigungen
void _setupNotificationHandlers() {
  // Überprüfe, ob die App aufgrund einer Benachrichtigung gestartet wurde
  NotificationService.flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails().then((details) {
    if (details != null && details.didNotificationLaunchApp) {
      debugPrint('App wurde durch Benachrichtigung gestartet: ${details.notificationResponse?.payload}');
      
      // Wenn die App durch eine Frost-Check-Benachrichtigung gestartet wurde, führe die Überprüfung durch
      if (details.notificationResponse?.payload == 'check_frost' || 
          details.notificationResponse?.payload == 'checking_frost') {
        debugPrint('Starte Frost-Überprüfung aufgrund von App-Start durch Benachrichtigung');
        // Verzögere den Aufruf leicht, um sicherzustellen, dass alle Provider initialisiert sind
        Future.delayed(const Duration(seconds: 2), () {
          NotificationService.triggerFrostCheck();
        });
      }
    }
  });
  
  // Registriere einen Listener für Benachrichtigungen, die empfangen werden, während die App läuft
  NotificationService.flutterLocalNotificationsPlugin.periodicallyShow(
    999, // Eindeutige ID
    'Frostwächter läuft',
    'Die App überprüft regelmäßig die Wettervorhersage',
    RepeatInterval.daily,
    NotificationDetails(
      android: const AndroidNotificationDetails(
        'app_status',
        'App-Status',
        channelDescription: 'Informationen über den App-Status',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: true,
        presentSound: false,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  
  @override
  void initState() {
    super.initState();
    // Registriere den WidgetsBindingObserver
    WidgetsBinding.instance.addObserver(this);
    // Setze den initialen Zustand auf "im Vordergrund"
    _notificationService.setAppInForeground(true);
  }
  
  @override
  void dispose() {
    // Entferne den WidgetsBindingObserver
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Setze den Vordergrund-Status basierend auf dem aktuellen Lebenszyklus-Zustand
    final bool isInForeground = state == AppLifecycleState.resumed;
    _notificationService.setAppInForeground(isInForeground);
    debugPrint('App-Lebenszyklus geändert: ${state.name}, im Vordergrund: $isInForeground');
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'Frost Guard',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de', 'DE'),
              Locale('en', 'US'),
            ],
            locale: const Locale('de', 'DE'),
          );
        },
      ),
    );
  }
}
