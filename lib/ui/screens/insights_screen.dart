import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.controller});
  final TrackerController controller;
  List<DateTime> get dates {
    final keys = <String>{
      ...controller.routineRecords.map((e) => e['date'] as String),
      ...controller.tasks
          .where((e) => e['status'] == 'COMPLETED')
          .map((e) => e['scheduled_date'] as String),
    }.toList()..sort();
    if (keys.isEmpty) return [];
    final start = DateTime.parse(keys.first), end = DateTime.now();
    return [
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1)))
        d,
    ];
  }

  ({int planned, int done, double score}) score(DateTime d) {
    final k = controller.key(d);
    final rr = controller.routineRecords
        .where((e) => e['date'] == k && e['skipped'] == 0)
        .toList();
    final ts = controller.tasks
        .where(
          (e) =>
              e['scheduled_date'] == k &&
              ![
                'SKIPPED',
                'DROPPED',
                'DELEGATED',
                'ARCHIVED',
              ].contains(e['status']),
        )
        .toList();
    final planned = rr.length + ts.length;
    final done =
        rr.where((e) => e['completed'] == 1).length +
        ts.where((e) => e['status'] == 'COMPLETED').length;
    return (
      planned: planned,
      done: done,
      score: planned == 0 ? 0 : done / planned * 100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = dates.where((d) => score(d).planned > 0).toList();
    final average = active.isEmpty
        ? 0
        : active.map((d) => score(d).score).reduce((a, b) => a + b) /
              active.length;
    final streaks = _streaks(active);
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: pagePadding,
        children: [
          const PageIntro(
            eyebrow: 'TRACKER ANALYTICS · SAVED HISTORY ONLY',
            title: 'Consistency, clearly seen.',
            subtitle:
                'No fabricated points. Sparse history stays honestly sparse.',
          ),
          const SizedBox(height: 20),
          MetricGrid(
            spacing: 9,
            children: [
              MetricCard(
                label: 'Average completion',
                value: '${average.round()}%',
                caption: 'across ${active.length} active days',
                color: TrackerColors.gold,
              ),
              MetricCard(
                label: 'Current streak',
                value: '${streaks.$1}',
                caption: 'fully completed days',
              ),
              MetricCard(
                label: 'Best streak',
                value: '${streaks.$2}',
                caption: 'longest complete run',
              ),
              MetricCard(
                label: 'Focus',
                value:
                    '${controller.focusSessions.where((e) => e['status'] == 'COMPLETED').fold(0, (s, e) => s + (e['duration_minutes'] as int? ?? 0))}m',
                caption: 'protected attention',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (active.isEmpty)
            const EmptyCard(
              eyebrow: 'No saved history',
              title: 'Your first completion starts the graph.',
              body:
                  'TRACKER will never decorate an empty chart with fake progress.',
              icon: Icons.show_chart,
            )
          else ...[
            _completionChart(context, active),
            const SizedBox(height: 14),
            _categoryChart(context),
            const SizedBox(height: 14),
            _heatmap(context),
            const SizedBox(height: 14),
            _variance(context, active),
            const SizedBox(height: 14),
            _routineTable(context),
            const SizedBox(height: 14),
            _focusCalibration(context),
          ],
        ],
      ),
    );
  }

  (int, int) _streaks(List<DateTime> active) {
    if (active.isEmpty) return (0, 0);
    var current = 0, best = 0, run = 0;
    for (final d in active) {
      if (score(d).score == 100) {
        run++;
        best = max(best, run);
      } else {
        run = 0;
      }
    }
    final today = DateTime.now();
    var cursor = today;
    while (true) {
      final s = score(cursor);
      if (s.planned == 0) {
        if (controller.key(cursor) == controller.todayKey) {
          cursor = cursor.subtract(const Duration(days: 1));
          continue;
        }
        break;
      }
      if (s.score == 100) {
        current++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return (current, best);
  }

  Widget _completionChart(
    BuildContext context,
    List<DateTime> active,
  ) => SectionCard(
    eyebrow: 'Completion arc',
    title: 'Day-by-day since your first saved record',
    child: Column(
      children: [
        SizedBox(
          height: 240,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context).dividerColor,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 34,
                    interval: 25,
                    getTitlesWidget: (v, _) => Text(
                      '${v.round()}%',
                      style: const TextStyle(fontSize: 9),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: max(1, (active.length / 4).ceil()).toDouble(),
                    getTitlesWidget: (v, _) => v.toInt() < active.length
                        ? Text(
                            DateFormat('d/M').format(active[v.toInt()]),
                            style: const TextStyle(fontSize: 9),
                          )
                        : const SizedBox(),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: [
                    for (var i = 0; i < active.length; i++)
                      FlSpot(i.toDouble(), score(active[i]).score),
                  ],
                  isCurved: true,
                  barWidth: 3.5,
                  color: TrackerColors.gold,
                  dotData: FlDotData(show: active.length < 18),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        TrackerColors.gold.withValues(alpha: .28),
                        TrackerColors.gold.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Missing days are not converted into zero. Only days with planned work enter the line.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
  Widget _categoryChart(BuildContext context) {
    const categories = [
      'STUDY',
      'HYGIENE',
      'WORKOUT',
      'HEALTH',
      'PERSONAL',
      'OTHER',
    ];
    final values = <double>[];
    for (final cat in categories) {
      final ids = controller.routines
          .where((r) => r['category'] == cat)
          .map((r) => r['id'])
          .toSet();
      final rec = controller.routineRecords
          .where((r) => ids.contains(r['routine_id']) && r['skipped'] == 0)
          .toList();
      values.add(
        rec.isEmpty
            ? 0
            : rec.where((r) => r['completed'] == 1).length / rec.length * 100,
      );
    }
    return SectionCard(
      eyebrow: 'Category comparison',
      title: 'Habit areas over time',
      child: Column(
        children: [
          SizedBox(
            height: 245,
            child: BarChart(
              BarChartData(
                maxY: 100,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Theme.of(context).dividerColor),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Transform.rotate(
                        angle: -.55,
                        child: Text(
                          categories[v.toInt()].substring(
                            0,
                            min(4, categories[v.toInt()].length),
                          ),
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < categories.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          gradient: const LinearGradient(
                            colors: [
                              TrackerColors.gold,
                              TrackerColors.brightGold,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            values.every((v) => v == 0)
                ? 'Categories will become comparable after routine records exist.'
                : 'Gold records completion; empty categories remain zero because no evidence exists.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _heatmap(BuildContext context) {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 83));
    return SectionCard(
      eyebrow: '84-day heatmap',
      title: 'The texture of consistency',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < 84; i++)
            Builder(
              builder: (context) {
                final d = start.add(Duration(days: i));
                final s = score(d);
                final alpha = s.planned == 0 ? 0.06 : .18 + .72 * s.score / 100;
                return Tooltip(
                  message:
                      '${DateFormat('d MMM').format(d)} · ${s.planned == 0 ? 'No planned work' : '${s.score.round()}%'}',
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: TrackerColors.gold.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _variance(BuildContext context, List<DateTime> active) {
    final recent = active.length > 42
        ? active.sublist(active.length - 42)
        : active;
    final avg =
        recent.map((d) => score(d).score).reduce((a, b) => a + b) /
        recent.length;
    return SectionCard(
      eyebrow: 'Variance from your average',
      title: 'Which days rose or fell?',
      child: SizedBox(
        height: 205,
        child: BarChart(
          BarChartData(
            minY: -100,
            maxY: 100,
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (v) => FlLine(
                color: v == 0
                    ? TrackerColors.gold
                    : Theme.of(context).dividerColor,
                strokeWidth: v == 0 ? 2 : 1,
              ),
            ),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < recent.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: score(recent[i]).score - avg,
                      fromY: 0,
                      width: max(3, 140 / recent.length),
                      color: score(recent[i]).score >= avg
                          ? TrackerColors.gold
                          : TrackerColors.muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routineTable(BuildContext context) => SectionCard(
    eyebrow: 'Routine performance',
    title: 'Promises with evidence',
    child: controller.routines.isEmpty
        ? const Text('No routine history yet.')
        : Column(
            children: [
              for (final routine in controller.routines.take(12))
                Builder(
                  builder: (context) {
                    final records = controller.routineRecords
                        .where(
                          (entry) =>
                              entry['routine_id'] == routine['id'] &&
                              entry['skipped'] == 0,
                        )
                        .toList();
                    final percent = records.isEmpty
                        ? 0
                        : (records
                                      .where((entry) => entry['completed'] == 1)
                                      .length /
                                  records.length *
                                  100)
                              .round();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(routine['title'] as String),
                      subtitle: Text(
                        '${routine['category']} · ${records.length} active records',
                      ),
                      trailing: Text(
                        '$percent%',
                        style: const TextStyle(
                          color: TrackerColors.gold,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
  );
  Widget _focusCalibration(BuildContext context) {
    final linked = controller.focusSessions
        .where((e) => e['status'] == 'COMPLETED' && e['task_id'] != null)
        .toList();
    return SectionCard(
      eyebrow: 'Estimate calibration',
      title: 'Planned versus actual focus',
      child: linked.isEmpty
          ? const Text(
              'Complete task-linked focus sessions to learn how your estimates compare with reality.',
            )
          : Column(
              children: [
                for (final s in linked.take(10))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s['title'] as String),
                    subtitle: LinearProgressIndicator(
                      value:
                          ((s['duration_minutes'] as int? ?? 0) /
                                  (s['planned_minutes'] as int))
                              .clamp(0, 1),
                      color: TrackerColors.gold,
                    ),
                    trailing: Text(
                      '${s['duration_minutes']} / ${s['planned_minutes']}m',
                    ),
                  ),
              ],
            ),
    );
  }
}
