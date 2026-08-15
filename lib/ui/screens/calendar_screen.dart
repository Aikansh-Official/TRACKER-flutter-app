import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';
import '../widgets/quick_capture.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime selected = DateTime.now();
  bool week = false;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: widget.controller.refresh,
    child: ListView(
      padding: pagePadding,
      children: [
        PageIntro(
          eyebrow: 'CALENDAR',
          title: 'Time, given a shape.',
          subtitle:
              'Deadlines, events, routines, and open space—without invented data.',
          trailing: IconButton.filled(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => QuickCapture(controller: widget.controller),
            ),
            icon: const Icon(Icons.add),
          ),
        ),
        const SizedBox(height: 18),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.calendar_view_month),
              label: Text('Month'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.view_week_outlined),
              label: Text('Week'),
            ),
          ],
          selected: {week},
          onSelectionChanged: (v) => setState(() => week = v.first),
        ),
        const SizedBox(height: 14),
        if (week) _weekBoard(context) else _month(context),
        const SizedBox(height: 14),
        _agenda(context),
      ],
    ),
  );
  Widget _month(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final offset = first.weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return SectionCard(
      eyebrow: 'Month view',
      title: DateFormat('MMMM yyyy').format(month),
      action: Row(
        children: [
          IconButton(
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () =>
                setState(() => month = DateTime(month.year, month.month + 1)),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final d in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: offset + days,
            itemBuilder: (context, i) {
              if (i < offset) return const SizedBox();
              final day = i - offset + 1;
              final date = DateTime(month.year, month.month, day);
              final key = widget.controller.key(date);
              final count = widget.controller.tasks
                  .where(
                    (e) =>
                        e['scheduled_date'] == key &&
                        !['ARCHIVED', 'DROPPED'].contains(e['status']),
                  )
                  .length;
              final isSelected = DateUtils.isSameDay(date, selected),
                  isToday = DateUtils.isSameDay(date, DateTime.now());
              return Semantics(
                label:
                    '${DateFormat('EEEE d MMMM').format(date)}, $count items',
                selected: isSelected,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => selected = date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? TrackerColors.gold
                          : isToday
                          ? TrackerColors.softGold.withValues(alpha: .7)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? TrackerColors.gold
                            : Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '$day',
                            style: TextStyle(
                              color: isSelected ? Colors.white : null,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.w800
                                  : null,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            bottom: 5,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var j = 0; j < count.clamp(0, 3); j++)
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? Colors.white
                                          : TrackerColors.violet,
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
            },
          ),
        ],
      ),
    );
  }

  Widget _weekBoard(BuildContext context) {
    final monday = selected.subtract(Duration(days: selected.weekday - 1));
    return SectionCard(
      eyebrow: 'Week planner',
      title:
          '${DateFormat('d MMM').format(monday)} — ${DateFormat('d MMM').format(monday.add(const Duration(days: 6)))}',
      action: Row(
        children: [
          IconButton(
            onPressed: () => setState(
              () => selected = selected.subtract(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: () => setState(
              () => selected = selected.add(const Duration(days: 7)),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      child: SizedBox(
        height: 430,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 7,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final date = monday.add(Duration(days: i));
            final dateKey = widget.controller.key(date);
            final items = widget.controller.tasks
                .where(
                  (e) =>
                      e['scheduled_date'] == dateKey &&
                      !['ARCHIVED', 'DROPPED'].contains(e['status']),
                )
                .toList();
            return DragTarget<Map<String, Object?>>(
              onAcceptWithDetails: (detail) =>
                  widget.controller.updateTask(detail.data['id'] as int, {
                    'scheduled_date': dateKey,
                    'status': dateKey == widget.controller.todayKey
                        ? 'TODAY'
                        : 'SCHEDULED',
                  }),
              builder: (context, candidate, rejected) => Container(
                width: 148,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: candidate.isNotEmpty
                      ? TrackerColors.softGold
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      DateFormat('EEE').format(date).toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TrackerColors.gold,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM').format(date),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Divider(),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          'Open space.',
                          style: TextStyle(color: TrackerColors.muted),
                        ),
                      )
                    else
                      for (final item in items) _draggableItem(item),
                    const Spacer(),
                    Text(
                      '${widget.controller.routines.where((r) => r['status'] == 'ACTIVE').length} routines in library',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _draggableItem(Map<String, Object?> item) =>
      Draggable<Map<String, Object?>>(
        data: item,
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            width: 135,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TrackerColors.gold,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item['title'] as String,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        childWhenDragging: const SizedBox(height: 52),
        child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: item['status'] == 'COMPLETED'
                ? TrackerColors.mint.withValues(alpha: .18)
                : TrackerColors.lavender.withValues(alpha: .65),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['title'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TrackerColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                item['all_day'] == 1
                    ? 'All day'
                    : '${item['start_time'] ?? item['deadline'] ?? ''}',
                style: const TextStyle(
                  color: TrackerColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      );
  Widget _agenda(BuildContext context) {
    final key = widget.controller.key(selected);
    final items = widget.controller.tasks
        .where(
          (e) =>
              e['scheduled_date'] == key &&
              !['ARCHIVED', 'DROPPED'].contains(e['status']),
        )
        .toList();
    return SectionCard(
      eyebrow: 'Selected day',
      title: DateFormat('EEEE, d MMMM').format(selected),
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Nothing scheduled. Leave the day open, or give it one clear intention.',
              ),
            )
          : Column(
              children: [
                for (final item in items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      item['item_type'] == 'EVENT'
                          ? Icons.event_outlined
                          : Icons.check_circle_outline,
                      color: TrackerColors.gold,
                    ),
                    title: Text(item['title'] as String),
                    subtitle: Text(
                      '${item['all_day'] == 1 ? 'All day' : item['start_time'] ?? item['deadline']} · ${item['status']}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _editItem(context, item);
                        if (v == 'done') {
                          widget.controller.completeTask(item['id'] as int);
                        }
                        if (v == 'archive') {
                          widget.controller.archiveTask(item['id'] as int);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'done',
                          child: Text('Toggle complete'),
                        ),
                        PopupMenuItem(value: 'archive', child: Text('Archive')),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  void _editItem(BuildContext context, Map<String, Object?> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          QuickCapture(controller: widget.controller, existingTask: item),
    );
  }
}
