import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/assets/app_asset_widgets.dart';
import '../core/assets/app_assets.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_messages.dart';
import '../core/l10n/generated/app_localizations.dart';
import '../core/theme/design_tokens.dart';
import '../core/theme/motion.dart';
import 'glass_button.dart';
import 'glass_surface.dart';

abstract final class AppFeedback {
  static void showToast(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        _glassSnackBar(
          context: context,
          message: message,
          duration: AppMotion.toastDuration,
          iconPath: AppIcons.checkmarkSuccess,
          tone: context.glass.success,
        ),
      );
  }

  static void showErrorSnackBar(
    BuildContext context,
    AppException exception, {
    VoidCallback? onRetry,
  }) {
    final strings = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        _glassSnackBar(
          context: context,
          message: userFacingMessage(context, exception),
          duration: AppMotion.snackbarDuration,
          iconPath: AppIcons.alertError,
          tone: context.glass.danger,
          action: onRetry == null
              ? null
              : SnackBarAction(
                  label: strings.actionRetry,
                  textColor: context.glass.signalAccent,
                  onPressed: onRetry,
                ),
        ),
      );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String confirmLabel,
    String? cancelLabel,
    bool isDestructive = true,
  }) async {
    final strings = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (dialogContext) => _GlassDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel ?? strings.actionCancel,
        isDestructive: isDestructive,
      ),
    );
    return result ?? false;
  }

  static SnackBar _glassSnackBar({
    required BuildContext context,
    required String message,
    required Duration duration,
    required String iconPath,
    required Color tone,
    SnackBarAction? action,
  }) {
    final palette = context.glass;
    return SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.all(AppSpacing.md),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppBlur.modal,
            sigmaY: AppBlur.modal,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md - 2,
            ),
            decoration: BoxDecoration(
              color: palette.isDark
                  ? const Color(0xE60E141C)
                  : const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: tone.withValues(alpha: 0.35), width: 1),
            ),
            child: Row(
              children: [
                AppIcon(iconPath, size: 20, color: tone),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: action.onPressed,
                    child: Text(
                      action.label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: palette.signalAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDialog extends StatelessWidget {
  const _GlassDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.isDestructive,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: GlassSurface(
          strong: true,
          blur: AppBlur.modal,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.sm + 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.glass.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: cancelLabel,
                      variant: GlassButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm + 4),
                  Expanded(
                    child: GlassButton(
                      label: confirmLabel,
                      variant: isDestructive
                          ? GlassButtonVariant.danger
                          : GlassButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InlineErrorState extends StatelessWidget {
  const InlineErrorState({
    super.key,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = context.glass;

    return GlassSurface(
      accent: palette.danger,
      accentStrength: 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppIcon(AppIcons.alertError, size: 28, color: palette.danger),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.lg),
            GlassButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
