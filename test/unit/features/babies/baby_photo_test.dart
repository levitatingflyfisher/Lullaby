import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:lullaby/features/babies/presentation/widgets/baby_photo_io.dart'
    as io_impl;
// The web half must stay free of dart:io — which is exactly what makes it
// importable (and testable) inside this VM test.
import 'package:lullaby/features/babies/presentation/widgets/baby_photo_web.dart'
    as web_impl;

void main() {
  group('baby_photo_web (the PWA half)', () {
    test('photo picking is not supported', () {
      expect(web_impl.babyPhotoSupported, isFalse);
    });

    test('babyPhotoImage is always null — a stored photoPath is a path on '
        'some device\'s disk, unreachable from a browser', () {
      expect(web_impl.babyPhotoImage(null), isNull);
      expect(web_impl.babyPhotoImage('/data/user/0/avatars/x.jpg'), isNull);
    });

    test('persistPickedPhoto degrades to a no-op (null), never a throw', () async {
      await expectLater(
          web_impl.persistPickedPhoto(XFile('/tmp/nope.jpg')), completion(isNull));
    });
  });

  group('baby_photo_io (the native half)', () {
    test('photo picking is supported', () {
      expect(io_impl.babyPhotoSupported, isTrue);
    });

    test('babyPhotoImage is null when no path is set', () {
      expect(io_impl.babyPhotoImage(null), isNull);
    });

    test('babyPhotoImage is null when the file is missing', () {
      expect(io_impl.babyPhotoImage('/definitely/not/here.jpg'), isNull);
    });

    test('babyPhotoImage resolves an existing file to a FileImage', () {
      final tmp = File(
          '${Directory.systemTemp.createTempSync('lullaby_test').path}/a.jpg')
        ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
      addTearDown(() => tmp.parent.deleteSync(recursive: true));

      final image = io_impl.babyPhotoImage(tmp.path);
      expect(image, isA<FileImage>());
      expect((image as FileImage).file.path, tmp.path);
    });
  });
}
