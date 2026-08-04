import 'package:flutter/widgets.dart';

import '../l10n/generated/app_localizations.dart';
import 'app_exception.dart';

String userFacingMessage(BuildContext context, AppException exception) {
  final strings = AppLocalizations.of(context);
  return switch (exception) {
    CameraPermissionDenied() => strings.errorCameraPermissionDenied,
    CameraUnavailable() => strings.errorCameraUnavailable,
    TransferCorrupted() => strings.errorTransferCorrupted,
    PayloadTooLargeToSend() => strings.errorPayloadTooLarge,
    PayloadEmptyToSend() => strings.errorPayloadEmpty,
    FileUnreadable() => strings.errorFileUnreadable,
    SaveFailed() => strings.errorSaveFailed,
    ShareFailed() => strings.errorShareFailed,
    UnknownError() => strings.errorUnknown,
  };
}
