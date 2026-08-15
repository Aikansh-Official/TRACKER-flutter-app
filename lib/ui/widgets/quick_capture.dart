import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';

class QuickCapture extends StatefulWidget {
  const QuickCapture({super.key, required this.controller, this.existingTask});
  final TrackerController controller;
  final Map<String, Object?>? existingTask;
  @override
  State<QuickCapture> createState() => _QuickCaptureState();
}

class _QuickCaptureState extends State<QuickCapture> {
  final title = TextEditingController();
  final description = TextEditingController();
  final checklist = TextEditingController();
  final estimate = TextEditingController(text: '30');
  DateTime date = DateTime.now();
  String type = 'TASK', repeat = 'NONE', priority = 'MEDIUM';
  int interval = 1;
  final weekdays = <int>{};
  DateTime? repeatUntil;
  bool allDay = true;
  TimeOfDay? start, deadline;
  int? reminder;
  bool saving = false;
  String? error;

  bool get editing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    final item = widget.existingTask;
    if (item == null) return;
    title.text = item['title'] as String;
    description.text = item['description'] as String? ?? '';
    checklist.text = widget.controller
        .subtasksFor(item['id'] as int)
        .map((entry) => entry['title'] as String)
        .join('\n');
    estimate.text = '${item['estimated_minutes'] ?? 30}';
    date = DateTime.parse(item['scheduled_date'] as String);
    type = item['item_type'] as String? ?? 'TASK';
    repeat = item['recurrence_frequency'] as String? ?? 'NONE';
    interval = item['recurrence_interval'] as int? ?? 1;
    weekdays.addAll(
      (item['recurrence_weekdays'] as String? ?? '')
          .split(',')
          .where((value) => value.isNotEmpty)
          .map(int.parse),
    );
    final end = item['recurrence_end_date'] as String?;
    repeatUntil = end == null || end.isEmpty ? null : DateTime.parse(end);
    allDay = item['all_day'] == 1;
    start = _parseTime(item['start_time']);
    deadline = _parseTime(item['deadline']);
    reminder = item['reminder_minutes'] as int?;
    priority = item['priority'] as String? ?? 'MEDIUM';
  }

  TimeOfDay? _parseTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final pieces = value.split(':');
    if (pieces.length != 2) return null;
    final hour = int.tryParse(pieces[0]), minute = int.tryParse(pieces[1]);
    return hour == null || minute == null
        ? null
        : TimeOfDay(hour: hour, minute: minute);
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    checklist.dispose();
    estimate.dispose();
    super.dispose();
  }

  String formatTime(TimeOfDay? time) => time == null
      ? ''
      : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> save() async {
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Give this task or event a title.');
      return;
    }
    if (!allDay && start == null && type == 'EVENT') {
      setState(() => error = 'Choose when the event starts.');
      return;
    }
    if (!allDay && deadline == null && type == 'TASK') {
      setState(() => error = 'Choose a deadline.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    final values = <String, Object?>{
      'title': title.text.trim(),
      'description': description.text.trim(),
      'item_type': type,
      'scheduled_date': widget.controller.key(date),
      'all_day': allDay ? 1 : 0,
      'start_time': type == 'EVENT' ? formatTime(start) : null,
      'deadline': formatTime(deadline).isEmpty ? null : formatTime(deadline),
      'priority': priority,
      'estimated_minutes': int.tryParse(estimate.text)?.clamp(5, 480) ?? 30,
      'reminder_minutes': reminder,
      'recurrence_frequency': repeat,
      'recurrence_interval': interval,
      'recurrence_weekdays': weekdays.join(','),
      'recurrence_end_date': repeatUntil == null
          ? null
          : widget.controller.key(repeatUntil!),
    };
    final reminderScheduled = editing
        ? await widget.controller.editTask(
            widget.existingTask!['id'] as int,
            values,
            checklist.text.split('\n'),
          )
        : await widget.controller.createTask(
            values,
            checklist.text.split('\n'),
          );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    if (reminder != null && !reminderScheduled) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Saved offline. Allow notifications to receive its reminder.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: .94,
    minChildSize: .6,
    maxChildSize: .98,
    builder: (context, scroll) => Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      child: ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 36,
        ),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      editing ? 'EDIT ${type.toUpperCase()}' : 'QUICK CAPTURE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TrackerColors.gold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      editing ? 'Refine the plan.' : 'Get it out of your head.',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'TASK',
                icon: Icon(Icons.check_circle_outline),
                label: Text('Task'),
              ),
              ButtonSegment(
                value: 'EVENT',
                icon: Icon(Icons.event_outlined),
                label: Text('Event'),
              ),
            ],
            selected: {type},
            onSelectionChanged: (v) => setState(() => type = v.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: title,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'What needs your attention?',
              hintText: 'e.g. Submit operating systems assignment',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: description,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              hintText: 'Context your future self will need',
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat('EEEE, d MMMM').format(date)),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: date,
              );
              if (picked != null) setState(() => date = picked);
            },
          ),
          if (!editing)
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: repeat,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: const [
                DropdownMenuItem(value: 'NONE', child: Text('Does not repeat')),
                DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
              ],
              onChanged: (v) => setState(() => repeat = v!),
            ),
          if (!editing && repeat != 'NONE') ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Every $interval ${repeat.toLowerCase()} interval${interval == 1 ? '' : 's'}',
                  ),
                ),
                IconButton(
                  onPressed: interval > 1
                      ? () => setState(() => interval--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: interval < 30
                      ? () => setState(() => interval++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (repeat == 'WEEKLY')
              Wrap(
                spacing: 6,
                children: [
                  for (final d in const [
                    (0, 'S'),
                    (1, 'M'),
                    (2, 'T'),
                    (3, 'W'),
                    (4, 'T'),
                    (5, 'F'),
                    (6, 'S'),
                  ])
                    ChoiceChip(
                      label: Text(d.$2),
                      selected: weekdays.contains(d.$1),
                      onSelected: (on) => setState(
                        () => on ? weekdays.add(d.$1) : weekdays.remove(d.$1),
                      ),
                    ),
                ],
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Repeat until'),
              subtitle: Text(
                repeatUntil == null
                    ? 'Up to one year · maximum 120 occurrences'
                    : DateFormat('d MMM y').format(repeatUntil!),
              ),
              trailing: const Icon(Icons.event_repeat),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: date,
                  lastDate: DateTime(2100),
                  initialDate:
                      repeatUntil ?? date.add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => repeatUntil = picked);
              },
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('All day'),
            subtitle: const Text('Turn off to choose a clock time'),
            value: allDay,
            onChanged: (v) => setState(() => allDay = v),
          ),
          if (!allDay)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showTimePicker(
                        context: context,
                        initialTime: start ?? TimeOfDay.now(),
                      );
                      if (value != null) setState(() => start = value);
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      type == 'EVENT'
                          ? (start == null ? 'Starts' : start!.format(context))
                          : 'Optional start',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final value = await showTimePicker(
                        context: context,
                        initialTime: deadline ?? TimeOfDay.now(),
                      );
                      if (value != null) setState(() => deadline = value);
                    },
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(
                      deadline == null
                          ? (type == 'EVENT' ? 'Ends' : 'Deadline')
                          : deadline!.format(context),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: reminder,
            decoration: const InputDecoration(labelText: 'Reminder'),
            items: const [
              DropdownMenuItem(value: null, child: Text('No reminder')),
              DropdownMenuItem(value: 0, child: Text('At start / deadline')),
              DropdownMenuItem(value: 10, child: Text('10 minutes before')),
              DropdownMenuItem(value: 30, child: Text('30 minutes before')),
              DropdownMenuItem(value: 60, child: Text('1 hour before')),
              DropdownMenuItem(value: 1440, child: Text('1 day before')),
            ],
            onChanged: (v) => setState(() => reminder = v),
          ),
          if (type == 'TASK') ...[
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'LOW', child: Text('Low priority')),
                DropdownMenuItem(
                  value: 'MEDIUM',
                  child: Text('Medium priority'),
                ),
                DropdownMenuItem(value: 'HIGH', child: Text('High priority')),
                DropdownMenuItem(
                  value: 'CRITICAL',
                  child: Text('Critical priority'),
                ),
              ],
              onChanged: (value) => setState(() => priority = value!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: estimate,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimate (minutes)',
                helperText: 'Between 5 and 480 minutes',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: checklist,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Checklist',
                hintText: 'One step per line',
                helperText: 'Up to 30 subtasks',
              ),
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: saving ? null : save,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(17)),
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              saving
                  ? 'Saving offline…'
                  : editing
                  ? 'Save changes'
                  : 'Save to TRACKER',
            ),
          ),
        ],
      ),
    ),
  );
}
