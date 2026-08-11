import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<bool> requestPermission() async =>
      await plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission() ??
      false;

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
  }) async {
    if (at.isBefore(DateTime.now())) return;
    await plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tracker_reminders',
          'TRACKER reminders',
          channelDescription: 'Deadlines and planned events',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );
  }

  Future<void> cancel(int id) => plugin.cancel(id: id);

  int _morningId(DateTime date) =>
      10000000 + date.year % 100 * 10000 + date.month * 100 + date.day;

  int _eveningId(DateTime date) =>
      20000000 + date.year % 100 * 10000 + date.month * 100 + date.day;

  Future<void> scheduleDaySummary({
    required DateTime date,
    required List<String> unfinishedTitles,
  }) async {
    await cancelDaySummary(date);
    if (unfinishedTitles.isEmpty) return;

    final shortList = unfinishedTitles.take(3).toList();
    final remaining = unfinishedTitles.length - shortList.length;
    final readable = shortList.join(', ');
    final morningBody = remaining > 0
        ? 'Today you planned: $readable, and $remaining more. Choose what matters first.'
        : 'Today you planned: $readable. Give the important work a clear place in your day.';
    final eveningBody = unfinishedTitles.length == 1
        ? 'You planned to do “${unfinishedTitles.first}” today. About five hours remain—finish it or reschedule it honestly.'
        : '$readable${remaining > 0 ? ', and $remaining more' : ''} are still waiting. About five hours remain in the day.';

    final morning = DateTime(date.year, date.month, date.day, 9);
    var evening = DateTime(date.year, date.month, date.day, 19);
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now) && evening.isBefore(now)) {
      evening = now.add(const Duration(minutes: 2));
    }

    if (morning.isAfter(now)) {
      await schedule(
        id: _morningId(date),
        title: 'Your plan for today',
        body: morningBody,
        at: morning,
      );
    }
    if (evening.isAfter(now)) {
      await schedule(
        id: _eveningId(date),
        title: 'Before today closes',
        body: eveningBody,
        at: evening,
      );
    }
  }

  Future<void> cancelDaySummary(DateTime date) async {
    await cancel(_morningId(date));
    await cancel(_eveningId(date));
  }
}
