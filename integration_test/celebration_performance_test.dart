import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tracker/core/theme.dart';
import 'package:tracker/data/tracker_database.dart';
import 'package:tracker/services/notification_service.dart';
import 'package:tracker/state/tracker_controller.dart';
import 'package:tracker/ui/screens/today_screen.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full-day celebration frame performance', (tester) async {
    final controller = _CelebrationController();
    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.dark,
        home: Scaffold(body: TodayScreen(controller: controller)),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await binding.watchPerformance(() async {
      await tester.tap(find.byTooltip('Increase routine progress'));
      await tester.pump();
      for (var frame = 0; frame < 360; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }, reportKey: 'full_day_celebration');

    expect(find.text('Deep work'), findsWidgets);
    expect(controller.dailyScore, 100);
  });
}

class _CelebrationController extends TrackerController {
  _CelebrationController() : super(TrackerDatabase(), NotificationService()) {
    routines = [
      {
        'id': 1,
        'title': 'Deep work',
        'description': '',
        'type': 'QUANTITY',
        'target_quantity': 1,
        'unit': 'session',
        'category': 'STUDY',
        'frequency': 'DAILY',
        'scheduled_days': '',
        'weekly_target': 7,
        'estimated_minutes': 25,
        'preferred_time': null,
        'minimum_target': 1,
        'stretch_target': 1,
        'paused_until': null,
        'start_date': todayKey,
        'end_date': null,
        'status': 'ACTIVE',
      },
    ];
    routineRecords = [
      {
        'id': 1,
        'routine_id': 1,
        'date': todayKey,
        'target_snapshot': 1,
        'completed_quantity': 0,
        'completed': 0,
        'skipped': 0,
        'skip_reason': '',
      },
    ];
  }

  @override
  Future<void> progressRoutine(int recordId, int delta) async {
    final record = routineRecords.single;
    final next = ((record['completed_quantity'] as int) + delta).clamp(0, 1);
    routineRecords = [
      {
        ...record,
        'completed_quantity': next,
        'completed': next == 1 ? 1 : 0,
        'skipped': 0,
      },
    ];
    notifyListeners();
  }
}
