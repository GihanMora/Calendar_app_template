import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/state_provider.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart';
import 'services/notes_service.dart';
import 'config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable edge-to-edge display for Android 15+ (SDK 35)
  // This ensures proper handling of system bars and prevents deprecated API warnings
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Load app config from JSON file FIRST (before anything else uses AppConfig)
  await AppConfig.initialize();

  // Only initialize Mobile Ads on mobile platforms
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
    // Initialize notification service
    await NotificationService().initialize();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came to foreground - reschedule notifications that might have been cancelled
      _rescheduleNotifications();
    }
  }

  Future<void> _rescheduleNotifications() async {
    try {
      print('App resumed - checking and rescheduling notifications...');
      await NotificationService.rescheduleAllNotifications();
      print('Notifications rescheduled successfully');
    } catch (e) {
      print('Error rescheduling notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider(create: (context) => StateProvider()),
            ChangeNotifierProvider(create: (context) => LanguageProvider()),
          ],
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,
                theme: buildLightTheme(),
                darkTheme: buildDarkTheme(),
                themeMode: themeProvider.themeMode,
                home: const HomeScreen(),
              );
            },
          ),
        );
  }
}
