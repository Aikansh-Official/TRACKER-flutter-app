import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../state/tracker_controller.dart';
import 'screens/calendar_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/mood_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/routines_screen.dart';
import 'screens/today_screen.dart';
import 'widgets/quick_capture.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.controller});
  final TrackerController controller;

  static const destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Overview'),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Plan'),
    (Icons.check_circle_outline, Icons.check_circle, 'Today'),
    (Icons.track_changes_outlined, Icons.track_changes, 'Routines'),
    (
      Icons.sentiment_satisfied_alt_outlined,
      Icons.sentiment_satisfied_alt,
      'Mood',
    ),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar'),
    (Icons.insights_outlined, Icons.insights, 'Insights'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      OverviewScreen(controller: controller),
      PlanScreen(controller: controller),
      TodayScreen(controller: controller),
      RoutinesScreen(controller: controller),
      MoodScreen(controller: controller),
      CalendarScreen(controller: controller),
      InsightsScreen(controller: controller),
    ];
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: TrackerColors.violet,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'TRACKER',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'serif',
                letterSpacing: .8,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: controller.darkMode ? 'Use light mode' : 'Use dark mode',
            onPressed: controller.toggleTheme,
            icon: Icon(
              controller.darkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Workspace menu',
            onSelected: (value) {
              if (value == 'json') controller.exportJson();
              if (value == 'ics') controller.exportIcs();
              if (value == 'lock') controller.lock();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'json',
                child: ListTile(
                  leading: Icon(Icons.data_object),
                  title: Text('Export all data'),
                ),
              ),
              PopupMenuItem(
                value: 'ics',
                child: ListTile(
                  leading: Icon(Icons.calendar_month),
                  title: Text('Export calendar'),
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'lock',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Lock workspace'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: controller.page, children: pages),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'reminders',
            tooltip: 'Reminder center',
            onPressed: () => _showReminders(context),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'quick-add',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => QuickCapture(controller: controller),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            icon: const Icon(Icons.add),
            label: const Text(
              'Quick add',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: controller.page,
        onDestinationSelected: controller.navigate,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.$1),
              selectedIcon: Icon(d.$2),
              label: d.$3,
            ),
        ],
      ),
    );
  }

  void _showReminders(BuildContext context) {
    final upcoming = controller.tasks
        .where(
          (e) =>
              e['reminder_minutes'] != null &&
              ![
                'COMPLETED',
                'SKIPPED',
                'DROPPED',
                'DELEGATED',
                'ARCHIVED',
              ].contains(e['status']),
        )
        .take(8)
        .toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'REMINDER CENTER',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
              ),
              const SizedBox(height: 8),
              Text(
                'Let the day remember with you.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 7),
              Text(
                'At 9:00 AM, TRACKER can remind you what you planned. Around 7:00 PM—about five hours before midnight—it can name only the tasks and routines that are still unfinished.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              if (upcoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No reminders in the next 24 hours.'),
                )
              else
                for (final item in upcoming)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      child: Icon(Icons.notifications_none, size: 18),
                    ),
                    title: Text(item['title'] as String),
                    subtitle: Text(
                      '${item['scheduled_date']} · ${item['start_time'] ?? item['deadline'] ?? 'All day'}',
                    ),
                  ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile.adaptive(
                  secondary: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Smart day reminders'),
                  subtitle: Text(
                    controller.smartRemindersEnabled
                        ? 'Morning plan and unfinished-evening reminders are active.'
                        : 'Off until you explicitly allow notifications.',
                  ),
                  value: controller.smartRemindersEnabled,
                  onChanged: (enabled) async {
                    final changed = await controller.setSmartReminders(enabled);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !changed
                              ? 'Notification permission was not granted.'
                              : enabled
                              ? 'Smart reminders are scheduled from your real plans.'
                              : 'Smart day reminders are turned off.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
