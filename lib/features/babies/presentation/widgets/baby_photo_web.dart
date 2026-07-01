import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';

/// Photo picking is hidden on web: baby photos are stored as device file
/// paths, and a browser has no file system to resolve them against.
bool get babyPhotoSupported => false;

/// Always null on web — a stored photoPath is a path on some device's disk,
/// unreachable from a browser; callers fall back to the initial-letter
/// avatar instead of hitting dart:io's throwing File stub.
ImageProvider? babyPhotoImage(String? photoPath) => null;

/// Unreachable on web ([babyPhotoSupported] hides the affordance). Returns
/// null — photo unchanged — rather than throwing, so a regression that
/// re-exposes the button degrades to a no-op instead of a crash.
Future<String?> persistPickedPhoto(XFile picked) async => null;
