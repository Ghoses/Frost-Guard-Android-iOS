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
//final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Headless-Task für flutter_background_fetch
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  final String taskId = task.taskId;
  final bool isTimeout = task.timeout;
  
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }
  
  try {
    final backgroundService = BackgroundService();
    await backgroundService.performFrostCheck();
  } catch (e) {
    // Stille Fehlerbehandlung ohne Logging
  }
  
  BackgroundFetch.finish(taskId);
}

Future<void> main() async {
  // Minimale Initialisierung
  WidgetsFlutterBinding.ensureInitialized();
  
  // Vollständige Unterdrückung aller Debugging-Ausgaben
  debugPrint = (String? message, {int? wrapWidth}) => null;
  
  // Deaktiviere DevTools-Verbindung
  FlutterError.onError = (FlutterErrorDetails details) {};
  
  // Registriere Headless-Task
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  
  // Minimale Systemkonfiguration
  tz.initializeTimeZones();
  await dotenv.load(fileName: ".env");
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialisiere Dienste
  final backgroundService = BackgroundService();
  final notificationService = NotificationService();
  
  await notificationService.init();
  await backgroundService.init();
  
  // Starte App
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
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
    );
  }
}
