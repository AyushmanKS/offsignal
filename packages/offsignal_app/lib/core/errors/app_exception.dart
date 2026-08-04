import 'package:offsignal_core/offsignal_core.dart';

sealed class AppException implements Exception {
  const AppException();
}

final class CameraPermissionDenied extends AppException {
  const CameraPermissionDenied({this.isPermanent = false});

  final bool isPermanent;
}

final class CameraUnavailable extends AppException {
  const CameraUnavailable();
}

final class TransferCorrupted extends AppException {
  const TransferCorrupted();
}

final class PayloadTooLargeToSend extends AppException {
  const PayloadTooLargeToSend();
}

final class PayloadEmptyToSend extends AppException {
  const PayloadEmptyToSend();
}

final class FileUnreadable extends AppException {
  const FileUnreadable();
}

final class SaveFailed extends AppException {
  const SaveFailed();
}

final class ShareFailed extends AppException {
  const ShareFailed();
}

final class UnknownError extends AppException {
  const UnknownError();
}

AppException appExceptionFromCodec(CodecError error) => switch (error) {
  EmptyPayload() => const PayloadEmptyToSend(),
  PayloadTooLarge() => const PayloadTooLargeToSend(),
  ChecksumMismatch() ||
  DecompressionFailed() ||
  MetadataMalformed() ||
  TransferIncomplete() => const TransferCorrupted(),
  MalformedPacket() || SessionMismatch() => const UnknownError(),
};
