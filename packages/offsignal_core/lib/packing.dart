import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'checksum.dart';
import 'result.dart';

const _maxMetadataLength = 0xFFFF;

final class PayloadEnvelope {
  const PayloadEnvelope({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;
}

Result<Uint8List> packPayload(PayloadEnvelope envelope) {
  if (envelope.bytes.isEmpty) return const Failure(EmptyPayload());

  final metadata = utf8.encode(
    jsonEncode({'name': envelope.name, 'mimeType': envelope.mimeType}),
  );
  if (metadata.length > _maxMetadataLength) {
    return const Failure(MetadataMalformed());
  }

  final digest = computeChecksum(envelope.bytes);
  final framed = BytesBuilder(copy: false)
    ..add(_uint16(metadata.length))
    ..add(metadata)
    ..addByte(digest.length)
    ..add(digest)
    ..add(envelope.bytes);

  return Success(_gzip(framed.takeBytes()));
}

Result<PayloadEnvelope> unpackPayload(Uint8List compressed) {
  final Uint8List framed;
  try {
    framed = _gunzip(compressed);
  } on Object {
    return const Failure(DecompressionFailed());
  }

  if (framed.length < 3) return const Failure(MetadataMalformed());

  final view = ByteData.sublistView(framed);
  final metadataLength = view.getUint16(0);
  final digestLengthOffset = 2 + metadataLength;
  if (digestLengthOffset >= framed.length) {
    return const Failure(MetadataMalformed());
  }

  final digestLength = framed[digestLengthOffset];
  if (digestLength != sha256ByteLength) {
    return const Failure(MetadataMalformed());
  }

  final digestOffset = digestLengthOffset + 1;
  final payloadOffset = digestOffset + digestLength;
  if (payloadOffset > framed.length) return const Failure(MetadataMalformed());

  final expectedDigest = Uint8List.sublistView(
    framed,
    digestOffset,
    payloadOffset,
  );
  final payload = Uint8List.sublistView(framed, payloadOffset);

  if (!checksumMatches(computeChecksum(payload), expectedDigest)) {
    return const Failure(ChecksumMismatch());
  }

  final Map<String, dynamic> metadata;
  try {
    final decoded = jsonDecode(
      utf8.decode(Uint8List.sublistView(framed, 2, digestLengthOffset)),
    );
    if (decoded is! Map<String, dynamic>) {
      return const Failure(MetadataMalformed());
    }
    metadata = decoded;
  } on Object {
    return const Failure(MetadataMalformed());
  }

  final name = metadata['name'];
  final mimeType = metadata['mimeType'];
  if (name is! String || mimeType is! String) {
    return const Failure(MetadataMalformed());
  }

  return Success(
    PayloadEnvelope(
      name: name,
      mimeType: mimeType,
      bytes: Uint8List.fromList(payload),
    ),
  );
}

Uint8List _uint16(int value) {
  final buffer = ByteData(2)..setUint16(0, value);
  return buffer.buffer.asUint8List();
}

Uint8List _gzip(Uint8List bytes) =>
    Uint8List.fromList(GZipEncoder().encode(bytes));

Uint8List _gunzip(Uint8List bytes) =>
    Uint8List.fromList(GZipDecoder().decodeBytes(bytes));
