import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.controller});
  final TrackerController controller;
  @override
  Widget build(BuildContext context) {
    final mood = controller.moodFor(controller.todayKey);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: pagePadding,
        children: [
          PageIntro(
            eyebrow: 'TRACKER OVERVIEW · OFFLINE & PRIVATE',
            title: 'Your day, without the noise.',
            subtitle:
                'Priorities, wellbeing, and progress in one honest workspace.',
            trailing: CircleAvatar(
              backgroundColor: TrackerColors.softGold,
              child: Text(
                (controller.profile?['name'] as String? ?? 'T').characters.first
                    .toUpperCase(),
                style: const TextStyle(
                  color: TrackerColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 138,
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                MetricCard(
                  label: 'Daily score',
                  value: '${controller.dailyScore}%',
                  caption: '${controller.activePlannedCount} active items',
                  color: TrackerColors.gold,
                ),
                MetricCard(
                  label: 'Routines',
                  value:
                      '${controller.todayRoutineRecords.where((e) => e['completed'] == 1).length}/${controller.todayRoutineRecords.length}',
                  caption: 'completed today',
                ),
                MetricCard(
                  label: 'Mood',
                  value: mood == null ? '—' : '${mood['mood']}/5',
                  caption: mood == null ? 'not checked in' : 'today’s check-in',
                ),
                MetricCard(
                  label: 'Pending',
                  value: '${controller.pendingTasks.length}',
                  caption: 'needs a decision',
                  color: controller.pendingTasks.isEmpty
                      ? TrackerColors.mint
                      : TrackerColors.coral,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'YOUR WORKSPACE',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: TrackerColors.muted),
          ),
          const SizedBox(height: 12),
          _route(
            context,
            Icons.check_circle_outline,
            'Today',
            'Complete what matters and protect recovery.',
            2,
          ),
          _route(
            context,
            Icons.sentiment_satisfied_alt,
            'Mood studio',
            'Record mood, energy, stress, focus, sleep, and context.',
            4,
          ),
          _route(
            context,
            Icons.track_changes,
            'Routines',
            'Shape habits without pretending every day is identical.',
            3,
          ),
          _route(
            context,
            Icons.calendar_month,
            'Calendar',
            'See dates, deadlines, events, and a week timeboard.',
            5,
          ),
          _route(
            context,
            Icons.insights,
            'Insights',
            'Read truthful patterns from saved history.',
            6,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _manage(context, false),
                  icon: const Icon(Icons.pending_actions),
                  label: Text('Pending (${controller.pendingTasks.length})'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _manage(context, true),
                  icon: const Icon(Icons.archive_outlined),
                  label: Text('Archive (${controller.archivedItems.length})'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _route(
    BuildContext context,
    IconData icon,
    String title,
    String body,
    int page,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => controller.navigate(page),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: TrackerColors.softGold,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: TrackerColors.gold),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(body, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded),
            ],
          ),
        ),
      ),
    ),
  );
  void _manage(BuildContext context, bool archive) {
    final list = archive ? controller.archivedItems : controller.pendingTasks;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                archive ? 'ARCHIVE' : 'PENDING',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
              ),
              const SizedBox(height: 7),
              Text(
                archive ? 'Kept, not erased.' : 'Make a clean decision.',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 15),
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text(
                    archive
                        ? 'Your archive is empty.'
                        : 'Nothing is waiting for you.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    children: [
                      for (final item in list)
                        ListTile(
                          title: Text(item['title'] as String),
                          subtitle: Text(item['scheduled_date'] as String),
                          trailing: archive
                              ? TextButton(
                                  onPressed: () {
                                    controller.archiveTask(
                                      item['id'] as int,
                                      restore: true,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Restore'),
                                )
                              : TextButton(
                                  onPressed: () {
                                    controller.updateTask(item['id'] as int, {
                                      'scheduled_date': controller.todayKey,
                                      'status': 'TODAY',
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Today'),
                                ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
