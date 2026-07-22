import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Lullaby ships a live PWA. `dart:io` COMPILES on web (the SDK provides
/// stubs) but every `File`/`Directory` call THROWS at runtime — so a bare
/// `import 'dart:io'` in shared UI code is a landmine that only detonates in
/// a web user's browser, never in `flutter build` or the native test suite.
///
/// House rule (the fleet's conditional-import trio convention, e.g. Sundial's
/// backup_file_save and this repo's database connection split): dart:io may
/// be imported only by files that are the native half of a platform split —
/// `*_io.dart` or `native.dart` — which a facade selects away on web.
///
/// The exemption is only sound if the native halves really ARE selected away:
/// a PLAIN `import 'foo_io.dart';` from ordinary lib code drags dart:io back
/// into the web build through the side door. The second test below closes
/// that gap: every import of a native half must be part of an
/// `if (dart.library...)` conditional-import directive.

/// Returns the import directives in [source] that reference a native half
/// (`*_io.dart` or `native.dart`) WITHOUT being part of an
/// `if (dart.library...)` conditional import.
List<String> plainNativeHalfImports(String source) {
  final directive = RegExp(r'''import\s+['"][^;]*;''');
  final uri = RegExp(r'''['"]([^'"]+)['"]''');
  final offenders = <String>[];
  for (final match in directive.allMatches(source)) {
    final text = match.group(0)!;
    final referencesNativeHalf = uri.allMatches(text).any((m) {
      final name = m.group(1)!.split('/').last;
      return name.endsWith('_io.dart') || name == 'native.dart';
    });
    if (referencesNativeHalf && !text.contains('if (dart.library')) {
      offenders.add(text);
    }
  }
  return offenders;
}

void main() {
  test('bare dart:io imports appear only in *_io.dart / native.dart', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));
    final ioImport = RegExp('''import\\s+['"]dart:io['"]''');

    for (final file in files) {
      final name = file.uri.pathSegments.last;
      if (name.endsWith('_io.dart') || name == 'native.dart') continue;
      if (ioImport.hasMatch(file.readAsStringSync())) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These files bare-import dart:io and will throw at runtime on '
          'the web build the moment their File/Directory calls run. Move the '
          'native file I/O behind a conditional-import trio '
          '(facade + *_io.dart + *_web.dart) instead.',
    );
  });

  test(
      'plainNativeHalfImports flags a bare import of a native half and '
      'accepts the conditional-import trio (synthetic fixtures)', () {
    // A plain import drags the native half — and its dart:io — into every
    // build, web included. The old guard never looked for this.
    const offender = '''
import 'package:flutter/material.dart';
import 'backup/backup_file_save_io.dart';
import 'db/native.dart';
''';
    expect(
      plainNativeHalfImports(offender),
      [
        contains('backup_file_save_io.dart'),
        contains('native.dart'),
      ],
      reason: 'Both plain imports of native halves must be flagged.',
    );

    // The blessed pattern: the native half appears only behind an
    // if (dart.library...) clause, so web builds never load it.
    const conditional = '''
import 'package:flutter/material.dart';
import 'db/unsupported.dart'
    if (dart.library.js_interop) 'db/web.dart'
    if (dart.library.io) 'db/native.dart';
import 'backup/backup_file_save_stub.dart'
    if (dart.library.io) 'backup/backup_file_save_io.dart';
''';
    expect(plainNativeHalfImports(conditional), isEmpty,
        reason: 'Conditional-import trios are exactly what the rule allows.');

    // Ordinary imports never trip the check.
    const clean = '''
import 'dart:async';
import 'package:flutter/material.dart';
import 'features/growth/domain/entities/growth_record.dart';
''';
    expect(plainNativeHalfImports(clean), isEmpty);
  });

  test(
      'native halves (*_io.dart / native.dart) are reachable from lib only '
      'via if (dart.library...) conditional imports', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in files) {
      // A native half may import other native halves (e.g. connection/
      // native.dart importing package:drift/native.dart): it is itself only
      // reachable through a conditional import, so nothing leaks to web.
      final name = file.uri.pathSegments.last;
      if (name.endsWith('_io.dart') || name == 'native.dart') continue;
      for (final directive
          in plainNativeHalfImports(file.readAsStringSync())) {
        offenders.add('${file.path}: $directive');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These imports pull a native half (and its dart:io) into every '
          'build, web included — the *_io.dart/native.dart exemption above is '
          'only sound when a conditional import selects the native half away '
          'on web. Route them through an if (dart.library...) conditional '
          'import instead.',
    );
  });
}
