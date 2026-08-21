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
      themeMode: controller.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: controller.initializationFailed
          ? const _InitializationFailure()
          : !controller.ready
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

class _InitializationFailure extends StatelessWidget {
  const _InitializationFailure();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.storage_rounded,
                  size: 46,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  'TRACKER could not open its offline workspace.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Close and reopen the app. Your saved data was not changed.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
