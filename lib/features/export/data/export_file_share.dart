import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'export_file_share_io.dart'
    if (dart.library.js_interop) 'export_file_share_web.dart' as impl;

/// Hands export bytes to the platform's share affordance.
typedef ExportFileShare = Future<void> Function({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
});

/// The platform share routine, resolved by conditional import: native writes
/// a temp file for the OS share sheet (dart:io); web hands the bytes to the
/// Web Share API with a plain-download fallback — no dart:io, whose stubs
/// throw at runtime in a browser. A provider so widget tests can drive the
/// seam with a recorder instead of platform channels.
final exportFileShareProvider =
    Provider<ExportFileShare>((_) => impl.shareExportBytes);
