import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/core/theme.dart';

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
}
