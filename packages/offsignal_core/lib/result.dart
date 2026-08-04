sealed class CodecError {
  const CodecError();
}

final class EmptyPayload extends CodecError {
  const EmptyPayload();
}

final class PayloadTooLarge extends CodecError {
  const PayloadTooLarge(this.sizeBytes, this.limitBytes);

  final int sizeBytes;
  final int limitBytes;
}

final class MalformedPacket extends CodecError {
  const MalformedPacket();
}

final class SessionMismatch extends CodecError {
  const SessionMismatch();
}

final class TransferIncomplete extends CodecError {
  const TransferIncomplete(this.solvedBlocks, this.totalBlocks);

  final int solvedBlocks;
  final int totalBlocks;
}

final class DecompressionFailed extends CodecError {
  const DecompressionFailed();
}

final class MetadataMalformed extends CodecError {
  const MetadataMalformed();
}

final class ChecksumMismatch extends CodecError {
  const ChecksumMismatch();
}

sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Failure<T>() => null,
  };

  CodecError? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };

  R fold<R>(R Function(T value) onSuccess, R Function(CodecError error) onFailure) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        Failure<T>(:final error) => onFailure(error),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final CodecError error;
}
