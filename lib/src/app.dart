import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/lobby/pages/lobby_page.dart';

class NeonNoirApp extends StatelessWidget {
  const NeonNoirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Noir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: NeonColors.background,
        primaryColor: NeonColors.primary,
        colorScheme: ColorScheme.dark(
          primary: NeonColors.primary,
          secondary: NeonColors.secondary,
          surface: NeonColors.surface,
        ),
        useMaterial3: true,
      ),
      home: const LobbyPage(),
    );
  }
}
