import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/theme.dart';
import 'package:tracker/data/tracker_database.dart';
import 'package:tracker/services/notification_service.dart';
import 'package:tracker/state/tracker_controller.dart';
import 'package:tracker/ui/app_shell.dart';
import 'package:tracker/ui/widgets/motion.dart';

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

  testWidgets('app shell reflows at narrow width with large text', (
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
    expect(tester.takeException(), isNull);
    expect(find.text('Your day, without the noise.'), findsOneWidget);

    controller.navigate(4);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Notice the weather within.'), findsOneWidget);
  });
}
