import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/theme.dart';
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
}
