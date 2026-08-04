import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<void> savePayloadToDevice(String name, Uint8List bytes) async {
  final directory =
      await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/${_uniqueName(directory, name)}');
  await file.writeAsBytes(bytes, flush: true);
}

String _uniqueName(Directory directory, String name) {
  if (!File('${directory.path}/$name').existsSync()) return name;

  final dotIndex = name.lastIndexOf('.');
  final stem = dotIndex <= 0 ? name : name.substring(0, dotIndex);
  final extension = dotIndex <= 0 ? '' : name.substring(dotIndex);

  var attempt = 2;
  while (File('${directory.path}/$stem ($attempt)$extension').existsSync()) {
    attempt++;
  }
  return '$stem ($attempt)$extension';
}
