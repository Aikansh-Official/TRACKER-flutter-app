import 'dart:async';
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

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.controller});
  final TrackerController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  Timer? _dayChangeTimer;

  TrackerController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dayChangeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => controller.refreshIfDayChanged(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.refreshIfDayChanged();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayChangeTimer?.cancel();
    super.dispose();
  }

  static const destinations = [
    (Icons.check_circle_outline, Icons.check_circle, 'Today', 2),
    (Icons.auto_awesome_outlined, Icons.auto_awesome, 'Plan', 1),
    (Icons.calendar_month_outlined, Icons.calendar_month, 'Calendar', 5),
  ];

  int get _selectedDestination => switch (controller.page) {
    2 => 0,
    1 => 1,
    5 => 2,
    _ => 3,
  };

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
      canPop: controller.page == 2,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.navigate(2);
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
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'quick-add',
          tooltip: 'Add task or event',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => QuickCapture(controller: controller),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add task'),
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          labelBehavior: compactNavigation
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _selectedDestination,
          onDestinationSelected: (index) {
            if (index == destinations.length) {
              _showMore(context);
            } else {
              controller.navigate(destinations[index].$4);
            }
          },
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.$1),
                selectedIcon: Icon(d.$2),
                label: d.$3,
              ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }

  void _showMore(BuildContext context) {
    final tools = [
      (Icons.home_outlined, 'Overview', 'A simple snapshot of your day.', 0),
      (
        Icons.track_changes_outlined,
        'Routines',
        'Build habits at your pace.',
        3,
      ),
      (
        Icons.sentiment_satisfied_alt_outlined,
        'Mood',
        'A private wellbeing check-in.',
        4,
      ),
      (
        Icons.insights_outlined,
        'Insights',
        'See patterns from saved history.',
        6,
      ),
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: .9,
        minChildSize: .5,
        maxChildSize: .95,
        expand: false,
        builder: (context, scrollController) => SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
            children: [
              Text(
                'MORE TOOLS',
                style: Theme.of(
                  sheetContext,
                ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
              ),
              const SizedBox(height: 6),
              Text(
                'Everything else, when you need it.',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              for (final tool in tools)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 8,
                  leading: CircleAvatar(child: Icon(tool.$1)),
                  title: Text(tool.$2),
                  subtitle: Text(tool.$3),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    controller.navigate(tool.$4);
                  },
                ),
              const Divider(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.notifications_none_rounded),
                ),
                title: const Text('Reminders'),
                subtitle: const Text('Manage task and day reminders.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showReminders(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReminders(BuildContext context) {
    final now = DateTime.now();
    final horizon = now.add(const Duration(hours: 24));
    final candidates =
        controller.tasks
            .where(
              (e) =>
                  controller.taskReminderAt(e) != null &&
                  !controller.taskReminderAt(e)!.isBefore(now) &&
                  !controller.taskReminderAt(e)!.isAfter(horizon) &&
                  ![
                    'COMPLETED',
                    'SKIPPED',
                    'DROPPED',
                    'DELEGATED',
                    'ARCHIVED',
                  ].contains(e['status']),
            )
            .toList()
          ..sort(
            (a, b) => controller
                .taskReminderAt(a)!
                .compareTo(controller.taskReminderAt(b)!),
          );
    final upcoming = candidates.take(8).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
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
