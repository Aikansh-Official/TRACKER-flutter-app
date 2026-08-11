import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';

class QuickCapture extends StatefulWidget {
  const QuickCapture({super.key, required this.controller});
  final TrackerController controller;
  @override
  State<QuickCapture> createState() => _QuickCaptureState();
}

class _QuickCaptureState extends State<QuickCapture> {
  final title = TextEditingController();
  final checklist = TextEditingController();
  final estimate = TextEditingController(text: '30');
  DateTime date = DateTime.now();
  String type = 'TASK', repeat = 'NONE';
  int interval = 1;
  final weekdays = <int>{};
  DateTime? repeatUntil;
  bool allDay = true;
  TimeOfDay? start, deadline;
  int? reminder;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
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
    await widget.controller.createTask({
      'title': title.text.trim(),
      'description': '',
      'item_type': type,
      'scheduled_date': widget.controller.key(date),
      'all_day': allDay ? 1 : 0,
      'start_time': type == 'EVENT' ? formatTime(start) : null,
      'deadline': formatTime(deadline).isEmpty ? null : formatTime(deadline),
      'priority': 'MEDIUM',
      'estimated_minutes': int.tryParse(estimate.text)?.clamp(5, 480) ?? 30,
      'reminder_minutes': reminder,
      'recurrence_frequency': repeat,
      'recurrence_interval': interval,
      'recurrence_weekdays': weekdays.join(','),
      'recurrence_end_date': repeatUntil == null
          ? null
          : widget.controller.key(repeatUntil!),
    }, checklist.text.split('\n'));
    if (mounted) Navigator.pop(context);
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
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
                      'QUICK CAPTURE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: TrackerColors.gold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Get it out of your head.',
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
          DropdownButtonFormField<String>(
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
          if (repeat != 'NONE') ...[
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
                    ? 'One-year default horizon'
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
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            label: Text(saving ? 'Saving offline…' : 'Save to TRACKER'),
          ),
        ],
      ),
    ),
  );
}
