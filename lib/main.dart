import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/tracker_database.dart';
import 'services/notification_service.dart';
import 'state/tracker_controller.dart';
import 'ui/tracker_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = TrackerDatabase();
  final notifications = NotificationService();
  final controller = TrackerController(database, notifications);
  runApp(
    TrackerApp(
      controller: controller,
      lightTheme: TrackerTheme.light,
      darkTheme: TrackerTheme.dark,
    ),
  );
  try {
    await database.open();
    try {
      await notifications.initialize();
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'TRACKER optional notifications',
        ),
      );
    }
    await controller.initialize();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'TRACKER initialization',
      ),
    );
    controller.markInitializationFailed();
  }
}
