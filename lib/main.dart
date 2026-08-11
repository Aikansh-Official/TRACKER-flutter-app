import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/tracker_database.dart';
import 'services/notification_service.dart';
import 'state/tracker_controller.dart';
import 'ui/tracker_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = TrackerDatabase();
  await database.open();
  final notifications = NotificationService();
  await notifications.initialize();
  final controller = TrackerController(database, notifications);
  await controller.initialize();
  runApp(
    TrackerApp(
      controller: controller,
      lightTheme: TrackerTheme.light,
      darkTheme: TrackerTheme.dark,
    ),
  );
}
