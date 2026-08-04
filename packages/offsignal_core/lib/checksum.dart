import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const sha256ByteLength = 32;

Uint8List computeChecksum(List<int> bytes) =>
    Uint8List.fromList(sha256.convert(bytes).bytes);

bool checksumMatches(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var difference = 0;
  for (var i = 0; i < a.length; i++) {
    difference |= a[i] ^ b[i];
  }
  return difference == 0;
}
