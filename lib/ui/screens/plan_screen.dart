import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController tabs;
  @override
  void initState() {
    super.initState();
    tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TabBar(
        controller: tabs,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Plan'),
          Tab(text: 'Focus'),
          Tab(text: 'Goals'),
          Tab(text: 'Weekly review'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: tabs,
          children: [
            _DailyPlan(controller: widget.controller),
            _Focus(controller: widget.controller),
            _Goals(controller: widget.controller),
            _Review(controller: widget.controller),
          ],
        ),
      ),
    ],
  );
}

class _DailyPlan extends StatefulWidget {
  const _DailyPlan({required this.controller});
  final TrackerController controller;
  @override
  State<_DailyPlan> createState() => _DailyPlanState();
}

class _DailyPlanState extends State<_DailyPlan> {
  final intention = TextEditingController(),
      implementation = TextEditingController(),
      shutdown = TextEditingController();
  String capacity = 'NORMAL';
  final selected = <int>{};
  bool loaded = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      final p = widget.controller.plans
          .where((e) => e['date'] == widget.controller.todayKey)
          .firstOrNull;
      if (p != null) {
        intention.text = p['intention'] as String;
        implementation.text = p['implementation_intention'] as String;
        shutdown.text = p['shutdown_note'] as String;
        capacity = p['capacity'] as String;
        selected.addAll(
          (p['priority_ids'] as String)
              .split(',')
              .where((e) => e.isNotEmpty)
              .map(int.parse),
        );
      }
      loaded = true;
    }
  }

  @override
  void dispose() {
    intention.dispose();
    implementation.dispose();
    shutdown.dispose();
    super.dispose();
  }

  int get planned => widget.controller.todayTasks
      .where((e) => selected.contains(e['id']))
      .fold(0, (s, e) => s + (e['estimated_minutes'] as int));
  int get limit => capacity == 'LOW'
      ? 180
      : capacity == 'HIGH'
      ? 480
      : 360;
  @override
  Widget build(BuildContext context) => ListView(
    padding: pagePadding,
    children: [
      const PageIntro(
        eyebrow: 'PRODUCTIVITY STUDIO',
        title: 'Plan with your real capacity.',
        subtitle: 'Choose less, define the trigger, and protect the shutdown.',
      ),
      const SizedBox(height: 20),
      SectionCard(
        eyebrow: 'Today’s intention',
        title: 'What would make today meaningful?',
        child: Column(
          children: [
            TextField(
              controller: intention,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'One clear outcome, written in your own words.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: implementation,
              maxLength: 400,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'If–then plan',
                hintText: 'If it is 7:00 PM, then I will study DSA at my desk.',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'LOW', label: Text('Low')),
                ButtonSegment(value: 'NORMAL', label: Text('Normal')),
                ButtonSegment(value: 'HIGH', label: Text('High')),
              ],
              selected: {capacity},
              onSelectionChanged: (v) => setState(() => capacity = v.first),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (planned / limit).clamp(0, 1),
              minHeight: 9,
              borderRadius: BorderRadius.circular(10),
              color: planned > limit ? TrackerColors.coral : TrackerColors.gold,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('$planned of $limit minutes planned')),
                if (planned > limit)
                  const Text(
                    'Over capacity',
                    style: TextStyle(
                      color: TrackerColors.coral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SectionCard(
        eyebrow: 'The vital three',
        title: 'Protect up to three priorities',
        child: widget.controller.todayTasks.isEmpty
            ? const Text('Add tasks for today before choosing priorities.')
            : Column(
                children: [
                  for (final t in widget.controller.todayTasks)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t['title'] as String),
                      subtitle: Text('${t['estimated_minutes']} min'),
                      value: selected.contains(t['id']),
                      onChanged: (on) {
                        setState(() {
                          if (on == true && selected.length < 3)
                            selected.add(t['id'] as int);
                          if (on == false) selected.remove(t['id']);
                        });
                      },
                    ),
                ],
              ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: shutdown,
        maxLength: 600,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Shutdown note',
          hintText: 'What can tomorrow safely hold?',
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        onPressed: () async {
          await widget.controller.savePlan({
            'date': widget.controller.todayKey,
            'intention': intention.text.trim(),
            'implementation_intention': implementation.text.trim(),
            'capacity': capacity,
            'priority_ids': selected.join(','),
            'shutdown_note': shutdown.text.trim(),
          });
          if (context.mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Today’s plan is saved offline.')),
            );
        },
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save today’s plan'),
      ),
    ],
  );
}

class _Focus extends StatefulWidget {
  const _Focus({required this.controller});
  final TrackerController controller;
  @override
  State<_Focus> createState() => _FocusState();
}

class _FocusState extends State<_Focus> {
  Timer? timer;
  DateTime now = DateTime.now();
  final title = TextEditingController();
  int minutes = 25;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => now = DateTime.now());
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.controller.focusSessions
        .where((e) => e['status'] == 'ACTIVE')
        .firstOrNull;
    return ListView(
      padding: pagePadding,
      children: [
        const PageIntro(
          eyebrow: 'DEEP WORK',
          title: 'Protect one honest block.',
          subtitle:
              'One active session at a time. Distractions are recorded, not judged.',
        ),
        const SizedBox(height: 20),
        if (active != null)
          _active(context, active)
        else
          SectionCard(
            eyebrow: 'Start focus',
            title: 'What deserves your full attention?',
            child: Column(
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Focus title',
                    hintText: 'e.g. Solve two graph problems',
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final m in [15, 25, 45, 60, 90])
                      ChoiceChip(
                        label: Text('$m min'),
                        selected: minutes == m,
                        onSelected: (_) => setState(() => minutes = m),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                FilledButton.icon(
                  onPressed: () async {
                    final err = await widget.controller.startFocus(
                      title: title.text.trim().isEmpty
                          ? 'Focused work'
                          : title.text.trim(),
                      minutes: minutes,
                    );
                    if (context.mounted && err != null)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Begin focus'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 15),
        SectionCard(
          eyebrow: 'Recent sessions',
          title: 'Evidence of protected attention',
          child:
              widget.controller.focusSessions
                  .where((e) => e['status'] != 'ACTIVE')
                  .isEmpty
              ? const Text('Your first completed session will appear here.')
              : Column(
                  children: [
                    for (final s
                        in widget.controller.focusSessions
                            .where((e) => e['status'] != 'ACTIVE')
                            .take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          s['status'] == 'COMPLETED'
                              ? Icons.check_circle
                              : Icons.stop_circle_outlined,
                          color: s['status'] == 'COMPLETED'
                              ? TrackerColors.mint
                              : TrackerColors.muted,
                        ),
                        title: Text(s['title'] as String),
                        subtitle: Text(
                          '${s['duration_minutes'] ?? 0} actual / ${s['planned_minutes']} planned · ${s['distractions']} distractions',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _active(BuildContext context, Map<String, Object?> s) {
    final started = DateTime.parse(s['started_at'] as String);
    final elapsed = now.difference(started);
    final left = Duration(minutes: s['planned_minutes'] as int) - elapsed;
    final display = left.isNegative ? elapsed : left;
    final label = left.isNegative ? 'OVER BY' : 'REMAINING';
    return SectionCard(
      eyebrow: 'Focus is active',
      title: s['title'] as String,
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
          ),
          Text(
            '${display.inMinutes.abs().toString().padLeft(2, '0')}:${(display.inSeconds.abs() % 60).toString().padLeft(2, '0')}',
            style: Theme.of(
              context,
            ).textTheme.displayLarge?.copyWith(fontSize: 58),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => widget.controller.updateFocus(
                  s['id'] as int,
                  distractions: (s['distractions'] as int) + 1,
                ),
                icon: const Icon(Icons.add),
                label: Text('${s['distractions']} distractions'),
              ),
              const SizedBox(width: 9),
              FilledButton(
                onPressed: () => widget.controller.updateFocus(
                  s['id'] as int,
                  finishStatus: 'COMPLETED',
                ),
                child: const Text('Complete'),
              ),
            ],
          ),
          TextButton(
            onPressed: () => widget.controller.updateFocus(
              s['id'] as int,
              finishStatus: 'ABANDONED',
            ),
            child: const Text('Abandon honestly'),
          ),
        ],
      ),
    );
  }
}

class _Goals extends StatelessWidget {
  const _Goals({required this.controller});
  final TrackerController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: pagePadding,
    children: [
      PageIntro(
        eyebrow: 'GOALS',
        title: 'Direction, broken into proof.',
        subtitle: 'Milestones turn distant ambition into visible movement.',
        trailing: IconButton.filled(
          onPressed: () => _add(context),
          icon: const Icon(Icons.add),
        ),
      ),
      const SizedBox(height: 20),
      if (controller.goals.where((e) => e['status'] != 'ARCHIVED').isEmpty)
        const EmptyCard(
          eyebrow: 'No active goals',
          title: 'Name the direction.',
          body:
              'Create a goal, then define milestones you can actually finish.',
          icon: Icons.flag_outlined,
        )
      else
        for (final g in controller.goals.where(
          (e) => e['status'] != 'ARCHIVED',
        ))
          _goal(context, g),
    ],
  );
  Widget _goal(BuildContext context, Map<String, Object?> g) {
    final ms = controller.milestones
        .where((e) => e['goal_id'] == g['id'])
        .toList();
    final done = ms.where((e) => e['done'] == 1).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        eyebrow: g['life_area'] as String,
        title: g['title'] as String,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((g['description'] as String).isNotEmpty)
              Text(g['description'] as String),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: ms.isEmpty ? 0 : done / ms.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: TrackerColors.gold,
            ),
            const SizedBox(height: 5),
            Text('$done of ${ms.length} milestones'),
            for (final m in ms)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m['title'] as String),
                value: m['done'] == 1,
                onChanged: (_) => controller.toggleMilestone(m['id'] as int),
              ),
          ],
        ),
      ),
    );
  }

  void _add(BuildContext context) {
    final title = TextEditingController();
    final description = TextEditingController();
    final milestones = TextEditingController();
    var area = 'STUDY';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 28,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'NEW GOAL',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Goal title'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Why it matters',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: area,
                  decoration: const InputDecoration(labelText: 'Life area'),
                  items: [
                    for (final value in const [
                      'STUDY',
                      'CAREER',
                      'HEALTH',
                      'FITNESS',
                      'PERSONAL',
                      'OTHER',
                    ])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => setSheetState(() => area = value!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: milestones,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Milestones',
                    hintText: 'One milestone per line',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    if (title.text.trim().isEmpty) return;
                    await controller.createGoal({
                      'title': title.text.trim(),
                      'description': description.text.trim(),
                      'life_area': area,
                      'status': 'ACTIVE',
                    }, milestones.text.split('\n'));
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create goal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Review extends StatefulWidget {
  const _Review({required this.controller});
  final TrackerController controller;
  @override
  State<_Review> createState() => _ReviewState();
}

class _ReviewState extends State<_Review> {
  final wins = TextEditingController(),
      lessons = TextEditingController(),
      next = TextEditingController();
  int rating = 3;
  bool loaded = false;
  String get week {
    final d = DateTime.now();
    return DateFormat(
      'yyyy-MM-dd',
    ).format(d.subtract(Duration(days: d.weekday - 1)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!loaded) {
      final r = widget.controller.weeklyReviews
          .where((e) => e['week_start'] == week)
          .firstOrNull;
      if (r != null) {
        wins.text = r['wins'] as String;
        lessons.text = r['lessons'] as String;
        next.text = r['next_week_focus'] as String;
        rating = r['rating'] as int;
      }
      loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: pagePadding,
    children: [
      PageIntro(
        eyebrow: 'WEEK OF $week',
        title: 'Review without self-deception.',
        subtitle: 'Keep the lesson. Release the guilt.',
      ),
      const SizedBox(height: 20),
      SectionCard(
        eyebrow: 'Reflection',
        title: 'What did this week teach you?',
        child: Column(
          children: [
            TextField(
              controller: wins,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Wins',
                hintText: 'What moved, however quietly?',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lessons,
              maxLength: 1000,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Lessons',
                hintText: 'What should change next time?',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: next,
              maxLength: 600,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Next week’s focus'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Week rating'),
                Expanded(
                  child: Slider(
                    value: rating.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$rating',
                    onChanged: (v) => setState(() => rating = v.round()),
                  ),
                ),
                Text('$rating/5'),
              ],
            ),
            FilledButton.icon(
              onPressed: () async {
                await widget.controller.saveWeeklyReview({
                  'week_start': week,
                  'wins': wins.text,
                  'lessons': lessons.text,
                  'next_week_focus': next.text,
                  'rating': rating,
                  'snapshot': jsonEncode({
                    'score': widget.controller.dailyScore,
                    'completed': widget.controller.completedCount,
                  }),
                });
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Weekly review saved.')),
                  );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save weekly review'),
            ),
          ],
        ),
      ),
    ],
  );
}
