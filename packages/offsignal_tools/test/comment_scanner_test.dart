import 'dart:io';

import 'package:offsignal_tools/comment_scanner.dart';
import 'package:test/test.dart';

void main() {
  group('detects real comments', () {
    test('line comment', () {
      final hits = scanSource(
        'a.dart',
        'final x = 1;\n// explain\nfinal y = 2;',
      );
      expect(hits, hasLength(1));
      expect(hits.single.line, 2);
      expect(hits.single.text, '// explain');
    });

    test('dartdoc comment', () {
      final hits = scanSource('a.dart', '/// Documents a thing\nclass A {}');
      expect(hits, hasLength(1));
    });

    test('block comment spanning lines', () {
      final hits = scanSource(
        'a.dart',
        'final a = 1;\n/* one\ntwo */\nfinal b = 2;',
      );
      expect(hits, hasLength(1));
      expect(hits.single.line, 2);
    });

    test('trailing comment after code', () {
      final hits = scanSource('a.dart', 'final x = 1; // why');
      expect(hits, hasLength(1));
    });

    test('ignore directives count as comments', () {
      final hits = scanSource(
        'a.dart',
        '// ignore: prefer_final_locals\nvar x = 1;',
      );
      expect(hits, hasLength(1));
    });
  });

  group('does not flag code that merely looks like a comment', () {
    test('url inside a single-quoted string', () {
      final hits = scanSource(
        'a.dart',
        "const url = 'https://offsignal.app/privacy';",
      );
      expect(hits, isEmpty);
    });

    test('url inside a double-quoted string', () {
      final hits = scanSource('a.dart', 'const url = "http://example.com//x";');
      expect(hits, isEmpty);
    });

    test('raw string containing slashes', () {
      final hits = scanSource('a.dart', r"final p = r'C:\dir//file';");
      expect(hits, isEmpty);
    });

    test('triple-quoted string containing a comment', () {
      final hits = scanSource(
        'a.dart',
        "final s = '''\n// not a comment\n''';",
      );
      expect(hits, isEmpty);
    });

    test('escaped quote inside a string', () {
      final hits = scanSource('a.dart', r"final s = 'it\'s // fine';");
      expect(hits, isEmpty);
    });

    test('division operators', () {
      final hits = scanSource('a.dart', 'final r = a / b / c;');
      expect(hits, isEmpty);
    });

    test('clean source produces no hits', () {
      final hits = scanSource(
        'a.dart',
        'class Signal {\n  const Signal(this.value);\n  final int value;\n}',
      );
      expect(hits, isEmpty);
    });
  });

  group('repository guard', () {
    test('offsignal_core and offsignal_app carry no comments', () {
      final hits = <CommentHit>[
        ...scanDirectory(Directory('../offsignal_core/lib')),
        ...scanDirectory(Directory('../offsignal_core/test')),
        ...scanDirectory(Directory('../offsignal_app/lib')),
      ];

      expect(
        hits,
        isEmpty,
        reason: hits.map((hit) => hit.toString()).join('\n'),
      );
    });

    test('generated localizations are excluded from the guard', () {
      final generated = Directory('../offsignal_app/lib/core/l10n/generated');
      expect(generated.existsSync(), isTrue);
      expect(scanDirectory(generated), isEmpty);
    });
  });
}
