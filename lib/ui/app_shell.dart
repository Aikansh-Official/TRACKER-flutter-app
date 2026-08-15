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
    final compactNavigation =
        MediaQuery.sizeOf(context).width < 370 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final pages = [
      OverviewScreen(controller: controller),
      PlanScreen(controller: controller),
      TodayScreen(controller: controller),
      RoutinesScreen(controller: controller),
      MoodScreen(controller: controller),
      CalendarScreen(controller: controller),
      InsightsScreen(controller: controller),
    ];
    return PopScope(
      canPop: controller.page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.navigate(0);
      },
      child: Scaffold(
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
              Flexible(
                child: Text(
                  'TRACKER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'serif',
                    letterSpacing: .8,
                  ),
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
            IconButton(
              tooltip: 'Reminder center',
              onPressed: () => _showReminders(context),
              icon: const Icon(Icons.notifications_none_rounded),
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
          child: _DestinationStage(
            selectedIndex: controller.page,
            children: pages,
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: 'quick-add',
              tooltip: 'Quick add',
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (_) => QuickCapture(controller: controller),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          labelBehavior: compactNavigation
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
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

class _DestinationStage extends StatelessWidget {
  const _DestinationStage({
    required this.selectedIndex,
    required this.children,
  });

  final int selectedIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < children.length; index++)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: index != selectedIndex,
              child: ExcludeSemantics(
                excluding: index != selectedIndex,
                child: AnimatedOpacity(
                  opacity: index == selectedIndex ? 1 : 0,
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: AnimatedScale(
                    scale: index == selectedIndex || reduced ? 1 : .985,
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.center,
                    child: TickerMode(
                      enabled: index == selectedIndex,
                      child: RepaintBoundary(child: children[index]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
