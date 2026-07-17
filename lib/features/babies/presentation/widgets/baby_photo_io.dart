import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Photo picking is available here (native, dart:io-backed).
bool get babyPhotoSupported => true;

/// Resolves [photoPath] to a [FileImage], or null when unset or the file has
/// gone missing — callers fall back to the initial-letter avatar.
ImageProvider? babyPhotoImage(String? photoPath) {
  if (photoPath == null) return null;
  final file = File(photoPath);
  if (!file.existsSync()) return null;
  return FileImage(file);
}

/// Copies a freshly picked photo into permanent app storage and returns the
/// stored path. image_picker returns a path in the OS cache/temp dir, which
/// is purged under storage pressure (the avatar would silently vanish), so
/// the path we persist must be one we own.
Future<String?> persistPickedPhoto(XFile picked) async {
  final docsDir = await getApplicationDocumentsDirectory();
  final avatarsDir = Directory(p.join(docsDir.path, 'avatars'));
  await avatarsDir.create(recursive: true);
  final ext = p.extension(picked.path);
  final dest = p.join(avatarsDir.path, '${_uuid.v4()}$ext');
  await File(picked.path).copy(dest);
  return dest;
}
