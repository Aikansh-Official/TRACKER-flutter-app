import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../state/tracker_controller.dart';
import '../widgets/common.dart';

class RoutinesScreen extends StatelessWidget {
  const RoutinesScreen({super.key, required this.controller});
  final TrackerController controller;

  @override
  Widget build(BuildContext context) {
    final active = controller.routines
        .where((entry) => entry['status'] != 'ARCHIVED')
        .toList();
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: pagePadding,
        children: [
          PageIntro(
            eyebrow: 'ROUTINE LIBRARY',
            title: 'Promises worth repeating.',
            subtitle: 'Build a rhythm that bends with real life.',
            trailing: IconButton.filled(
              onPressed: () => _compose(context),
              icon: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 22),
          if (active.isEmpty)
            const EmptyCard(
              eyebrow: 'No routines yet',
              title: 'Start with one promise to yourself.',
              body:
                  'Add something small enough to repeat, then let evidence grow.',
              icon: Icons.track_changes,
            )
          else
            for (final routine in active) _routineCard(context, routine),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: () => _showArchived(context),
            icon: const Icon(Icons.archive_outlined),
            label: Text(
              'Archived routines (${controller.routines.where((entry) => entry['status'] == 'ARCHIVED').length})',
            ),
          ),
        ],
      ),
    );
  }

  Widget _routineCard(
    BuildContext context,
    Map<String, Object?> routine,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
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
              child: const Icon(Icons.track_changes, color: TrackerColors.gold),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routine['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${routine['category']} · ${routine['frequency']} · ${routine['target_quantity']} ${routine['unit']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if ((routine['description'] as String).isNotEmpty)
                    Text(
                      routine['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'archive') {
                  controller.archiveRoutine(routine['id'] as int);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'archive', child: Text('Archive')),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  void _compose(BuildContext context) {
    final title = TextEditingController();
    final description = TextEditingController();
    final target = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'times');
    var type = 'BINARY';
    var category = 'STUDY';
    var frequency = 'DAILY';
    final days = <int>{};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                  'NEW ROUTINE',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
                ),
                const SizedBox(height: 7),
                Text(
                  'A promise you can repeat.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Routine title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(
                    labelText: 'Why it matters',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'BINARY',
                      child: Text('Binary — done or not'),
                    ),
                    DropdownMenuItem(
                      value: 'QUANTIFIABLE',
                      child: Text('Quantifiable'),
                    ),
                    DropdownMenuItem(
                      value: 'TEMPORARY',
                      child: Text('Temporary'),
                    ),
                  ],
                  onChanged: (value) => setSheetState(() => type = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: target,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Target'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Life area'),
                  items: [
                    for (final value in const [
                      'STUDY',
                      'HYGIENE',
                      'WORKOUT',
                      'HEALTH',
                      'PERSONAL',
                      'OTHER',
                    ])
                      DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => setSheetState(() => category = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: [
                    for (final value in const [
                      'DAILY',
                      'WEEKDAYS',
                      'WEEKENDS',
                      'CUSTOM',
                      'WEEKLY_TARGET',
                    ])
                      DropdownMenuItem(
                        value: value,
                        child: Text(value.replaceAll('_', ' ')),
                      ),
                  ],
                  onChanged: (value) => setSheetState(() => frequency = value!),
                ),
                if (frequency == 'CUSTOM')
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final day in const [
                          (0, 'S'),
                          (1, 'M'),
                          (2, 'T'),
                          (3, 'W'),
                          (4, 'T'),
                          (5, 'F'),
                          (6, 'S'),
                        ])
                          ChoiceChip(
                            label: Text(day.$2),
                            selected: days.contains(day.$1),
                            onSelected: (selected) => setSheetState(
                              () => selected
                                  ? days.add(day.$1)
                                  : days.remove(day.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (title.text.trim().isEmpty) return;
                    await controller.createRoutine({
                      'title': title.text.trim(),
                      'description': description.text.trim(),
                      'type': type,
                      'target_quantity': int.tryParse(target.text) ?? 1,
                      'unit': unit.text.trim(),
                      'category': category,
                      'frequency': frequency,
                      'scheduled_days': days.join(','),
                      'weekly_target': 3,
                      'estimated_minutes': 25,
                      'minimum_target': 1,
                      'stretch_target': int.tryParse(target.text) ?? 1,
                      'start_date': controller.todayKey,
                      'status': 'ACTIVE',
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Create routine'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      title.dispose();
      description.dispose();
      target.dispose();
      unit.dispose();
    });
  }

  void _showArchived(BuildContext context) {
    final archived = controller.routines
        .where((entry) => entry['status'] == 'ARCHIVED')
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ARCHIVED ROUTINES',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: TrackerColors.gold),
              ),
              const SizedBox(height: 14),
              if (archived.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Your routine archive is empty.'),
                )
              else
                for (final routine in archived)
                  ListTile(
                    title: Text(routine['title'] as String),
                    trailing: TextButton(
                      onPressed: () {
                        controller.archiveRoutine(
                          routine['id'] as int,
                          restore: true,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Restore'),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
