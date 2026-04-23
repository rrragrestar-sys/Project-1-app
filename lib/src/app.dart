import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/onboarding/pages/splash_page.dart';

class LuckyKingApp extends StatelessWidget {
  const LuckyKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky King',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonColors.background,
        primaryColor: NeonColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: NeonColors.primary,
          secondary: NeonColors.secondary,
          surface: NeonColors.surface,
        ),
        useMaterial3: true,
      ),
      home: const SplashPage(),
    );
  }
}
