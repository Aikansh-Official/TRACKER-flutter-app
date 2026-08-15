import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/theme.dart';
import 'package:tracker/data/tracker_database.dart';
import 'package:tracker/services/notification_service.dart';
import 'package:tracker/state/tracker_controller.dart';
import 'package:tracker/ui/app_shell.dart';
import 'package:tracker/ui/auth_screen.dart';
import 'package:tracker/ui/screens/insights_screen.dart';
import 'package:tracker/ui/screens/plan_screen.dart';
import 'package:tracker/ui/widgets/motion.dart';
import 'package:tracker/ui/widgets/quick_capture.dart';

void main() {
  testWidgets('TRACKER light and dark themes keep input text visible', (
    tester,
  ) async {
    for (final theme in [TrackerTheme.light, TrackerTheme.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: TextField(
              decoration: InputDecoration(labelText: 'Task title'),
            ),
          ),
        ),
      );
      expect(find.text('Task title'), findsOneWidget);
      expect(theme.inputDecorationTheme.filled, isTrue);
      expect(
        theme.colorScheme.onSurface.computeLuminance() ==
            theme.colorScheme.surface.computeLuminance(),
        isFalse,
      );
    }
  });

  test('TRACKER palette keeps gold distinct from paper and graphite', () {
    expect(TrackerColors.gold, isNot(TrackerColors.paper));
    expect(TrackerColors.brightGold, isNot(TrackerColors.graphite));
  });

  testWidgets('celebrations become calm and readable with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.dark,
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: CelebrationOverlay(title: 'Finish report', wholeDay: false),
        ),
      ),
    );

    expect(find.text('Finish report'), findsOneWidget);
    expect(find.text('✓ COMPLETE'), findsOneWidget);
    expect(find.byKey(const ValueKey('celebration-particles')), findsNothing);
  });

  testWidgets('spring action remains usable when animation is disabled', (
    tester,
  ) async {
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SpringIconButton(
              tooltip: 'Complete task',
              icon: const Icon(Icons.check),
              onPressed: () => activations++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Complete task'));
    expect(activations, 1);
  });

  testWidgets('every destination reflows at narrow width with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TrackerController(
      TrackerDatabase(),
      NotificationService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: AppShell(controller: controller),
        ),
      ),
    );
    const headings = [
      'Your day, without the noise.',
      'Plan with your real capacity.',
      'Make today count.',
      'Promises worth repeating.',
      'Notice the weather within.',
      'Time, given a shape.',
      'Consistency, clearly seen.',
    ];
    for (var page = 0; page < headings.length; page++) {
      controller.navigate(page);
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'destination $page');
      expect(find.text(headings[page]), findsOneWidget);
    }
  });

  testWidgets('real insight data renders charts at narrow large-text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TrackerController(
      TrackerDatabase(),
      NotificationService(),
    );
    controller.routines = [
      {'id': 1, 'title': 'Read', 'category': 'STUDY', 'target_quantity': 1},
    ];
    controller.routineRecords = [
      {
        'id': 1,
        'routine_id': 1,
        'date': controller.todayKey,
        'completed': 1,
        'skipped': 0,
      },
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: Scaffold(body: InsightsScreen(controller: controller)),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Day-by-day since your first saved record'),
      360,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text('Day-by-day since your first saved record'),
      findsOneWidget,
    );
  });

  testWidgets('reminder center remains scrollable with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TrackerController(
      TrackerDatabase(),
      NotificationService(),
    );
    final reminderTime = DateTime.now().add(const Duration(hours: 2));
    controller.tasks = [
      {
        'id': 1,
        'title': 'Placement briefing',
        'description': '',
        'item_type': 'EVENT',
        'scheduled_date': controller.key(reminderTime),
        'all_day': 0,
        'start_time':
            '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}',
        'priority': 'HIGH',
        'deadline': null,
        'estimated_minutes': 45,
        'reminder_minutes': 10,
        'status': 'SCHEDULED',
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: AppShell(controller: controller),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Reminder center'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Placement briefing'), findsOneWidget);
    expect(find.text('Smart day reminders'), findsOneWidget);
  });

  testWidgets('quick capture stays usable above a large keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TrackerController(
      TrackerDatabase(),
      NotificationService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.dark,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            viewInsets: EdgeInsets.only(bottom: 300),
            textScaler: TextScaler.linear(1.4),
            disableAnimations: true,
          ),
          child: Scaffold(body: QuickCapture(controller: controller)),
        ),
      ),
    );
    final verticalScroll = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('Save to TRACKER'),
      420,
      scrollable: verticalScroll,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Save to TRACKER'), findsOneWidget);
  });

  testWidgets('every planning studio tab supports narrow large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TrackerController(
      TrackerDatabase(),
      NotificationService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: TrackerTheme.light,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
            disableAnimations: true,
          ),
          child: Scaffold(body: PlanScreen(controller: controller)),
        ),
      ),
    );
    const tabs = {
      'Focus': 'Protect one honest block.',
      'Goals': 'Direction, broken into proof.',
      'Weekly review': 'Review without self-deception.',
    };
    for (final entry in tabs.entries) {
      await tester.ensureVisible(find.text(entry.key));
      await tester.tap(find.text(entry.key));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull, reason: entry.key);
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('onboarding, lock, failed login, and unlock work offline', (
    tester,
  ) async {
    final controller = _AuthFlowController();

    Widget harness() => MaterialApp(
      theme: TrackerTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 800),
          textScaler: TextScaler.linear(1.4),
          disableAnimations: true,
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) => controller.unlocked
              ? const Scaffold(body: Text('Unlocked workspace'))
              : AuthScreen(
                  controller: controller,
                  hasProfile: controller.profile != null,
                ),
        ),
      ),
    );

    await tester.pumpWidget(harness());
    await tester.enterText(find.byType(TextField).at(0), 'Aikansh');
    await tester.enterText(find.byType(TextField).at(1), 'aikansh@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'strong-pass');
    await tester.ensureVisible(find.text('Create my profile →'));
    await tester.tap(find.text('Create my profile →'));
    await tester.pump();
    expect(find.text('Unlocked workspace'), findsOneWidget);

    await controller.lock();
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('One private local profile lives on this device.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(0), 'aikansh@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong-pass');
    await tester.ensureVisible(find.text('Unlock TRACKER →'));
    await tester.tap(find.text('Unlock TRACKER →'));
    await tester.pump();
    expect(find.text('Incorrect email or password.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), 'strong-pass');
    await tester.tap(find.text('Unlock TRACKER →'));
    await tester.pump();
    expect(find.text('Unlocked workspace'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });
}

class _AuthFlowController extends TrackerController {
  _AuthFlowController() : super(TrackerDatabase(), NotificationService()) {
    ready = true;
  }

  @override
  Future<String?> createProfile(
    String name,
    String email,
    String password,
  ) async {
    profile = {'name': name, 'email': email};
    unlocked = true;
    notifyListeners();
    return null;
  }

  @override
  Future<String?> login(String email, String password) async {
    if (email != profile?['email'] || password != 'strong-pass') {
      return 'Incorrect email or password.';
    }
    unlocked = true;
    notifyListeners();
    return null;
  }

  @override
  Future<void> lock() async {
    unlocked = false;
    notifyListeners();
  }
}
