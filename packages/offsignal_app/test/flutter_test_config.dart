import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _rasterisationNoiseTolerance = 0.05;

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final existing = goldenFileComparator as LocalFileComparator;
  goldenFileComparator = _RasterisationTolerantComparator(existing.basedir);
  await testMain();
}

class _RasterisationTolerantComparator extends LocalFileComparator {
  _RasterisationTolerantComparator(Uri baseDirectory)
    : super(baseDirectory.resolve('flutter_test_config.dart'));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );

    if (result.passed || result.diffPercent <= _rasterisationNoiseTolerance) {
      result.dispose();
      return true;
    }

    final failure = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(failure);
  }
}
