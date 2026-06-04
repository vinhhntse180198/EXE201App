import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';

/// App Yume — luôn dùng API thật (splash → login → shell).
class YumeApp extends StatelessWidget {
  const YumeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yume',
      debugShowCheckedModeBanner: false,
      locale: const Locale('vi', 'VN'),
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
