import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen>
    with SingleTickerProviderStateMixin {
  int mood = 3, energy = 3, stress = 3, focus = 3;
  double sleep = 7;
  final note = TextEditingController();
  final emotions = <String>{}, factors = <String>{};
  bool loaded = false;
  late final AnimationController _orbitController;
  static const emotionOptions = [
    'Calm',
    'Hopeful',
    'Focused',
    'Proud',
    'Joyful',
    'Tired',
    'Anxious',
    'Sad',
    'Frustrated',
    'Lonely',
    'Overwhelmed',
    'Restless',
  ];
  static const factorOptions = [
    'Study',
    'Work',
    'Health',
    'Sleep',
    'Exercise',
    'Food',
    'Family',
    'Friends',
    'Weather',
    'Finances',
    'Screen time',
    'Rest',
  ];
  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _orbitController
        ..stop()
        ..value = .5;
    } else if (!_orbitController.isAnimating) {
      _orbitController.repeat(reverse: true);
    }
    if (!loaded) {
      final e = widget.controller.moodFor(widget.controller.todayKey);
      if (e != null) {
        mood = e['mood'] as int;
        energy = e['energy'] as int;
        stress = e['stress'] as int;
        focus = e['focus'] as int;
        sleep = e['sleep_hours'] as double;
        note.text = e['note'] as String;
        emotions.addAll(
          (e['emotions'] as String).split(',').where((x) => x.isNotEmpty),
        );
        factors.addAll(
          (e['factors'] as String).split(',').where((x) => x.isNotEmpty),
        );
      }
      loaded = true;
    }
  }

  @override
  void dispose() {
    _orbitController.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: widget.controller.refresh,
    child: ListView(
      padding: pagePadding,
      children: [
        const PageIntro(
          eyebrow: 'MOOD STUDIO',
          title: 'Notice the weather within.',
          subtitle: 'Mood is context—not a grade, diagnosis, or target.',
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _moodOrbit(context),
                const SizedBox(height: 20),
                _slider(
                  'Mood',
                  mood,
                  Icons.sentiment_satisfied_alt,
                  (v) => setState(() => mood = v),
                ),
                _slider(
                  'Energy',
                  energy,
                  Icons.bolt_outlined,
                  (v) => setState(() => energy = v),
                ),
                _slider(
                  'Stress',
                  stress,
                  Icons.waves_outlined,
                  (v) => setState(() => stress = v),
                  reverse: true,
                ),
                _slider(
                  'Focus',
                  focus,
                  Icons.center_focus_strong,
                  (v) => setState(() => focus = v),
                ),
                _sleepSlider(),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _chips(
          context,
          'EMOTIONS',
          'What feelings are present?',
          emotionOptions,
          emotions,
        ),
        const SizedBox(height: 14),
        _chips(
          context,
          'CONTEXT',
          'What shaped today?',
          factorOptions,
          factors,
        ),
        const SizedBox(height: 14),
        SectionCard(
          eyebrow: 'Private reflection',
          title: 'A note to your future self',
          child: TextField(
            controller: note,
            maxLength: 600,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'What happened, and what do you need?',
            ),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () async {
            await widget.controller.saveMood({
              'date': widget.controller.todayKey,
              'mood': mood,
              'energy': energy,
              'stress': stress,
              'focus': focus,
              'sleep_hours': sleep,
              'emotions': emotions.join(','),
              'factors': factors.join(','),
              'note': note.text.trim(),
            });
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Today’s check-in is saved offline.'),
                ),
              );
            }
          },
          icon: const Icon(Icons.favorite_outline),
          label: const Text('Save today’s check-in'),
        ),
        const SizedBox(height: 24),
        _analytics(context),
      ],
    ),
  );
  Widget _moodOrbit(BuildContext context) {
    final faces = ['😞', '😕', '😐', '🙂', '😄'];
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, _) => SizedBox(
        height: 170,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: TrackerColors.gold.withValues(alpha: .45),
                ),
                gradient: RadialGradient(
                  colors: [
                    TrackerColors.softGold.withValues(alpha: .7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            for (var i = 0; i < 5; i++)
              Builder(
                builder: (context) {
                  final direction = i.isEven ? 1.0 : -.64;
                  final angle =
                      (i * 72 -
                          90 +
                          (_orbitController.value - .5) * 10 * direction) *
                      pi /
                      180;
                  final depth = .5 + .5 * sin(angle + pi / 2);
                  final radius = 69 + (i % 3) * 2.5;
                  final selected = mood == i + 1;
                  return Transform.translate(
                    offset: Offset(
                      cos(angle) * radius,
                      sin(angle) * radius * (.97 + depth * .04),
                    ),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, .0015)
                        ..rotateY((depth - .5) * .12)
                        ..scaleByDouble(
                          selected ? 1.08 : .9 + depth * .14,
                          selected ? 1.08 : .9 + depth * .14,
                          1,
                          1,
                        ),
                      child: GestureDetector(
                        onTap: () => setState(() => mood = i + 1),
                        child: AnimatedContainer(
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          width: selected ? 48 : 40,
                          height: selected ? 48 : 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? TrackerColors.gold
                                : Theme.of(context).colorScheme.surface,
                            border: Border.all(
                              color: selected
                                  ? TrackerColors.gold
                                  : Theme.of(context).dividerColor,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: .04 + depth * .08,
                                ),
                                blurRadius: 3 + depth * 8,
                                offset: Offset(0, 2 + depth * 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            faces[i],
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$mood',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: TrackerColors.gold,
                  ),
                ),
                Text('OF 5', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _slider(
    String label,
    int value,
    IconData icon,
    ValueChanged<int> change, {
    bool reverse = false,
  }) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 300;
      final heading = Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text('$value/5'),
        ],
      );
      final slider = Slider(
        value: value.toDouble(),
        min: 1,
        max: 5,
        divisions: 4,
        label: '$value',
        onChanged: (v) => change(v.round()),
      );
      if (compact) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [heading, slider]),
        );
      }
      return Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          SizedBox(width: 62, child: Text(label)),
          Expanded(child: slider),
          Text('$value/5'),
        ],
      );
    },
  );

  Widget _sleepSlider() => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 300;
      final value = '${sleep.toStringAsFixed(1)} h';
      final heading = Row(
        children: [
          const Icon(Icons.bedtime_outlined),
          const SizedBox(width: 10),
          const Expanded(child: Text('Sleep')),
          Text(value),
        ],
      );
      final slider = Slider(
        value: sleep,
        min: 0,
        max: 12,
        divisions: 24,
        label: value,
        onChanged: (v) => setState(() => sleep = v),
      );
      if (compact) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [heading, slider]),
        );
      }
      return Row(
        children: [
          const Icon(Icons.bedtime_outlined),
          const SizedBox(width: 10),
          const SizedBox(width: 62, child: Text('Sleep')),
          Expanded(child: slider),
          Text(value),
        ],
      );
    },
  );
  Widget _chips(
    BuildContext context,
    String eyebrow,
    String title,
    List<String> options,
    Set<String> chosen,
  ) => SectionCard(
    eyebrow: eyebrow,
    title: title,
    child: Wrap(
      spacing: 7,
      runSpacing: 5,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(option),
            selected: chosen.contains(option),
            onSelected: (on) =>
                setState(() => on ? chosen.add(option) : chosen.remove(option)),
          ),
      ],
    ),
  );
  Widget _analytics(BuildContext context) {
    final entries = widget.controller.moods;
    if (entries.isEmpty) {
      return const EmptyCard(
        eyebrow: 'No history yet',
        title: 'The first point begins the story.',
        body:
            'Save today’s check-in. Trends will appear only when real history exists.',
        icon: Icons.insights,
      );
    }
    return SectionCard(
      eyebrow: 'Saved mood history',
      title: entries.length == 1
          ? 'One point is a check-in, not yet a trend.'
          : 'Your inner weather over time',
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: 1,
                maxY: 5,
                gridData: const FlGridData(show: true),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  _line(entries, 'mood', TrackerColors.gold),
                  _line(entries, 'energy', TrackerColors.violet),
                  _line(entries, 'stress', TrackerColors.coral),
                  _line(entries, 'focus', TrackerColors.mint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 14,
            children: [
              _Legend('Mood', TrackerColors.gold),
              _Legend('Energy', TrackerColors.violet),
              _Legend('Stress', TrackerColors.coral),
              _Legend('Focus', TrackerColors.mint),
            ],
          ),
          const Divider(height: 28),
          for (final e in entries.reversed.take(7))
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                DateFormat(
                  'EEE, d MMM',
                ).format(DateTime.parse(e['date'] as String)),
              ),
              subtitle: Text(
                (e['note'] as String).isEmpty
                    ? 'No written reflection'
                    : e['note'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                '${e['mood']}/5',
                style: const TextStyle(
                  color: TrackerColors.gold,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  LineChartBarData _line(
    List<Map<String, Object?>> entries,
    String field,
    Color color,
  ) => LineChartBarData(
    spots: [
      for (var i = 0; i < entries.length; i++)
        FlSpot(i.toDouble(), (entries[i][field] as int).toDouble()),
    ],
    color: color,
    barWidth: 3,
    isCurved: true,
    dotData: FlDotData(show: entries.length < 16),
    belowBarData: BarAreaData(show: true, color: color.withValues(alpha: .08)),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}
