import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// House style for words on screen: no spaced em dashes, and typographic
/// apostrophes and quotes (’ “ ”) rather than typewriter ones (' ").
/// A source scan over string literals in lib/: comments and log lines are
/// ignored, and so is export_service.dart, whose strings go into the CSV
/// and the PDF (file format, and the PDF's built-in font).
void main() {
  final literal = RegExp(r'"([^"\\]|\\.)*"' "|" r"'([^'\\]|\\.)*'");
  final exempt = {'lib/features/export/export_service.dart'};

  Iterable<(String, int, String)> literals() sync* {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .where((f) => !exempt.contains(f.path));
    for (final f in files) {
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final t = line.trimLeft();
        if (t.startsWith('//') || t.startsWith('///')) continue;
        if (line.contains('developer.log(') || line.contains('debugPrint(')) {
          continue;
        }
        if (t.startsWith('import ') || t.startsWith('export ')) continue;
        for (final m in literal.allMatches(line)) {
          yield (f.path, i + 1, m.group(0)!);
        }
      }
    }
  }

  test('no spaced em dash in on-screen copy', () {
    final hits = [
      for (final (path, line, lit) in literals())
        if (lit.contains(' — ') || lit.endsWith(" —'") || lit.endsWith(' —"'))
          '$path:$line $lit',
    ];
    expect(hits, isEmpty);
  });

  test('no typewriter apostrophe or quote inside on-screen copy', () {
    final apostrophe = RegExp(r"[A-Za-z]'[A-Za-z]");
    final escaped = RegExp(r"[A-Za-z]\\'[A-Za-z]");
    final hits = [
      for (final (path, line, lit) in literals())
        if ((lit.startsWith('"') &&
                apostrophe.hasMatch(lit.substring(1, lit.length - 1))) ||
            (lit.startsWith("'") &&
                (lit.substring(1, lit.length - 1).contains('"') ||
                    escaped.hasMatch(lit))))
          '$path:$line $lit',
    ];
    expect(hits, isEmpty);
  });
}
