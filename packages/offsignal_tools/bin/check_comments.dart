import 'dart:io';

import 'package:offsignal_tools/comment_scanner.dart';

void main(List<String> arguments) {
  final roots = arguments.isEmpty ? <String>['.'] : arguments;
  final hits = <CommentHit>[];

  for (final root in roots) {
    hits.addAll(scanDirectory(Directory(root)));
  }

  if (hits.isEmpty) {
    stdout.writeln('No comments found in ${roots.join(', ')}.');
    return;
  }

  stderr.writeln(
    'Found ${hits.length} comment(s); PRD section 4.1 forbids them:',
  );
  for (final hit in hits.take(50)) {
    stderr.writeln('  $hit');
  }
  exitCode = 1;
}
