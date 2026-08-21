import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/quick_capture.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late Timer timer;
  DateTime now = DateTime.now();
  String? celebration;
  bool dayCelebration = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Future<void> completeTask(Map<String, Object?> task) async {
    final before = widget.controller.dailyScore;
    await widget.controller.completeTask(task['id'] as int);
    if (task['status'] != 'COMPLETED') {
      showCelebration(
        task['title'] as String,
        before < 100 && widget.controller.dailyScore == 100,
      );
    }
  }

  void showCelebration(String title, bool wholeDay) {
    setState(() {
      celebration = title;
      dayCelebration = wholeDay;
    });
    Future.delayed(Duration(milliseconds: wholeDay ? 5000 : 2400), () {
      if (mounted) setState(() => celebration = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final empty = c.todayTasks.isEmpty && c.todayRoutineRecords.isEmpty;
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: c.refresh,
          child: ListView(
            padding: pagePadding,
            children: [
              PageIntro(
                eyebrow: DateFormat('EEEE, MMMM d').format(now),
                title: 'Make today count.',
                subtitle:
                    'Small promises, kept consistently, become your story.',
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(now),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const LiveIndicator(),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scoreRing = SizedBox.square(
                        key: const ValueKey('daily-score-ring'),
                        dimension: 92,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: c.dailyScore / 100),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 850),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) =>
                                    CircularProgressIndicator(
                                      key: const ValueKey(
                                        'daily-score-progress-ring',
                                      ),
                                      value: value,
                                      strokeWidth: 9,
                                      backgroundColor: Theme.of(
                                        context,
                                      ).dividerColor,
                                      color: TrackerColors.gold,
                                    ),
                              ),
                            ),
                            SizedBox.square(
                              key: const ValueKey('daily-score-label-box'),
                              dimension: 40,
                              child: Center(
                                child: Text(
                                  key: const ValueKey('daily-score-label'),
                                  '${c.dailyScore}%',
                                  maxLines: 1,
                                  textScaler: TextScaler.noScaling,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontFamily: 'serif',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      final scoreDetails = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DAILY SCORE',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: TrackerColors.gold),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            '${c.completedCount} of ${c.activePlannedCount}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text('Intentional recovery days are excluded.'),
                        ],
                      );
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final useVerticalLayout =
                          constraints.maxWidth < 320 || textScale >= 1.6;
                      if (useVerticalLayout) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: scoreRing,
                            ),
                            const SizedBox(height: 18),
                            scoreDetails,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          scoreRing,
                          const SizedBox(width: 18),
                          Expanded(child: scoreDetails),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (empty)
                const EmptyCard(
                  eyebrow: 'A quiet beginning',
                  title: 'Your day is still unwritten.',
                  body: 'Use Quick add to give today one clear promise.',
                )
              else ...[
                if (c.todayRoutineRecords.isNotEmpty)
                  Text(
                    'ROUTINES',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TrackerColors.muted,
                    ),
                  ),
                const SizedBox(height: 8),
                for (final record in c.todayRoutineRecords)
                  _routineCard(context, record),
                if (c.todayTasks.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'TASKS & EVENTS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: TrackerColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                for (final task in c.todayTasks) _taskCard(context, task),
              ],
            ],
          ),
        ),
        if (celebration != null)
          Positioned.fill(
            child: CelebrationOverlay(
              title: celebration!,
              wholeDay: dayCelebration,
            ),
          ),
      ],
    );
  }

  Widget _routineCard(BuildContext context, Map<String, Object?> record) {
    final c = widget.controller;
    final routine = c.routineById(record['routine_id'] as int)!;
    final skipped = record['skipped'] == 1;
    final completed = record['completed'] == 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: skipped
            ? (Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF233029)
                  : const Color(0xFFF0F8F3))
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    completed
                        ? Icons.check_circle
                        : skipped
                        ? Icons.self_improvement
                        : Icons.radio_button_unchecked,
                    color: completed
                        ? TrackerColors.mint
                        : skipped
                        ? TrackerColors.gold
                        : TrackerColors.violet,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          skipped
                              ? 'Recovery · ${record['skip_reason']}'
                              : '${record['completed_quantity']}/${record['target_snapshot']} ${routine['unit']} · ${routine['category']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (!skipped) ...[
                    SpringIconButton(
                      tooltip: 'Decrease routine progress',
                      onPressed: () =>
                          c.progressRoutine(record['id'] as int, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('${record['completed_quantity']}'),
                    SpringIconButton(
                      tooltip: 'Increase routine progress',
                      onPressed: () async {
                        final before = c.dailyScore;
                        await c.progressRoutine(record['id'] as int, 1);
                        if (!completed) {
                          showCelebration(
                            routine['title'] as String,
                            before < 100 && c.dailyScore == 100,
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ] else
                    TextButton(
                      onPressed: () =>
                          c.progressRoutine(record['id'] as int, 0),
                      child: const Text('Restore'),
                    ),
                ],
              ),
              if (!completed && !skipped)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _recovery(context, record['id'] as int),
                    icon: const Icon(Icons.spa_outlined, size: 18),
                    label: const Text('Recovery day'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskCard(BuildContext context, Map<String, Object?> task) {
    final c = widget.controller;
    final done = task['status'] == 'COMPLETED';
    final items = c.subtasksFor(task['id'] as int);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  SpringIconButton(
                    tooltip: done ? 'Mark task incomplete' : 'Complete task',
                    onPressed: () => completeTask(task),
                    icon: Icon(
                      done
                          ? Icons.check_circle
                          : task['item_type'] == 'EVENT'
                          ? Icons.event_outlined
                          : Icons.radio_button_unchecked,
                      color: done ? TrackerColors.mint : TrackerColors.gold,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '${task['item_type']} · ${task['all_day'] == 1 ? 'All day' : task['start_time'] ?? task['deadline']} · ${task['estimated_minutes']} min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editTask(context, task);
                      if (v == 'archive') c.archiveTask(task['id'] as int);
                      if (v == 'skip') {
                        c.resolveTask(
                          task['id'] as int,
                          'SKIPPED',
                          note: 'Intentionally skipped',
                        );
                      }
                      if (v == 'drop') {
                        c.resolveTask(task['id'] as int, 'DROPPED');
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'skip',
                        child: Text('Skip intentionally'),
                      ),
                      PopupMenuItem(value: 'drop', child: Text('Drop')),
                      PopupMenuItem(value: 'archive', child: Text('Archive')),
                    ],
                  ),
                ],
              ),
              if (items.isNotEmpty) ...[
                const Divider(),
                for (final item in items)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(item['title'] as String),
                    value: item['done'] == 1,
                    onChanged: (_) => c.toggleSubtask(item['id'] as int),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _recovery(BuildContext context, int recordId) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose intentional recovery'),
        content: TextField(
          controller: reason,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Why does rest matter today?',
            hintText: 'Recovery protects consistency.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              widget.controller.skipRoutine(
                recordId,
                reason.text.isEmpty ? 'Intentional recovery' : reason.text,
              );
              Navigator.pop(context);
            },
            child: const Text('Take recovery day'),
          ),
        ],
      ),
    ).whenComplete(reason.dispose);
  }

  void _editTask(BuildContext context, Map<String, Object?> task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          QuickCapture(controller: widget.controller, existingTask: task),
    );
  }
}
