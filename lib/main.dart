import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frost_guard/core/services/background_service.dart';
import 'package:frost_guard/core/services/notification_service.dart';
import 'package:frost_guard/providers/location_provider.dart';
import 'package:frost_guard/providers/settings_provider.dart';
import 'package:frost_guard/providers/theme_provider.dart';
import 'package:frost_guard/providers/weather_provider.dart';
import 'package:frost_guard/ui/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:background_fetch/background_fetch.dart';

// Globaler Key für den NavigatorState, um auf den aktuellen Kontext zuzugreifen
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Headless-Task für flutter_background_fetch
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool isTimeout = task.timeout;
  
  if (isTimeout) {
    // Dieser Task ist abgelaufen
    debugPrint('[BackgroundFetch] Headless task timed out: $taskId');
    BackgroundFetch.finish(taskId);
    return;
  }
  
  // Führe den Frost-Check im Hintergrund durch
  debugPrint('[BackgroundFetch] Headless event received: $taskId');
  
  try {
    final backgroundService = BackgroundService();
    await backgroundService.performFrostCheck();
  } catch (e) {
    debugPrint('[BackgroundFetch] Headless task error: $e');
  }
  
  // Markiere den Task als abgeschlossen
  BackgroundFetch.finish(taskId);
}

Future<void> main() async {
  // Stelle sicher, dass Flutter-Binding initialisiert ist
  WidgetsFlutterBinding.ensureInitialized();
  
  // Registriere den Headless-Task für flutter_background_fetch
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  
  // Lade Umgebungsvariablen
  await dotenv.load();
  
  // Initialisiere Zeitzonen für geplante Benachrichtigungen
  tz.initializeTimeZones();
  
  // Richte Benachrichtigungshandler ein
  _setupNotificationHandlers();
  
  // Initialisiere den BackgroundService für Hintergrundaufgaben
  await BackgroundService().init();
  
  // Setze die Statusleiste auf transparent für ein besseres Design
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  
  // Starte die App
  runApp(const MyApp());
}

// Registriere Handler für Benachrichtigungen
void _setupNotificationHandlers() {
  debugPrint('Richtet Benachrichtigungshandler ein');
  
  // Setze den Frost-Check-Callback
  NotificationService.setFrostCheckCallback(() {
    debugPrint('Frost-Check-Callback ausgelöst');
    
    // Wir verwenden Provider.of mit listen:false, da dies ein statischer Kontext ist
    if (navigatorKey.currentContext != null) {
      final weatherProvider = Provider.of<WeatherProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      
      // Führe eine Überprüfung auf Frost durch
      weatherProvider.checkForFrost();
    } else {
      debugPrint('Kein Kontext verfügbar für Frost-Check-Callback');
      // Führe direkte Überprüfung durch
      BackgroundService().checkForFrostNow();
    }
  });
  
  // Überwache Hintergrund-Benachrichtigungen, die die App öffnen
  FlutterLocalNotificationsPlugin().getNotificationAppLaunchDetails().then((details) {
    if (details != null && details.didNotificationLaunchApp) {
      debugPrint('App wurde durch Benachrichtigung gestartet: ${details.notificationResponse?.payload}');
      
      // Wenn die App durch eine Frost-Check-Benachrichtigung gestartet wurde, führe den Check aus
      if (details.notificationResponse?.payload == 'check_frost') {
        debugPrint('Frost-Check aus App-Start durch Benachrichtigung');
        
        // Verzögere die Ausführung leicht, um sicherzustellen, dass Provider initialisiert ist
        Future.delayed(const Duration(seconds: 1), () {
          NotificationService.triggerFrostCheck();
        });
      } else if (details.notificationResponse?.payload?.startsWith('frost_warning:') ?? false) {
        // Wenn die App durch eine Frostwarnung geöffnet wurde, könnte man hier zur entsprechenden Standort-Ansicht navigieren
        debugPrint('App durch Frostwarnung geöffnet');
      }
    }
  });
  
  debugPrint('Benachrichtigungshandler eingerichtet');
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  final BackgroundService _backgroundService = BackgroundService();
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialisiere die App
    _initializeApp();
    
    // Registriere App-Lebenszyklus-Listener
    WidgetsBinding.instance.addObserver(this);
    
    // App startet im Vordergrund
    _notificationService.setAppInForeground(true);
  }
  
  Future<void> _initializeApp() async {
    try {
      // Initialisiere Benachrichtigungen
      await _notificationService.initialize();
      
      // Initialisiere den Hintergrund-Service
      await _backgroundService.init();
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Fehler bei der Initialisierung: $e');
      // Zeige Fehlermeldung an
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler bei der Initialisierung: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    // Entferne App-Lebenszyklus-Listener
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Aktualisiere den App-Vordergrund-Status basierend auf dem Lebenszyklus
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App ist im Vordergrund (resumed)');
        _notificationService.setAppInForeground(true);
        break;
      case AppLifecycleState.inactive:
        debugPrint('App ist inaktiv');
        // Noch im Vordergrund, aber möglicherweise teilweise verdeckt
        break;
      case AppLifecycleState.paused:
        debugPrint('App ist im Hintergrund (paused)');
        _notificationService.setAppInForeground(false);
        break;
      case AppLifecycleState.detached:
        debugPrint('App ist losgelöst (detached)');
        _notificationService.setAppInForeground(false);
        break;
      default:
        debugPrint('Unbekannter App-Lebenszyklus-Status: $state');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Frost Guard',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('de', 'DE'),
              Locale('en', 'US'),
            ],
            home: const HomeScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
