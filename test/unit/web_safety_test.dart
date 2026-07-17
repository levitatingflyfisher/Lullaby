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
}
