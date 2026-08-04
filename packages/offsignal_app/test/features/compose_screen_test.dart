import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/features/send/compose_screen.dart';
import 'package:offsignal_app/widgets/glass_button.dart';

import '../support/harness.dart';

void main() {
  testWidgets(
    'start button is disabled with helper text until content exists',
    (tester) async {
      await tester.pumpWidget(await wrapScreen(const ComposeScreen()));
      await settleFrames(tester);

      expect(find.text('Type a message or choose a file'), findsOneWidget);

      final button = tester.widget<GlassButton>(
        find.widgetWithText(GlassButton, 'Start broadcasting'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('typing enables the start button and shows an estimate', (
    tester,
  ) async {
    await tester.pumpWidget(await wrapScreen(const ComposeScreen()));
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'meet me at gate 32');
    await tester.pump(const Duration(milliseconds: 400));
    await settleFrames(tester);

    final button = tester.widget<GlassButton>(
      find.widgetWithText(GlassButton, 'Start broadcasting'),
    );
    expect(button.onPressed, isNotNull);
    expect(find.textContaining('1 block  ·'), findsOneWidget);
    expect(find.text('Type a message or choose a file'), findsNothing);
  });

  testWidgets('the block estimate pluralises correctly', (tester) async {
    await tester.pumpWidget(await wrapScreen(const ComposeScreen()));
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'short note');
    await tester.pump(const Duration(milliseconds: 400));
    await settleFrames(tester);
    expect(find.textContaining('1 block  ·'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      List<String>.generate(600, (index) => 'w$index').join(' '),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await settleFrames(tester);
    expect(find.textContaining(' blocks  ·'), findsOneWidget);
  });

  testWidgets('character counter reflects the typed message', (tester) async {
    await tester.pumpWidget(await wrapScreen(const ComposeScreen()));
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('5 characters'), findsOneWidget);
  });

  testWidgets('switching to file mode with content asks for confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(await wrapScreen(const ComposeScreen()));
    await settleFrames(tester);

    await tester.enterText(find.byType(TextField), 'draft worth protecting');
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('File'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Switch to a file?'), findsOneWidget);
    expect(
      find.text('The content you already added will be cleared.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('renders without overflow on a short viewport', (tester) async {
    await tester.pumpWidget(
      await wrapScreen(
        const ComposeScreen(),
        surfaceSize: const Size(375, 667),
      ),
    );
    await settleFrames(tester);

    expect(tester.takeException(), isNull);
  });
}
