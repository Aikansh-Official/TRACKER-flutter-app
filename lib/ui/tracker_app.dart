import 'package:flutter/material.dart';
import '../state/tracker_controller.dart';
import 'auth_screen.dart';
import 'app_shell.dart';

class TrackerApp extends StatelessWidget {
  const TrackerApp({
    super.key,
    required this.controller,
    required this.lightTheme,
    required this.darkTheme,
  });
  final TrackerController controller;
  final ThemeData lightTheme;
  final ThemeData darkTheme;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => MaterialApp(
      title: 'TRACKER',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: controller.darkMode && controller.unlocked
          ? ThemeMode.dark
          : ThemeMode.light,
      home: !controller.ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : controller.profile == null || !controller.unlocked
          ? AuthScreen(
              controller: controller,
              hasProfile: controller.profile != null,
            )
          : AppShell(controller: controller),
    ),
  );
}
