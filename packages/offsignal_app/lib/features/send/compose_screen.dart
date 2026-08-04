import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

import '../../core/assets/app_asset_widgets.dart';
import '../../core/assets/app_assets.dart';
import '../../core/errors/app_exception.dart';
import '../../core/formatting.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/platform/haptics.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_segmented_control.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive_scaffold.dart';
import 'send_providers.dart';

class ComposeScreen extends ConsumerStatefulWidget {
  const ComposeScreen({super.key});

  @override
  ConsumerState<ComposeScreen> createState() => _ComposeScreenState();
}

class _ComposeScreenState extends ConsumerState<ComposeScreen> {
  late final TextEditingController _textController = TextEditingController(
    text: ref.read(composeProvider).text,
  );
  bool _isPickingFile = false;
  bool _isStarting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _onModeChanged(ComposeMode mode) async {
    final compose = ref.read(composeProvider);
    if (compose.mode == mode) return;

    final strings = AppLocalizations.of(context);
    if (compose.hasContent) {
      final confirmed = await AppFeedback.confirm(
        context,
        title: mode == ComposeMode.text
            ? strings.composeSwitchToTextTitle
            : strings.composeSwitchToFileTitle,
        body: strings.composeSwitchBody,
        confirmLabel: strings.composeSwitchConfirm,
        isDestructive: false,
      );
      if (!confirmed || !mounted) return;
    }

    _textController.clear();
    ref.read(composeProvider.notifier).setMode(mode);
  }

  Future<void> _pickFile() async {
    if (_isPickingFile) return;
    setState(() => _isPickingFile = true);

    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      final picked = result?.files.singleOrNull;
      if (picked == null) return;

      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          AppFeedback.showErrorSnackBar(
            context,
            const FileUnreadable(),
            screen: 'compose',
          );
        }
        return;
      }

      ref
          .read(composeProvider.notifier)
          .setFile(
            PickedFilePayload(
              name: picked.name,
              mimeType:
                  lookupMimeType(picked.name) ?? 'application/octet-stream',
              bytes: bytes,
            ),
          );
    } on Object {
      if (mounted) {
        AppFeedback.showErrorSnackBar(
          context,
          const FileUnreadable(),
          screen: 'compose',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  Future<void> _startBroadcasting() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final envelope = envelopeFrom(ref.read(composeProvider));
      if (envelope == null) return;

      final prepared = ref
          .read(outgoingTransferProvider.notifier)
          .prepare(envelope);

      if (!mounted) return;
      prepared.fold(
        (_) {
          ref.read(hapticsProvider).press();
          context.push(AppRoutes.broadcasting);
        },
        (error) => AppFeedback.showErrorSnackBar(
          context,
          appExceptionFromCodec(error),
          screen: 'compose',
        ),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final compose = ref.watch(composeProvider);

    return ResponsiveScaffold(
      title: strings.composeTitle,
      onBack: () => context.pop(),
      accent: palette.signalAccent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassSegmentedControl<ComposeMode>(
              selected: compose.mode,
              onChanged: _onModeChanged,
              options: [
                SegmentOption(
                  value: ComposeMode.text,
                  label: strings.composeSegmentText,
                  iconPath: AppIcons.textNote,
                ),
                SegmentOption(
                  value: ComposeMode.file,
                  label: strings.composeSegmentFile,
                  iconPath: AppIcons.file,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (compose.mode == ComposeMode.text)
              _TextComposer(controller: _textController)
            else
              _FileComposer(isPicking: _isPickingFile, onPick: _pickFile),
            const SizedBox(height: AppSpacing.md),
            _EstimateStrip(state: compose),
            if (compose.showsLargePayloadNotice) ...[
              const SizedBox(height: AppSpacing.md),
              _LargePayloadNotice(
                onDismiss: () => ref
                    .read(composeProvider.notifier)
                    .dismissLargePayloadNotice(),
              ),
            ],
          ],
        ),
      ),
      bottomBar: GlassButton(
        label: strings.composeStart,
        iconPath: AppIcons.playBroadcast,
        isProcessing: _isStarting || compose.isEstimating,
        onPressed: compose.canBroadcast ? _startBroadcasting : null,
        helperText: compose.hasContent ? null : strings.composeDisabledHelp,
      ),
    );
  }
}

class _TextComposer extends ConsumerWidget {
  const _TextComposer({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final characterCount = ref.watch(
      composeProvider.select((state) => state.text.characters.length),
    );

    return GlassSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            onChanged: ref.read(composeProvider.notifier).setText,
            maxLines: 7,
            minLines: 5,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: strings.composeTextHint,
              hintStyle: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: palette.textMuted),
              labelStyle: const TextStyle(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              strings.composeCharacterCount(characterCount),
              style: AppTextStyles.readout(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileComposer extends ConsumerWidget {
  const _FileComposer({required this.isPicking, required this.onPick});

  final bool isPicking;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final file = ref.watch(composeProvider.select((state) => state.file));

    if (file == null) {
      return Pressable(
        onPressed: isPicking ? null : onPick,
        semanticLabel: strings.composeChooseFile,
        child: GlassSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            children: [
              AppIcon(
                AppIcons.uploadPicker,
                size: 30,
                color: palette.signalAccent,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                strings.composeChooseFile,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                strings.composeChooseFileHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return GlassSurface(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: palette.signalAccent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: file.isImage
                ? Image.memory(file.bytes, fit: BoxFit.cover)
                : Center(
                    child: AppIcon(
                      AppIcons.file,
                      size: 22,
                      color: palette.signalAccent,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  formatBytes(strings, file.sizeBytes),
                  style: AppTextStyles.readout(context),
                ),
              ],
            ),
          ),
          Pressable(
            onPressed: ref.read(composeProvider.notifier).clearFile,
            semanticLabel: strings.composeRemoveFile,
            child: SizedBox(
              width: AppSizes.minTapTarget,
              height: AppSizes.minTapTarget,
              child: Center(
                child: AppIcon(
                  AppIcons.close,
                  size: 18,
                  color: palette.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimateStrip extends StatelessWidget {
  const _EstimateStrip({required this.state});

  final ComposeState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final plan = state.plan;

    final label = plan == null
        ? '—'
        : [
            strings.composeEstimateBlocks(plan.blockCount),
            formatBytes(strings, plan.compressedBytes),
            strings.composeEstimateBand(
              plan
                  .durationBand(const Duration(milliseconds: 120))
                  .fastest
                  .inSeconds,
              plan
                  .durationBand(const Duration(milliseconds: 120))
                  .slowest
                  .inSeconds,
            ),
          ].join('  ·  ');

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceFill,
          borderRadius: BorderRadius.circular(AppRadius.control),
          border: Border.all(color: palette.borderHighlight, width: 1),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.lightWave, size: 16, color: palette.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.readout(context),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LargePayloadNotice extends StatelessWidget {
  const _LargePayloadNotice({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;

    return GlassSurface(
      accent: palette.amberAccent,
      accentStrength: 0.5,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(AppIcons.alertError, size: 18, color: palette.amberAccent),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              strings.composeLargePayloadWarning,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Pressable(
            onPressed: onDismiss,
            semanticLabel: strings.actionDismiss,
            minSize: AppSizes.minTapTarget,
            child: Center(
              child: AppIcon(
                AppIcons.close,
                size: 16,
                color: palette.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
