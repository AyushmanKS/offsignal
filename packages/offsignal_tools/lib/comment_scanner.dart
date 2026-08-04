import 'dart:io';

const excludedPathFragments = <String>[
  '/l10n/generated/',
  '/.dart_tool/',
  '/build/',
  '/tools/',
];

final class CommentHit {
  const CommentHit(this.path, this.line, this.text);

  final String path;
  final int line;
  final String text;

  @override
  String toString() => '$path:$line  $text';
}

List<CommentHit> scanDirectory(Directory root) {
  final hits = <CommentHit>[];
  if (!root.existsSync()) return hits;

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final normalized = entity.path.replaceAll(r'\', '/');
    if (excludedPathFragments.any(normalized.contains)) continue;
    hits.addAll(scanSource(normalized, entity.readAsStringSync()));
  }
  return hits;
}

List<CommentHit> scanSource(String path, String source) {
  final hits = <CommentHit>[];
  var line = 1;
  var index = 0;

  while (index < source.length) {
    final character = source[index];

    if (character == '\n') {
      line++;
      index++;
      continue;
    }

    if (character == 'r' &&
        index + 1 < source.length &&
        (source[index + 1] == "'" || source[index + 1] == '"')) {
      index = _skipString(source, index + 1, () => line++);
      continue;
    }

    if (character == "'" || character == '"') {
      index = _skipString(source, index, () => line++);
      continue;
    }

    if (character == '/' && index + 1 < source.length) {
      final next = source[index + 1];
      if (next == '/') {
        final end = source.indexOf('\n', index);
        final stop = end == -1 ? source.length : end;
        hits.add(CommentHit(path, line, source.substring(index, stop).trim()));
        index = stop;
        continue;
      }
      if (next == '*') {
        final end = source.indexOf('*/', index + 2);
        final stop = end == -1 ? source.length : end + 2;
        hits.add(
          CommentHit(
            path,
            line,
            source
                .substring(index, index + 40 > stop ? stop : index + 40)
                .trim(),
          ),
        );
        line += '\n'.allMatches(source.substring(index, stop)).length;
        index = stop;
        continue;
      }
    }

    index++;
  }

  return hits;
}

int _skipString(String source, int start, void Function() onNewline) {
  final quote = source[start];
  final isTriple =
      start + 2 < source.length &&
      source[start + 1] == quote &&
      source[start + 2] == quote;
  final delimiter = isTriple ? quote * 3 : quote;

  var index = start + delimiter.length;
  while (index < source.length) {
    final character = source[index];
    if (character == r'\') {
      index += 2;
      continue;
    }
    if (character == '\n') {
      onNewline();
      if (!isTriple) return index;
      index++;
      continue;
    }
    if (source.startsWith(delimiter, index)) return index + delimiter.length;
    index++;
  }
  return index;
}
