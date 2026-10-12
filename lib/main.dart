import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/navigation_service.dart';
import 'services/language_service.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/theme_service.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// This class fixes the "Handshake Exception" for the OTP service
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  
  await NotificationService.init();
  await BackgroundService.init();
  await BackgroundService.scheduleDailyNewsTask();
  
  final languageService = LanguageService();
  await languageService.init();

  final themeService = ThemeService();
  await themeService.init();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: languageService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider(create: (_) => NavigationService()),
        Provider<AuthService>(create: (_) => AuthService()),
        StreamProvider<User?>.value(
          value: AuthService().userStream,
          initialData: null,
        ),
      ],
      child: const WheatGuardApp(),
    ),
  );
}

class WheatGuardApp extends StatelessWidget {
  const WheatGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<LanguageService, ThemeService>(
      builder: (context, langService, themeService, child) {
        return MaterialApp(
          title: 'WheatGuard',
          debugShowCheckedModeBanner: false,
          theme: themeService.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
          locale: langService.currentLocale,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ur', 'PK'),
            Locale('pa', 'PK'),
          ],
          home: const SplashScreen(),
        );
      },
    );
  }
}
