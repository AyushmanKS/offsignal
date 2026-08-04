import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:offsignal_core/offsignal_core.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/assets/app_asset_widgets.dart';
import '../../core/assets/app_assets.dart';
import '../../core/errors/app_exception.dart';
import '../../core/formatting.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/platform/file_saver.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/motion.dart';
import '../../widgets/app_feedback.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_surface.dart';
import '../../widgets/responsive_scaffold.dart';
import 'receive_providers.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _contentRevealed = false;
  bool _isSaving = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(
      AppMotion.successDraw + AppMotion.successContentDelay,
    ).then((_) {
      if (mounted) setState(() => _contentRevealed = true);
    });
  }

  bool get _isText {
    final payload = ref.read(receivedPayloadProvider);
    return payload != null && payload.mimeType.startsWith('text/');
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    AppFeedback.showToast(context, AppLocalizations.of(context).resultCopied);
  }

  Future<void> _save(PayloadEnvelope payload) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await savePayloadToDevice(payload.name, payload.bytes);
      if (!mounted) return;
      AppFeedback.showToast(context, AppLocalizations.of(context).resultSaved);
    } on Object {
      if (mounted) AppFeedback.showErrorSnackBar(context, const SaveFailed());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _share(PayloadEnvelope payload) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              payload.bytes,
              name: payload.name,
              mimeType: payload.mimeType,
            ),
          ],
          fileNameOverrides: [payload.name],
        ),
      );
    } on Object {
      if (mounted) AppFeedback.showErrorSnackBar(context, const ShareFailed());
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _startOver() {
    ref.read(receiveProvider.notifier).reset();
    ref.read(receivedPayloadProvider.notifier).state = null;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final payload = ref.watch(receivedPayloadProvider);

    if (payload == null) return const SizedBox.shrink();

    return ResponsiveScaffold(
      title: strings.resultTitle,
      accent: palette.success,
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
            Center(child: AppSuccessAnimation(size: 108)),
            const SizedBox(height: AppSpacing.md),
            AnimatedOpacity(
              opacity: _contentRevealed ? 1 : 0,
              duration: AppMotion.resolve(
                context,
                AppMotion.successContentFade,
              ),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: _contentRevealed ? Offset.zero : const Offset(0, 0.04),
                duration: AppMotion.resolve(
                  context,
                  AppMotion.successContentFade,
                ),
                curve: Curves.easeOut,
                child: _isText
                    ? _TextResult(payload: payload)
                    : _FileResult(payload: payload),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isText)
              GlassButton(
                label: strings.resultCopy,
                iconPath: AppIcons.copy,
                accent: palette.success,
                onPressed: () => _copy(utf8.decode(payload.bytes)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: strings.resultSave,
                      iconPath: AppIcons.downloadSave,
                      accent: palette.success,
                      isProcessing: _isSaving,
                      onPressed: () => _save(payload),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: GlassButton(
                      label: strings.resultShare,
                      iconPath: AppIcons.share,
                      variant: GlassButtonVariant.secondary,
                      isProcessing: _isSharing,
                      onPressed: () => _share(payload),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      bottomBar: GlassButton(
        label: strings.resultAnother,
        variant: GlassButtonVariant.secondary,
        onPressed: _startOver,
      ),
    );
  }
}

class _TextResult extends StatelessWidget {
  const _TextResult({required this.payload});

  final PayloadEnvelope payload;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final text = utf8.decode(payload.bytes, allowMalformed: true);

    return GlassSurface(
      accent: palette.success,
      accentStrength: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.resultMessageLabel.toUpperCase(),
            style: AppTextStyles.statLabel(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _FileResult extends StatelessWidget {
  const _FileResult({required this.payload});

  final PayloadEnvelope payload;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final palette = context.glass;
    final isImage = payload.mimeType.startsWith('image/');

    return GlassSurface(
      accent: palette.success,
      accentStrength: 0.4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: Image.memory(payload.bytes, fit: BoxFit.contain),
              ),
            )
          else
            Center(
              child: AppIcon(AppIcons.file, size: 40, color: palette.success),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            payload.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatBytes(strings, payload.bytes.length),
            style: AppTextStyles.readout(context),
          ),
        ],
      ),
    );
  }
}
