import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offsignal_app/core/assets/app_assets.dart';
import 'package:offsignal_app/core/theme/design_tokens.dart';
import 'package:offsignal_app/widgets/glass_button.dart';
import 'package:offsignal_app/widgets/glass_segmented_control.dart';
import 'package:offsignal_app/widgets/glass_surface.dart';
import 'package:offsignal_app/widgets/transfer_progress_bar.dart';

import '../support/harness.dart';

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return Material(
      color: palette.backgroundBase,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSurface(
              accent: palette.signalAccent,
              accentStrength: 0.7,
              child: Text(
                'Glass surface',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GlassButton(
              label: 'Start broadcasting',
              iconPath: AppIcons.playBroadcast,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.sm),
            const GlassButton(
              label: 'Disabled action',
              onPressed: null,
              helperText: 'Type a message or choose a file',
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassButton(
              label: 'Stop',
              variant: GlassButtonVariant.danger,
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.md),
            GlassSegmentedControl<int>(
              options: const [
                SegmentOption(
                  value: 0,
                  label: 'Text',
                  iconPath: AppIcons.textNote,
                ),
                SegmentOption(value: 1, label: 'File', iconPath: AppIcons.file),
              ],
              selected: 0,
              onChanged: (_) {},
            ),
            const SizedBox(height: AppSpacing.lg),
            TransferProgressBar(
              progress: 0.62,
              accent: palette.amberAccent,
              label: '124 / 200 blocks',
              trailing: '318 frames read',
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  for (final brightness in Brightness.values) {
    testWidgets('glass components render in ${brightness.name}', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(420, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        await wrapScreen(
          const Center(child: _Gallery()),
          brightness: brightness,
          surfaceSize: const Size(420, 700),
          reduceMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(_Gallery),
        matchesGoldenFile('goldens/glass_components_${brightness.name}.png'),
      );
    });
  }
}
